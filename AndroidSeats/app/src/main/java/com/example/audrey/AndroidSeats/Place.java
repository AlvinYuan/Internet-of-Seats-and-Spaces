package com.example.audrey.AndroidSeats;

import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Collections;
import java.util.Hashtable;
import java.util.Map;

/**
 * Created by alvin on 4/25/2015.
 * Currently does not consider time of reservation request.
 * Assumes all reservation requests are for the current time.
 * TODO: support time specification of requests
 */
public class Place {
    public enum Status {
        AVAILABLE, UNAVAILABLE, REQUESTED, RESERVED
    }
    public static final Map<String, Status> statusMap;
    static {
        Hashtable<String, Status> map = new Hashtable<String, Status>();
        map.put("leave", Status.AVAILABLE);
        map.put("checkin", Status.UNAVAILABLE);
        map.put("request", Status.REQUESTED);
        map.put("approve", Status.RESERVED);
        map.put("deny", Status.AVAILABLE);
        statusMap = Collections.unmodifiableMap(map);
    }

    public Status status;
    JSONObject jsonObject;

    public Place(JSONObject activity) throws JSONException {
        updateStatus(activity);

    }

    public String id() throws JSONException {
        return jsonObject.getString("id");
    }

    // ASSUMPTION: activity verb is in statusMap.keys()
    public void updateStatus(JSONObject activity) throws JSONException {
        jsonObject = ActivityUtil.getPlace(activity);
        status = statusMap.get(activity.getString("verb"));
    }

    // ASSUMPTION: Controller logic ensures this is called only when it makes sense.
    public void request() throws JSONException {
        //http://stackoverflow.com/questions/13911993/sending-a-jsonObject-http-post-request-from-android
        // Create Activity
        JSONObject activity = new JSONObject()
            .put("actor", Person.self.asJson())
            .put("verb", "request")
            .put("object", jsonObject)
            .put("provider", ActivityUtil.providerJson)
            .put("published", ActivityUtil.getTimeStamp());
        Log.d(this.getClass().getSimpleName() + id(), activity.toString());

        // Post Activity
        PostActivityAsyncTask task = new PostActivityAsyncTask();
        task.execute(activity);
    }
}
