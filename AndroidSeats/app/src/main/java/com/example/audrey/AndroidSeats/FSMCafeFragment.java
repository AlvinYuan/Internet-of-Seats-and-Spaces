package com.example.audrey.AndroidSeats;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Created by alvin on 4/24/2015.
 */
public class FSMCafeFragment extends Fragment implements View.OnClickListener {
    private static final String TAG = "MyActivity";
    private Button btn;

    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fsm_cafe_layout, container, false);

        btn=(Button) v.findViewById(R.id.button);
        btn.setOnClickListener(this);

        return v;
    }

    public void onClick(View v) {
        Log.d("Test", "Hello World!");
        doAsyncPost();
    }

    public void doAsyncPost() {
        //http://stackoverflow.com/questions/13911993/sending-a-json-http-post-request-from-android
        //Create JSONObject
        JSONObject jsonParam = new JSONObject();
        try {
            jsonParam.put("actor", "Audrey's Awesome Android App")
                    .put("verb", "request")
                    .put("object", new JSONObject()
                            .put("objectType", "place")
                            .put("id", "http://example.org/berkeley/southhall/202/chair/1")
                            .put("displayName", "Chair at 202 South Hall, UC Berkeley")
                            .put("position", new JSONObject()
                                    .put("latitude", 34.34)
                                    .put("longitude", -127.23)
                                    .put("altitude", 100.05)))
                    .put("descriptor-tags", new JSONArray()
                            .put("chair")
                            .put("rolling"));
        } catch (Exception e) {
            Log.e("error", e.getMessage());
        }

        Log.d(TAG, jsonParam.toString());

        PostActivityAsyncTask task = new PostActivityAsyncTask();
        task.execute(jsonParam);
    }
}