#include <Adafruit_CC3000.h>
#include <ccspi.h>
#include <SPI.h>
//#include <string.h>
//#include "utility/debug.h"
#include "utility/sntp.h"

/***************************************************************************
NOTES

This sketch takes up most of the memory available for red boards.
If you need a little more memory, try commenting out serial print statements.
Getting more memory may require some serious optimizations or upgrading the hardware.
***************************************************************************/

// Enums
enum FreeTakenState {
  FREE,
  TAKEN,
};

// Pins
const int START_BUTTON_PIN = 8;
const int LOAD_SENSOR_PIN = A0;

// CC3000
const bool USE_CC3000 = true; // if false, use processing_wifi
// These are the interrupt and control pins
#define ADAFRUIT_CC3000_IRQ   3  // MUST be an interrupt pin!
// These can be any two pins
#define ADAFRUIT_CC3000_VBAT  5
#define ADAFRUIT_CC3000_CS    10
// Use hardware SPI for the remaining pins
// On an UNO, SCK = 13, MISO = 12, and MOSI = 11
Adafruit_CC3000 cc3000 = Adafruit_CC3000(ADAFRUIT_CC3000_CS, ADAFRUIT_CC3000_IRQ, ADAFRUIT_CC3000_VBAT,
                                         SPI_CLOCK_DIVIDER); // you can change this clock speed but DI

// Wireless
#define WLAN_SSID       "CHANGEME"        // cannot be longer than 32 characters!
#define WLAN_PASS       "CHANGEME"
// Security can be WLAN_SEC_UNSEC, WLAN_SEC_WEP, WLAN_SEC_WPA or WLAN_SEC_WPA2
#define WLAN_SECURITY   WLAN_SEC_WPA2

#define IDLE_TIMEOUT_MS  3000      // Amount of time to wait (in milliseconds) with no data 
                                   // received before closing the connection.  If you know the server
                                   // you're accessing is quick to respond, you can reduce this value.
                                   
#define ACTIVITY_STREAM_WEBSITE "russet.ISchool.Berkeley.EDU"
#define ACTIVITY_STREAM_WEBSITE_PORT 8080

// SNTP
sntp mysntp = sntp(NULL, "time.nist.gov", (short)(-8 * 60), (short)(-7 * 60), true);
SNTP_Timestamp_t now;
NetTime_t timeExtract;
char published[] = "\"2011-02-10T15:04:55Z\"";

// Constants
const int ledPin = A1;
const int loadSensorThreshold = 900;
const long minStateChangePeriod = 5000; // milliseconds

// State
FreeTakenState chairState = FREE;
long lastStateChangeMillis = 0;

uint32_t activityStreamServerIp = 0;
uint32_t adafruitIp = 0; // for testing connection

// Object Information
const char *objectType = "\"place\"";
const char *id = "\"http://example.org/fsm/chair/1\"";
char *displayName = "\"Chair1 in FSM\"";
char *descriptor_tags = "[\"chair\"]";
char* locality = "\"Berkeley\"";
char* region = "\"CA\"";

const int contentLengthMaxLength = 3; // XXX: assume 3 digits is enough
char contentLength[contentLengthMaxLength + 1]; 

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);
  
  Serial.println("Press the Start Button!");
  while (digitalRead(START_BUTTON_PIN) == LOW); // block until start button pressed
  if (USE_CC3000) {
    initializeConnection();
  }
  
  digitalWrite(ledPin, HIGH);
}

void loop() {
  // Determine new state
  int loadSensorValue = analogRead(LOAD_SENSOR_PIN);
  FreeTakenState newChairState = loadSensorValue > loadSensorThreshold ? FREE : TAKEN;
  long currentMillis = millis();

  // Only do something if the state changes.
  if (   newChairState != chairState 
      && currentMillis - lastStateChangeMillis > minStateChangePeriod) {
    // Update state
    chairState = newChairState;
    lastStateChangeMillis = currentMillis;
    stateUpdate();
  }
}

