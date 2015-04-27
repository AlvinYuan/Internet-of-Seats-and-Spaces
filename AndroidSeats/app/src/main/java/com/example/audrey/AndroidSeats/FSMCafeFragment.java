package com.example.audrey.AndroidSeats;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

/**
 * Created by alvin on 4/24/2015.
 * Currently assumes there will always be exactly 6 chairs with ids ID_PREFIX + 1-6.
 * TODO: Figure out how best to handle layout/logic based on activity data.
 */
public class FSMCafeFragment extends PlaceFragment {
    public static final String ID_PREFIX = "http://example.org/fsm/chair/";

    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        mainView = inflater.inflate(R.layout.fsm_cafe_layout, container, false);

        // TODO: Show loading UI until query async task finishes
        QueryPlaceAsyncTask task = new QueryPlaceAsyncTask(this);
        task.execute(ID_PREFIX);

        return mainView;
    }

}