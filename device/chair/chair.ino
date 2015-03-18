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
const int LED_PIN = 13;


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
                                   
#define WEBSITE      "www.adafruit.com"
#define WEBPAGE      "/testwifi/index.html"

// Constants
const int loadSensorThreshold = 900;
const long minStateChangePeriod = 5000; // milliseconds

// State
FreeTakenState chairState = TAKEN;
long lastStateChangeMillis = 0;


void setup() {
  pinMode(LED_PIN, OUTPUT);
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
//  Serial.println(loadSensorValue);
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
  String actor = "{\"displayName\":\"Unknown\",\"objectType\":\"person\"}"; // default Unknown person
  String verb;
  switch(chairState) {
    case FREE:
      digitalWrite(LED_PIN, HIGH);
      verb = "\"leave\"";
      break;
    case TAKEN:
      digitalWrite(LED_PIN, LOW);
      verb = "\"checkin\"";
      break;      
  }
  String published = "\"2011-02-10T15:04:55Z\""; // TODO: actually determine time
  if (USE_CC3000) {
  } else {
    postActivityToSerial(actor, verb, published);
  }
}

void postActivityToSerial(String actor, String verb, String published) {
  Serial.print("{\"actor\":");
  Serial.print(actor);
  Serial.print(",\"verb\":");
  Serial.print(verb);
  Serial.print(",\"object\":");
  Serial.print(selfObjectString());
  Serial.print(",\"published\":");
  Serial.print(published);
  Serial.println("}");
}

String selfObjectString() {
  String objectType = "\"place\"";
  int id = 1;
  String idString = "\"http://example.org/berkeley/southhall/202/chair/" + String(id) + "\"";
  String displayName = "\"Chair at 202 South Hall, UC Berkeley\"";
  String descriptor_tags = "[\"chair\",\"rolling\"]";
  return "{\"objectType\":" + objectType + 
                 ",\"id\":" + idString + 
        ",\"displayName\":" + displayName + 
    ",\"descriptor_tags\":" + descriptor_tags + 
           ",\"position\":" + selfPositionString() +
         "}";
}

String selfPositionString() {
  String latitude = "34.34";
  String longitude = "-127.23";
  String altitude = "100.05";
  return "{\"latitude\":" + latitude +
        ",\"longitude\":" + longitude + 
         ",\"altitude\":" + altitude +
         "}";
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

  uint32_t ip = 0;
  // Try looking up the website's IP address
  Serial.print(WEBSITE); Serial.print(F(" -> "));
  while (ip == 0) {
    if (! cc3000.getHostByName(WEBSITE, &ip)) {
      Serial.println(F("Couldn't resolve!"));
    }
    delay(500);
  }

  cc3000.printIPdotsRev(ip);

  /* Try connecting to the website.
     Note: HTTP/1.1 protocol is used to keep the server from closing the connection before all data is read.
  */
  Adafruit_CC3000_Client www = cc3000.connectTCP(ip, 80);
  if (www.connected()) {
    www.fastrprint(F("GET "));
    www.fastrprint(WEBPAGE);
    www.fastrprint(F(" HTTP/1.1\r\n"));
    www.fastrprint(F("Host: ")); www.fastrprint(WEBSITE); www.fastrprint(F("\r\n"));
    www.fastrprint(F("\r\n"));
    www.println();
  } else {
    Serial.println(F("Connection failed"));    
    return;
  }

  Serial.println(F("-------------------------------------"));
  
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
  Serial.println(F("-------------------------------------"));
  
  /* You need to make sure to clean up after yourself or the CC3000 can freak out */
  /* the next time your try to connect ... */
  Serial.println(F("\n\nDisconnecting"));
  cc3000.disconnect();
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

