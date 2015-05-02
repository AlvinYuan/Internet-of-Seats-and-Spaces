package com.example.audrey.AndroidSeats;

import android.app.Activity;
import android.app.IntentService;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.NotificationCompat;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v4.content.WakefulBroadcastReceiver;
import android.support.v7.app.ActionBar;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.gcm.GoogleCloudMessaging;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Main UI for the app. Register for GCM.
 * An Android application needs to register with GCM servers
 * before it can receive messages. When an app registers,
 * it receives a registration ID, which it can then store
 * for future use (note that registration IDs must be kept secret)
 * adapted from: https://developer.android.com/google/gcm/client.html
 */

public class MyActivity extends ActionBarActivity {

    private static final String TAG = "MyActivity"; //tag used in log mesgs
    private final static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;
    public static final String EXTRA_MESSAGE = "message";
    public static final String PROPERTY_REG_ID = "registration_id";
    private static final String PROPERTY_APP_VERSION = "appVersion";

    // These should match how the server sends GCM messages.
    static final public String MESSAGE_KEY = "message";
    static final public String PLACE_STATUS_UPDATE_MESSAGE = "Place Status Update";
    static final public String ACTIVITY_KEY = "activity";

    /**
     * Substitute you own sender ID here. This is the project number you got
     * from the API Console, as described in "Getting Started."
     */
    String SENDER_ID = "994765306421";

    GoogleCloudMessaging gcm;
    AtomicInteger msgId = new AtomicInteger();
    SharedPreferences prefs;
    Context context;
    BroadcastReceiver receiver;

    String regid;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

//        setContentView(R.layout.activity_my);

        ActionBar actionBar = getSupportActionBar();
        System.out.println(actionBar);
        actionBar.setNavigationMode(ActionBar.NAVIGATION_MODE_TABS);

        ActionBar.Tab FSMCafeTab = actionBar.newTab();
        FSMCafeTab.setText("FSM Cafe");
        FSMCafeTab.setTabListener(new SpaceTabListener<FSMCafeFragment>(this, "FSM Cafe", FSMCafeFragment.class));
        actionBar.addTab(FSMCafeTab);

        ActionBar.Tab bartTab = actionBar.newTab();
        bartTab.setText("Bart");
        bartTab.setTabListener(new SpaceTabListener<BartFragment>(this, "Bart", BartFragment.class));
        actionBar.addTab(bartTab);

        //Check the device to make sure it has the Google Play Services APK.
        //The check in onCreate() ensures that the app can't be used without a successful check.
        context = getApplicationContext();
        // Check device for Play Services APK.  If check succeeds, proceed with
        //  GCM registration.
        if (checkPlayServices()) {
            gcm = GoogleCloudMessaging.getInstance(this);
            regid = getRegistrationId(context);
            Log.d(TAG,"registration ID is:" + regid);

             if (regid.isEmpty()) {
                registerInBackground();
             }
        } else {
            Log.i(TAG, "No valid Google Play Services APK found.");
        }

