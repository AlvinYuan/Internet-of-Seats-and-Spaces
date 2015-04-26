package com.example.audrey.AndroidSeats;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Calendar;

/**
 * Created by alvin on 4/25/2015.
 * Helper functions for dealing with activities.
 */
public class ActivityUtil {
    public static final JSONObject providerJson = new JSONObject();
    static {
        try {
            providerJson.put("displayName", "BerkeleyChair");
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public static String getTimeStamp() {
        Calendar cal = Calendar.getInstance();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
        return sdf.format(cal.getTime());
    }

    // May need to revisit this logic if we add more functionality
    public static JSONObject getPlace(JSONObject activity) throws JSONException {
        String verb = activity.getString("verb");
        if (verb.equals("approve") || verb.equals("deny")) {
            return activity.getJSONObject("object").getJSONObject("object");
        } else {
            return activity.getJSONObject("object");
        }

    }


}
