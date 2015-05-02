package com.example.audrey.AndroidSeats;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by alvin on 4/25/2015.
 */
public class Person {
    //class variable. all instances share common static object.
    //public static final Person self = new Person("Android App",""); s

    //declaration of member variables
    String displayName;
    String regid;

    //define constructor with two parameters
    public Person(String displayName, String regid) {
        //initialize member variables
        this.displayName = displayName;
        this.regid = regid;
    }

    public JSONObject asJson() throws JSONException {
        return new JSONObject()
                .put("displayName", displayName)
                .put("objectType", "person")
                .put("device_id",regid)
                .put("system", "android");
    }
}
