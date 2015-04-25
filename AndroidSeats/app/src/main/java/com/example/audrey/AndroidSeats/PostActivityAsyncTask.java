package com.example.audrey.AndroidSeats;

import android.os.AsyncTask;
import android.util.Log;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Created by alvin on 4/24/2015.
 */
class PostActivityAsyncTask extends AsyncTask<JSONObject, Integer, Void> {

    @Override
    protected Void doInBackground(JSONObject... params) {
        postToASBase(params[0].toString());
        return null;
    }

    public void postToASBase(String activityJsonString) {
        // http://stackoverflow.com/questions/4205980/java-sending-http-parameters-via-post-method-easily

        try {
            URL asBaseURL = new URL("http://russet.ischool.berkeley.edu:8080/activities");
            HttpURLConnection asBaseConn = (HttpURLConnection) asBaseURL.openConnection();

            byte[] postData = activityJsonString.getBytes("UTF-8");

            asBaseConn.setDoOutput(true);
            asBaseConn.setDoInput(true);
            asBaseConn.setRequestMethod("POST");
            asBaseConn.setRequestProperty("Content-Type", "application/stream+json");
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
            Log.d(this.getClass().getSimpleName(), response.toString());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}