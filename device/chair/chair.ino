#include <Adafruit_CC3000.h>
#include <ccspi.h>
#include <SPI.h>
#include <string.h>
#include "utility/debug.h"

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

#define WLAN_SSID       "CHANGEME"        // cannot be longer than 32 characters!
#define WLAN_PASS       "CHANGEME"
// Security can be WLAN_SEC_UNSEC, WLAN_SEC_WEP, WLAN_SEC_WPA or WLAN_SEC_WPA2
#define WLAN_SECURITY   WLAN_SEC_WPA2

#define IDLE_TIMEOUT_MS  3000      // Amount of time to wait (in milliseconds) with no data 
                                   // received before closing the connection.  If you know the server
                                   // you're accessing is quick to respond, you can reduce this value.
                                   
#define ACTIVITY_STREAM_WEBSITE      "russet.ISchool.Berkeley.EDU"
#define ACTIVITY_STREAM_WEBSITE_PORT 8080
#define ADAFRUIT_WEBSITE "www.adafruit.com"

// Constants
const int loadSensorThreshold = 900;
const long minStateChangePeriod = 5000; // milliseconds

// State
FreeTakenState chairState = TAKEN;
long lastStateChangeMillis = 0;

uint32_t activityStreamServerIp = 0;
uint32_t adafruitIp = 0; // for testing connection

// Object Information
const char *objectType = "\"place\"";
const char *id = "\"http://example.org/berkeley/southhall/202/chair/1\"";
char *displayName = "\"Chair at 202 South Hall, UC Berkeley\"";
char *descriptor_tags = "[\"chair\",\"rolling\"]";
char* latitude = "34.34";
char* longitude = "-127.23";
char* altitude = "100.05";

void setup() {
  Serial.begin(115200);

  Serial.println("Press the Start Button!");
  while (digitalRead(START_BUTTON_PIN) == LOW); // block until start button pressed
  if (USE_CC3000) {
    initializeConnection();
  }
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
  char* published = "\"2011-02-10T15:04:55Z\""; // TODO: actually determine time
  if (USE_CC3000) {
    postActivityToCC3000(actor, verb, published);
  } else {
    postActivityToSerial(actor, verb, published);
  }
}

void postActivityToCC3000(char* actor, char* verb, char* published) {
  // TODO: figure out a cleaner way to specify this? Beware of memory limits
  int contentLength = 
    1 + 
    1 + 5 + 2 + strlen(actor) + 
    2 + 4 + 2 + strlen(verb) +
    2 + 6 + 2 +
      1 +
      1 + 10 + 2 + strlen(objectType) +
      2 + 2 + 2 + strlen(id) +
      2 + 11 + 2 + strlen(displayName) +
      2 + 15 + 2 + strlen(descriptor_tags) +
      2 + 8 + 2 +
        1 +
        1 + 8 + 2 + strlen(latitude) +
        2 + 9 + 2 + strlen(longitude) +
        2 + 8 + 2 + strlen(altitude) +
        1 +
      1 +
     2 + 9 + 2 + strlen(published) +
     1;
  String contentLengthString = String(contentLength);
  int contentLengthCLength = contentLengthString.length() + 1;
  char contentLengthC[contentLengthCLength];
  contentLengthString.toCharArray(contentLengthC, contentLengthCLength);
  Serial.println(cc3000.checkConnected());
  Adafruit_CC3000_Client www = cc3000.connectTCP(activityStreamServerIp, ACTIVITY_STREAM_WEBSITE_PORT);
  if (www.connected()) {
    www.fastrprint(F("POST /activities HTTP/1.1\r\n"));
    www.fastrprint(F("Host: ")); www.fastrprint(F(ACTIVITY_STREAM_WEBSITE)); www.fastrprint(F("\r\n"));
    www.fastrprint(F("Content-Type: application/stream+json\r\n"));
    www.fastrprint(F("Content-Length: ")); www.fastrprint(contentLengthC); www.fastrprint(F("\r\n"));
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
      www.fastrprint(F(",\"position\":"));
        www.fastrprint(F("{"));
        www.fastrprint(F("\"latitude\":")); www.fastrprint(latitude);
        www.fastrprint(F(",\"longitude\":")); www.fastrprint(longitude);
        www.fastrprint(F(",\"altitude\":")); www.fastrprint(altitude);
        www.fastrprint(F("}"));
      www.fastrprint(F("}"));
    www.fastrprint(F(",\"published\":")); www.fastrprint(published);
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
    Serial.print(F(",\"position\":"));
      Serial.print(F("{"));
      Serial.print(F("\"latitude\":")); Serial.print(latitude);
      Serial.print(F(",\"longitude\":")); Serial.print(longitude);
      Serial.print(F(",\"altitude\":")); Serial.print(altitude);
      Serial.print(F("}"));
    Serial.print(F("}"));
  Serial.print(F(",\"published\":")); Serial.print(published);
  Serial.print(F("}"));
  Serial.println();
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
    Serial.println(F("Couldn't begin()! Check your wiring?"));
    while(1);
  }
    
  Serial.print(F("\nAttempting to connect to ")); Serial.println(WLAN_SSID);
  if (!cc3000.connectToAP(WLAN_SSID, WLAN_PASS, WLAN_SECURITY)) {
    Serial.println(F("Failed!"));
    while(1);
  }
   
  Serial.println(F("Connected!"));
  
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
  Serial.print(ACTIVITY_STREAM_WEBSITE); Serial.print(F(" -> "));
  while (activityStreamServerIp == 0) {
    if (! cc3000.getHostByName(ACTIVITY_STREAM_WEBSITE, &activityStreamServerIp)) {
      Serial.println(F("Couldn't resolve!"));
    }
    delay(500);
  }
  cc3000.printIPdotsRev(activityStreamServerIp);
  Serial.println();
  
  testConnect();

}