        // http://stackoverflow.com/questions/14695537/android-update-activity-ui-from-service
        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Log.d(TAG, "Activity received local broadcast");
                if (intent.hasExtra(ACTIVITY_KEY)) {
                    String s = intent.getStringExtra(ACTIVITY_KEY);
                    try {
                        handleMessageJson(new JSONObject(s));
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                } else {
                    Log.e(TAG, "No activity key found in intent");
                    Log.e(TAG, intent.getExtras().toString());
                }
            }
        };
    }


    @Override
    //The check in onResume() ensures that if the user returns to the running app through
    //some other means, such as through the back button, the check is still performed.
    protected void onResume() {
        super.onResume();
        checkPlayServices();
    }

    @Override
    protected void onStart() {
        super.onStart();
        LocalBroadcastManager.getInstance(this).registerReceiver((receiver),
                new IntentFilter(PLACE_STATUS_UPDATE_MESSAGE)
        );
    }

    @Override
    protected void onStop() {
        LocalBroadcastManager.getInstance(this).unregisterReceiver(receiver);
        super.onStop();
    }

    /**
     * Check the device to make sure it has the Google Play Services APK. If
     * it doesn't, display a dialog that allows users to download the APK from
     * the Google Play Store or enable it in the device's system settings.
     */
    private boolean checkPlayServices() {
        int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(this);
        if (resultCode != ConnectionResult.SUCCESS) {
            if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
                GooglePlayServicesUtil.getErrorDialog(resultCode, this,
                        PLAY_SERVICES_RESOLUTION_REQUEST).show();
            } else {
                Log.i(TAG, "This device is not supported.");
                finish();
            }
            return false;
        }
        return true;
    }

    /**
     * Gets the current registration ID for application on GCM service.
     * <p>
     * If result is empty, the app needs to register.
     *
     * @return registration ID, or empty string if there is no existing
     *         registration ID.
     */
    private String getRegistrationId(Context context) {
        final SharedPreferences prefs = getGCMPreferences(context);
        String registrationId = prefs.getString(PROPERTY_REG_ID, "");
        if (registrationId.isEmpty()) {
            Log.i(TAG, "Registration not found.");
            return "";
        }
        // Check if app was updated; if so, it must clear the registration ID
        // since the existing registration ID is not guaranteed to work with
        // the new app version.
        int registeredVersion = prefs.getInt(PROPERTY_APP_VERSION, Integer.MIN_VALUE);
        int currentVersion = getAppVersion(context);
        if (registeredVersion != currentVersion) {
            Log.i(TAG, "App version changed.");
            return "";
        }
        return registrationId;
    }

    /**
     * @return Application's {@code SharedPreferences}.
     */
    private SharedPreferences getGCMPreferences(Context context) {
        // This sample app persists the registration ID in shared preferences, but
        // how you store the registration ID in your app is up to you.
        return getSharedPreferences(MyActivity.class.getSimpleName(),
                Context.MODE_PRIVATE);
    }

    /**
     * @return Application's version code from the {@code PackageManager}.
     */
    private static int getAppVersion(Context context) {
        try {
            PackageInfo packageInfo = context.getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0);
            return packageInfo.versionCode;
        } catch (PackageManager.NameNotFoundException e) {
            // should never happen
            throw new RuntimeException("Could not get package name: " + e);
        }
    }

    /**
     * Registers the application with GCM servers asynchronously.
     * <p>
     * Stores the registration ID and app versionCode in the application's
     * shared preferences.
     */
    private void registerInBackground() {
        AsyncTask t = new AsyncTask() {
            @Override
            protected Object doInBackground(Object[] params) {
                Log.d(TAG,"start registration doInBackground");
                String msg = "";
                try {
                    if (gcm == null) {
                        gcm = GoogleCloudMessaging.getInstance(context);
                    }
                    regid = gcm.register(SENDER_ID);
                    msg = "Device registered, registration ID=" + regid;

                    // You should send the registration ID to your server over HTTP,
                    // so it can use GCM/HTTP or CCS to send messages to your app.
                    // The request to your server should be authenticated if your app
                    // is using accounts.
                    sendRegistrationIdToBackend();
                    Log.d(TAG,"sendRegistrationIdToBackend");
                    // Persist the registration ID - no need to register again.
                    storeRegistrationId(context, regid);
                    Log.d(TAG,"registration ID stored");
                } catch (IOException ex) {
                    msg = "Error :" + ex.getMessage();
                    // If there is an error, don't just keep trying to register.
                    // Require the user to click a button again, or perform
                    // exponential back-off.
                }
                return msg;
            }
        };
        t.execute(null, null);
    }

    class SendRegIdAsyncTask extends AsyncTask<JSONObject, Integer, Void> {
        @Override
        protected Void doInBackground(JSONObject... params) {
            Log.d(TAG,"send registration async task doInBackground");
            postToServer(params[0].toString());
            return null;
        }

        public void postToServer(String deviceJsonString) {
            // http://stackoverflow.com/questions/4205980/java-sending-http-parameters-via-post-method-easily
            Log.d(TAG,"post to server running");
            try {
                URL serverURL = new URL("http://serene-wave-9290.herokuapp.com/register_device/");
                HttpURLConnection serverConn = (HttpURLConnection) serverURL.openConnection();

                byte[] postData = deviceJsonString.getBytes("UTF-8");

                serverConn.setDoOutput(true);
                serverConn.setDoInput(true);
                serverConn.setRequestMethod("POST");
                serverConn.setRequestProperty("Content-Type", "application/stream+json");
                serverConn.setRequestProperty("Content-Length", String.valueOf(postData.length));
                serverConn.getOutputStream().write(postData);

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(serverConn.getInputStream()));
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

    /**
     * Sends the registration ID to your server over HTTP, so it can use GCM/HTTP
     * or CCS to send messages to your app. Not needed for this demo since the
     * device sends upstream messages to a server that echoes back the message
     * using the 'from' address in the message.
     */
    private void sendRegistrationIdToBackend() {
        // Implementation of connecting to server here
        // Create a subclass of AsyncTask and instance of subclass
        SendRegIdAsyncTask send = new SendRegIdAsyncTask();
        Log.d(TAG,"send registration id async task running");
        //http://stackoverflow.com/questions/13911993/sending-a-jsonObject-http-post-request-from-android
        try {
            JSONObject deviceJSON = new JSONObject()
                    .put("device_token",regid)
                    .put("system", "Android");
            send.execute(deviceJSON);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Log.d(TAG,"send registration id finished");
    }

    /**
     * Stores the registration ID and app versionCode in the application's
     * {@code SharedPreferences}.
     *
     * @param context application's context.
     * @param regId registration ID
     */
    private void storeRegistrationId(Context context, String regId) {
        final SharedPreferences prefs = getGCMPreferences(context);
        int appVersion = getAppVersion(context);
        Log.i(TAG, "Saving regId on app version " + appVersion);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(PROPERTY_REG_ID, regId);
        editor.putInt(PROPERTY_APP_VERSION, appVersion);
        editor.commit();
    }

    /**RECEIVE A DOWNSTREAM MESSAGE*///////////////////////////////////////////////

    //A broadcast receiver is the mechanism GCM uses to deliver messages.

    public static class GcmBroadcastReceiver extends WakefulBroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            Log.d(TAG, "received message" + intent);
            // Explicitly specify that GcmIntentService will handle the intent.
            ComponentName comp = new ComponentName(context.getPackageName(),
                    GcmIntentService.class.getName());
            // Start the service, keeping the device awake while it is launching.
            startWakefulService(context, (intent.setComponent(comp)));
            setResultCode(Activity.RESULT_OK);
        }
    }

    /**This snippet processes the GCM message based on message type, and posts
     the result in a notification */

    public static class GcmIntentService extends IntentService {
        public static final int NOTIFICATION_ID = 1;
        private NotificationManager mNotificationManager;
        NotificationCompat.Builder builder;

        public GcmIntentService() {
            super("GcmIntentService");
        }

        @Override
        protected void onHandleIntent(Intent intent) {
            Bundle extras = intent.getExtras();
            GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(this);
            // The getMessageType() intent parameter must be the intent you received
            // in your BroadcastReceiver.
            String messageType = gcm.getMessageType(intent);

            if (!extras.isEmpty()) {  // has effect of unparcelling Bundle
            /*
             * Filter messages based on message type. Since it is likely that GCM
             * will be extended in the future with new message types, just ignore
             * any message types you're not interested in, or that you don't
             * recognize.
             */
                if (GoogleCloudMessaging.
                        MESSAGE_TYPE_SEND_ERROR.equals(messageType)) {
                    sendNotification("Send error: " + extras.toString());
                } else if (GoogleCloudMessaging.
                        MESSAGE_TYPE_DELETED.equals(messageType)) {
                    sendNotification("Deleted messages on server: " +
                            extras.toString());
                    // If it's a regular GCM message, do some work.
                } else if (GoogleCloudMessaging.
                        MESSAGE_TYPE_MESSAGE.equals(messageType)) {
                    Log.i(TAG, "Received: " + extras.toString());
                    if (intent.hasExtra(MESSAGE_KEY) && extras.getString(MESSAGE_KEY).equals(PLACE_STATUS_UPDATE_MESSAGE)) {
                        // Got a place status update. Broadcast (forward) it to the activity.
                        LocalBroadcastManager broadcaster = LocalBroadcastManager.getInstance(this);
                        intent.setAction(PLACE_STATUS_UPDATE_MESSAGE);
                        broadcaster.sendBroadcast(intent);
                        Log.d(TAG, "Locally broadcasted received intent");
                    }
                }
            }
            // Release the wake lock provided by the WakefulBroadcastReceiver.
            GcmBroadcastReceiver.completeWakefulIntent(intent);
        }

        // Put the message into a notification and post it.

        private void sendNotification(String msg) {
            mNotificationManager = (NotificationManager)
                    this.getSystemService(Context.NOTIFICATION_SERVICE);

            PendingIntent contentIntent = PendingIntent.getActivity(this, 0,
                    new Intent(this, MyActivity.class), 0);

            NotificationCompat.Builder mBuilder =
                    new NotificationCompat.Builder(this)
                            .setSmallIcon(R.mipmap.ic_launcher)
                            .setContentTitle("GCM Notification")
                            .setStyle(new NotificationCompat.BigTextStyle()
                                    .bigText(msg))
                            .setContentText(msg);

            mBuilder.setContentIntent(contentIntent);
            mNotificationManager.notify(NOTIFICATION_ID, mBuilder.build());
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

    void handleMessageJson(JSONObject activity) throws JSONException {
        FragmentManager fragmentManager = getSupportFragmentManager();
        Fragment currentFragment = fragmentManager.findFragmentById(android.R.id.content);
        Log.d(TAG, activity.toString());
        Log.d(TAG, ActivityUtil.getPlace(activity).getString("id"));
        Log.d(TAG, currentFragment.toString());
        if (currentFragment instanceof PlaceFragment) {
            PlaceFragment currentPlaceFragment = (PlaceFragment) currentFragment;
            View v = currentPlaceFragment.viewForPlace(ActivityUtil.getPlace(activity).getString("id"));
            // view can be null if the current fragment does not have the place that was updated in the message
            if (v != null) {
                Log.d(TAG, v.toString());
                Place p = currentPlaceFragment.placeMap.get(v);
                p.updateStatus(activity);
                currentPlaceFragment.refreshViewForPlace(p);
            } else {
                Log.d(TAG, "No view found for id");
            }
        } else {
            Log.e(getClass().getSimpleName(), "Current Fragment is not Place Fragment");
        }
//            sendNotification("Received: " + activity.toString());
    }
}

