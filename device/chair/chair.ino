// Enums
enum FreeTakenState {
  FREE,
  TAKEN,
};

// Constants
const int loadSensorPin = A0;
const int ledPin = 13;
const int loadSensorThreshold = 900;
const long minStateChangePeriod = 5000; // milliseconds

// State
FreeTakenState chairState = TAKEN;
long lastStateChangeMillis = 0;

void setup() {
  pinMode(ledPin, OUTPUT);
  Serial.begin(9600); // for debugging and communicating with Processing
}

void loop() {
  // Determine new state
  int loadSensorValue = analogRead(loadSensorPin);
  FreeTakenState newChairState = loadSensorValue > loadSensorThreshold ? TAKEN : FREE;
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
      digitalWrite(ledPin, HIGH);
      verb = "\"leave\"";
      break;
    case TAKEN:
      digitalWrite(ledPin, LOW);
      verb = "\"checkin\"";
      break;      
  }
  String published = "\"2011-02-10T15:04:55Z\""; // TODO: actually determine time 
  String postData = "{\"actor\":" + actor + 
                     ",\"verb\":" + verb + 
                   ",\"object\":" + selfObjectString() + 
                ",\"published\":" + published +
                    "}";
  Serial.println(postData);
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
