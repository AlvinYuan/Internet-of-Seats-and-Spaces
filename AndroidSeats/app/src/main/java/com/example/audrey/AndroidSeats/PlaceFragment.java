package com.example.audrey.AndroidSeats;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import org.json.JSONException;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by alvin on 4/25/2015.
 */
public abstract class PlaceFragment extends Fragment implements View.OnClickListener {
    private static final String TAG = "PlaceFragment";
    Map<View, Place> placeMap = new HashMap<View, Place>();
    View mainView;

    View viewForPlace(Place p) throws JSONException {
        return viewForPlace(p.id());
    }

    View viewForPlace(String placeId) throws JSONException {
        String[] placeIdSplit = placeId.split("/");
        String viewId = "seat" + placeIdSplit[placeIdSplit.length - 1];
        int resId = getResources().getIdentifier(viewId, "id", getActivity().getPackageName());
        View v = mainView.findViewById(resId);
        if (v != null && placeMap.containsKey(v)) {
            // If v is already in placeMap, check its Place and make sure the placeId matches.
            if (placeMap.get(v).id().equals(placeId)) {
                return v;
            } else {
                return null;
            }
        } else {
            return v;
        }
    }

    // TODO: somehow distinguish between someone else's reservation and your own.
    int colorForPlaceStatus(Place.Status s) {
        switch (s) {
            case AVAILABLE:
                return Color.GREEN;
            case UNAVAILABLE:
                return Color.RED;
            case REQUESTED:
                return Color.YELLOW;
            case RESERVED:
                return Color.RED;
            default:
                return Color.WHITE;
        }
    }

    void refreshViewForPlace(Place p) throws JSONException {
        // http://stackoverflow.com/questions/5940825/android-change-shape-color-in-runtime
        GradientDrawable shape = (GradientDrawable) viewForPlace(p).getBackground().mutate();
        shape.setColor(colorForPlaceStatus(p.status));
        shape.invalidateSelf();
    }

    // ASSUMPTION: all clickable views are mapped to a place already.
    public void onClick(View v) {
        Place p = placeMap.get(v);
        // For now, can only request if place is currently available
        if (p != null && p.status == Place.Status.AVAILABLE) {
            try {
                //fragment has access to same context that activity is running in
                //Context has access to global SharedPreferences
                SharedPreferences prefs = getActivity().getSharedPreferences(MyActivity.class.getSimpleName(),
                        Context.MODE_PRIVATE);
                String registrationId = prefs.getString(MyActivity.PROPERTY_REG_ID,"");
                if (registrationId.isEmpty()) {
                    Toast.makeText(getActivity(), "No registration id!", Toast.LENGTH_SHORT).show();
                } else {
                    p.request(registrationId);
                    Toast.makeText(getActivity(), "Place requested!", Toast.LENGTH_SHORT).show();
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        } else {
            Log.d(TAG, "place status? " + (p == null ? "null" : p.status));
            Toast.makeText(getActivity(), "Place is not available.", Toast.LENGTH_SHORT).show();
        }
    }

}
