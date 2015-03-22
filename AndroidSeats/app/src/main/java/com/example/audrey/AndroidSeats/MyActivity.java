package com.example.audrey.AndroidSeats;

import android.os.AsyncTask;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

import static android.view.View.OnClickListener;


public class MyActivity extends ActionBarActivity implements OnClickListener {

    private static final String TAG = "MyActivity";
    private Button btn;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_my);
        btn=(Button)findViewById(R.id.button);
        btn.setOnClickListener(this);
    }

    public void onClick(View v) {
        Log.d("Test", "Hello World!");
        doAsyncPost();
    }

    public void doAsyncPost() {
        //http://stackoverflow.com/questions/13911993/sending-a-json-http-post-request-from-android
        //Create JSONObject
        JSONObject jsonParam = new JSONObject();
        try{
            jsonParam.put("actor", "Audrey's Awesome Android App");
            jsonParam.put("verb", "kVerbPost");
            jsonParam.put("id", "chairID");
        } catch (Exception e) {
            Log.d("error","Err1 message");
        }

        Log.e(TAG, jsonParam.toString());

        MyAsyncTask task = new MyAsyncTask();
        task.execute(jsonParam);
    }

    class MyAsyncTask extends AsyncTask<JSONObject, Integer, Void> {

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
                Log.d(TAG, response.toString());
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_my, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
