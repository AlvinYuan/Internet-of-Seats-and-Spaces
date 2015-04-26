package com.example.audrey.AndroidSeats;

import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

/**
 * Created by alvin on 4/24/2015.
 */
public class BartFragment extends PlaceFragment {
    public static final String ID_PREFIX = "http://example.org/bart/car2/seat/";

    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        mainView = inflater.inflate(R.layout.bart_layout, container, false);

        // TODO: Show loading UI until query async task finishes
        QueryPlaceAsyncTask task = new QueryPlaceAsyncTask(this);
        task.execute(ID_PREFIX);

        return mainView;
    }
}