void stateUpdate() {
  char* actor = "{\"displayName\":\"Unknown\",\"objectType\":\"person\"}"; // default Unknown person

  char* verb;
  switch(chairState) {
    case FREE:
      verb = "\"leave\"";
      break;
    case TAKEN:
      verb = "\"checkin\"";
      break;      
  }

  if (USE_CC3000) {
    updatePublishedString();
    postActivityToCC3000(actor, verb, published);
  } else {
    postActivityToSerial(actor, verb, published);
  }
}

void postActivityToCC3000(char* actor, char* verb, char* published) {
  // TODO: figure out a cleaner way to specify this? Beware of memory limits
  int contentLengthVal = 
    1 + 
    1 + 5 + 2 + strlen(actor) + 
    2 + 4 + 2 + strlen(verb) +
    2 + 6 + 2 +
      1 +
      1 + 10 + 2 + strlen(objectType) +
      2 + 2 + 2 + strlen(id) +
      2 + 11 + 2 + strlen(displayName) +
      2 + 15 + 2 + strlen(descriptor_tags) +
      2 + 7 + 2 +
        1 +
        1 + 8 + 2 + strlen(locality) +
        2 + 6 + 2 + strlen(region) +
        1 +
      1 +
     2 + 9 + 2 + strlen(published) +
     2 + 8 + 2 + 1 + 1 + 11 + 2 + 15 + 1 +
     1;
  updateStringWithValue(contentLength, contentLengthVal, contentLengthMaxLength-1, 0);
  
  Serial.println(cc3000.checkConnected());
  Adafruit_CC3000_Client www = cc3000.connectTCP(activityStreamServerIp, ACTIVITY_STREAM_WEBSITE_PORT);
  if (www.connected()) {
    www.fastrprint(F("POST /activities HTTP/1.1\r\n"));
    www.fastrprint(F("Host: ")); www.fastrprint(F(ACTIVITY_STREAM_WEBSITE)); www.fastrprint(F("\r\n"));
    www.fastrprint(F("Content-Type: application/stream+json\r\n"));
    www.fastrprint(F("Content-Length: ")); www.fastrprint(contentLength); www.fastrprint(F("\r\n"));
    www.fastrprint(F("\r\n"));
    // Activity JSON
    www.fastrprint(F("{"));
    www.fastrprint(F("\"actor\":")); www.fastrprint(actor);
    www.fastrprint(F(",\"verb\":")); www.fastrprint(verb);
    www.fastrprint(F(",\"object\":"));
      // TODO: figure out a cleaner way to specify this? Beware of memory limits
      www.fastrprint(F("{"));
      www.fastrprint(F("\"objectType\":")); www.fastrprint(objectType);
      www.fastrprint(F(",\"id\":")); www.fastrprint(id);
      www.fastrprint(F(",\"displayName\":")); www.fastrprint(displayName);
      www.fastrprint(F(",\"descriptor_tags\":")); www.fastrprint(descriptor_tags);
      www.fastrprint(F(",\"address\":"));
        www.fastrprint(F("{"));
        www.fastrprint(F("\"locality\":")); www.fastrprint(locality);
        www.fastrprint(F(",\"region\":")); www.fastrprint(region);
        www.fastrprint(F("}"));
      www.fastrprint(F("}"));
    www.fastrprint(F(",\"published\":")); www.fastrprint(published);
    www.fastrprint(F(",\"provider\":{\"displayName\":\"BerkeleyChair\"}"));
    www.fastrprint(F("}"));
    www.println();

    /* Read data until either the connection is closed, or the idle timeout is reached. */ 
    unsigned long lastRead = millis();
    while (www.connected() && (millis() - lastRead < IDLE_TIMEOUT_MS)) {
      while (www.available()) {
        char c = www.read();
        Serial.print(c);
        lastRead = millis();
      }
    }
    www.close();
    Serial.println();
  } else {
    Serial.println(F("Connection failed"));    
    return;
  }
}