void testConnect() {
  // Try looking up adafruit IP address
  Serial.print(ADAFRUIT_WEBSITE); Serial.print(F(" -> "));
  while (adafruitIp == 0) {
    if (! cc3000.getHostByName(ADAFRUIT_WEBSITE, &adafruitIp)) {
      Serial.println(F("Couldn't resolve!"));
    }
    delay(500);
  }

  cc3000.printIPdotsRev(adafruitIp);
  Serial.println();

  /* Try connecting to the website.
     Note: HTTP/1.1 protocol is used to keep the server from closing the connection before all data is read.
  */
  Adafruit_CC3000_Client www = cc3000.connectTCP(adafruitIp, 80);
  if (www.connected()) {
    www.fastrprint(F("GET "));
    www.fastrprint("/testwifi/index.html");
    www.fastrprint(F(" HTTP/1.1\r\n"));
    www.fastrprint(F("Host: ")); www.fastrprint(ADAFRUIT_WEBSITE); www.fastrprint(F("\r\n"));
    www.fastrprint(F("\r\n"));
    www.println();
  } else {
    Serial.println(F("Connection failed"));    
    return;
  }

  /* Read data until either the connection is closed, or the idle timeout is reached. */ 
  unsigned long lastRead = millis();
  int count = 0;
  while (www.connected() && (millis() - lastRead < IDLE_TIMEOUT_MS)) {
    while (www.available()) {
      char c = www.read();
      Serial.print(c);
      count = count + 1;
      lastRead = millis();
    }
  }
  www.close();
  Serial.println(count);
}

/**************************************************************************/
/*!
    @brief  Displays the driver mode (tiny of normal), and the buffer
            size if tiny mode is not being used

    @note   The buffer size and driver mode are defined in cc3000_common.h
*/
/**************************************************************************/
void displayDriverMode(void)
{
  #ifdef CC3000_TINY_DRIVER
    Serial.println(F("CC3000 is configure in 'Tiny' mode"));
  #else
    Serial.print(F("RX Buffer : "));
    Serial.print(CC3000_RX_BUFFER_SIZE);
    Serial.println(F(" bytes"));
    Serial.print(F("TX Buffer : "));
    Serial.print(CC3000_TX_BUFFER_SIZE);
    Serial.println(F(" bytes"));
  #endif
}

/**************************************************************************/
/*!
    @brief  Tries to read the CC3000's internal firmware patch ID
*/
/**************************************************************************/
uint16_t checkFirmwareVersion(void)
{
  uint8_t major, minor;
  uint16_t version;
  
#ifndef CC3000_TINY_DRIVER  
  if(!cc3000.getFirmwareVersion(&major, &minor))
  {
    Serial.println(F("Unable to retrieve the firmware version!\r\n"));
    version = 0;
  }
  else
  {
    Serial.print(F("Firmware V. : "));
    Serial.print(major); Serial.print(F(".")); Serial.println(minor);
    version = major; version <<= 8; version |= minor;
  }
#endif
  return version;
}

/**************************************************************************/
/*!
    @brief  Tries to read the 6-byte MAC address of the CC3000 module
*/
/**************************************************************************/
void displayMACAddress(void)
{
  uint8_t macAddress[6];
  
  if(!cc3000.getMacAddress(macAddress))
  {
    Serial.println(F("Unable to retrieve MAC Address!\r\n"));
  }
  else
  {
    Serial.print(F("MAC Address : "));
    cc3000.printHex((byte*)&macAddress, 6);
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
    Serial.println(F("Unable to retrieve the IP Address!\r\n"));
    return false;
  }
  else
  {
    Serial.print(F("\nIP Addr: ")); cc3000.printIPdotsRev(ipAddress);
    Serial.print(F("\nNetmask: ")); cc3000.printIPdotsRev(netmask);
    Serial.print(F("\nGateway: ")); cc3000.printIPdotsRev(gateway);
    Serial.print(F("\nDHCPsrv: ")); cc3000.printIPdotsRev(dhcpserv);
    Serial.print(F("\nDNSserv: ")); cc3000.printIPdotsRev(dnsserv);
    Serial.println();
    return true;
  }
}

