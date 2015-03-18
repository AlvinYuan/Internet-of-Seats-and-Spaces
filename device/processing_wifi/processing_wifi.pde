import processing.serial.*;
import java.net.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

// https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing

// State
Serial myPort;  // Create object from Serial class

void setup() {
  println(Serial.list());
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200); 
}

void draw()
{
  if ( myPort.available() > 0) 
  {
    String activityString = myPort.readStringUntil('\n');
    if (activityString == null) {
      return;
    }
    println(activityString);
    postToASBase(activityString);
  }
}

// http://stackoverflow.com/questions/4205980/java-sending-http-parameters-via-post-method-easily
void postToASBase(String activityJsonString) {
  try {
    URL asBaseURL = new URL("http://russet.ischool.berkeley.edu:8080/activities");
    HttpURLConnection asBaseConn = (HttpURLConnection) asBaseURL.openConnection();
    byte[] postData = activityJsonString.getBytes("UTF-8");

    asBaseConn.setDoOutput(true);
    asBaseConn.setDoInput(true);
    asBaseConn.setRequestMethod("POST");
    asBaseConn.setRequestProperty( "Content-Type", "application/stream+json");
    asBaseConn.setRequestProperty("Content-Length", String.valueOf(postData.length));
    asBaseConn.getOutputStream().write(postData);
  
    BufferedReader in = new BufferedReader(
            new InputStreamReader(asBaseConn.getInputStream()));
    String inputLine;
    StringBuffer response = new StringBuffer();
  
    while ((inputLine = in.readLine()) != null) {
        response.append(inputLine);
    }
    in.close();
  
    //print result
    println(response.toString());
  } catch (Exception e) {
    println(e.getMessage());
    e.printStackTrace();
  }
}