void postActivityToSerial(char* actor, char* verb, char* published) {
  // TODO: figure out a cleaner way to specify this? Beware of memory limits
  Serial.print(F("{"));
  Serial.print(F("\"actor\":")); Serial.print(actor);
  Serial.print(F(",\"verb\":")); Serial.print(verb);
  Serial.print(F(",\"object\":"));
    Serial.print(F("{"));
    Serial.print(F("\"objectType\":")); Serial.print(objectType);
    Serial.print(F(",\"id\":")); Serial.print(id);
    Serial.print(F(",\"displayName\":")); Serial.print(displayName);
    Serial.print(F(",\"descriptor_tags\":")); Serial.print(descriptor_tags);
    Serial.print(F(",\"address\":"));
      Serial.print(F("{"));
      Serial.print(F("\"locality\":")); Serial.print(locality);
      Serial.print(F(",\"region\":")); Serial.print(region);
      Serial.print(F("}"));
    Serial.print(F("}"));
  Serial.print(F(",\"provider\":{\"displayName\":\"BerkeleyChair\"}"));
  Serial.print(F("}"));
  Serial.println();
}

void updatePublishedString() {
    mysntp.ExtractNTPTime(mysntp.NTPGetTime(&now, true), &timeExtract);
    updateStringWithValue(published, timeExtract.year, 4, 1);
    updateStringWithValue(published, timeExtract.mon + 1, 7, 6);
    updateStringWithValue(published, timeExtract.mday, 10, 9);
    updateStringWithValue(published, timeExtract.hour, 13, 12);
    updateStringWithValue(published, timeExtract.min, 16, 15);
    updateStringWithValue(published, timeExtract.sec, 19, 18);
}

// start and end index inclusive.
// start >= end
void updateStringWithValue(char* str, int value, int start_index, int end_index) {
    for (int i =start_index; i >= end_index; i--) {
      str[i] = '0' + (value % 10);
      value = value / 10;
    }
}
/***************************************************************************
    initializeConnection

Initialize CC3000 and test connection.
Based on Adafruit example sketch WebClient.

***************************************************************************/

void initializeConnection() {
  /* Initialise the module */
  Serial.println(F("\nInitializing CC3000..."));
  if (!cc3000.begin())
  {
//    Serial.println(F("Couldn't begin()! Check your wiring?"));
    while(1);
  }
    
  Serial.print(F("\nAttempting to connect to ")); Serial.println(WLAN_SSID);
  if (!cc3000.connectToAP(WLAN_SSID, WLAN_PASS, WLAN_SECURITY)) {
//    Serial.println(F("Failed!"));
    while(1);
  }
   
  /* Wait for DHCP to complete */
  Serial.println(F("Request DHCP"));
  while (!cc3000.checkDHCP())
  {
    delay(100); // ToDo: Insert a DHCP timeout!
  }  

  /* Display the IP address DNS, Gateway, etc. */  
  while (! displayConnectionDetails()) {
    delay(1000);
  }

  // Try looking up the website's IP address
//  Serial.print(ACTIVITY_STREAM_WEBSITE); Serial.print(F(" -> "));
  while (activityStreamServerIp == 0) {
    if (! cc3000.getHostByName(ACTIVITY_STREAM_WEBSITE, &activityStreamServerIp)) {
//      Serial.println(F("Couldn't resolve!"));
    }
    delay(500);
  }
//  cc3000.printIPdotsRev(activityStreamServerIp);
//  Serial.println();
  
//  Serial.println(F("UpdateNTPTime"));
  if (mysntp.UpdateNTPTime())
  {
    Serial.println(F("Local time synced."));
  }
}


/**************************************************************************/
/*!
    @brief  Tries to read the IP address and other connection details
*/
/**************************************************************************/
bool displayConnectionDetails(void)
{
  uint32_t ipAddress, netmask, gateway, dhcpserv, dnsserv;
  
  if(!cc3000.getIPAddress(&ipAddress, &netmask, &gateway, &dhcpserv, &dnsserv))
  {
//    Serial.println(F("Unable to retrieve the IP Address!\r\n"));
    return false;
  }
  else
  {
//    Serial.print(F("\nIP Addr: ")); cc3000.printIPdotsRev(ipAddress);
//    Serial.print(F("\nNetmask: ")); cc3000.printIPdotsRev(netmask);
//    Serial.print(F("\nGateway: ")); cc3000.printIPdotsRev(gateway);
//    Serial.print(F("\nDHCPsrv: ")); cc3000.printIPdotsRev(dhcpserv);
//    Serial.print(F("\nDNSserv: ")); cc3000.printIPdotsRev(dnsserv);
//    Serial.println();
    return true;
  }
}

