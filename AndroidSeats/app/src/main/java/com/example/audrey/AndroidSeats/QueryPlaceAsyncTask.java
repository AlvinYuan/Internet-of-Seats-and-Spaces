package com.example.audrey.AndroidSeats;

import android.os.AsyncTask;
import android.util.Log;
import android.view.View;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;

/**
 * Created by alvin on 4/24/2015.
 */
class QueryPlaceAsyncTask extends AsyncTask<String, Integer, JSONObject> {
    private static final String TAG = QueryPlaceAsyncTask.class.getSimpleName();
    PlaceFragment placeFragment;

    public QueryPlaceAsyncTask(PlaceFragment placeFragment) {
        super();
        this.placeFragment = placeFragment;
    }

    @Override
    protected JSONObject doInBackground(String... params) {
        String id_prefix = params[0];
        try {
            JSONObject activityTemplate = new JSONObject()
                .put("verb", new JSONObject()
                        .put("$in", new JSONArray()
                                .put("checkin")
                                .put("leave")
                                .put("request")
                                .put("approve")
                                .put("deny")))
                .put("$or", new JSONArray()
                        .put(new JSONObject()
                                .put("object.id", new JSONObject()
                                        .put("$regex", id_prefix)))
                        .put(new JSONObject()
                                .put("object.object.id", new JSONObject()
                                        .put("$regex", id_prefix))));
            return queryASBase(activityTemplate.toString());
        } catch (JSONException e) {
            e.printStackTrace();
            return null;
        }


    }

    // TODO: refactor to avoid duplicate code with PostActivityAsyncTask
    public JSONObject queryASBase(String activityTemplateJsonString) {
        // http://stackoverflow.com/questions/4205980/java-sending-http-parameters-via-post-method-easily

        try {
            URL asBaseURL = new URL("http://russet.ischool.berkeley.edu:8080/query");
            HttpURLConnection asBaseConn = (HttpURLConnection) asBaseURL.openConnection();

            byte[] postData = activityTemplateJsonString.getBytes("UTF-8");

            asBaseConn.setDoOutput(true);
            asBaseConn.setDoInput(true);
            asBaseConn.setRequestMethod("POST");
            asBaseConn.setRequestProperty("Content-Type", "application/json");
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
            return new JSONObject(response.toString());
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    @Override
    protected void onPostExecute(JSONObject jsonObject) {
        if (jsonObject == null) {
            // TODO: display error message
            Log.e(TAG, "Error, no valid response!");
            return;
        }

        ArrayList<String> foundPlaceIds = new ArrayList<String>();

        try {
            int totalItems = jsonObject.getInt("totalItems");
            JSONArray items = jsonObject.getJSONArray("items");
            for (int i = 0; i < totalItems; i++) {
                JSONObject activity = (JSONObject) items.get(i);
                Place p = new Place(activity);
                // ASSUMPTION: items are in chronological order, newest first
                // TODO: Change this logic when future reservations are supported.
                if (!foundPlaceIds.contains(p.id())) {
                    foundPlaceIds.add(p.id());

                    View v = placeFragment.viewForPlace(p);
                    placeFragment.placeMap.put(v, p);
                    placeFragment.refreshViewForPlace(p);
                    v.setOnClickListener(placeFragment);
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
}