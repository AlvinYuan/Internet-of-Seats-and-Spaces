package com.example.audrey.AndroidSeats;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by alvin on 4/25/2015.
 */
public class Person {
    public static final Person self = new Person("Android App"); // TODO: customize self name

    String displayName;

    public Person(String displayName) {
        this.displayName = displayName;
    }

    public JSONObject asJson() throws JSONException {
        return new JSONObject()
                .put("displayName", displayName)
                .put("objectType", "person");
    }
}
