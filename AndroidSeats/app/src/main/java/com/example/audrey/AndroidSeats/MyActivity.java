package com.example.audrey.AndroidSeats;

import android.os.AsyncTask;
import android.support.v7.app.ActionBar;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;

import org.json.JSONObject;
import org.json.JSONArray;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

import static android.view.View.OnClickListener;


public class MyActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

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
