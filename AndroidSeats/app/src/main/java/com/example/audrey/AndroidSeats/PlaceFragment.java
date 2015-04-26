package com.example.audrey.AndroidSeats;

import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.support.v4.app.Fragment;
import android.view.View;
import android.widget.Toast;

import org.json.JSONException;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by alvin on 4/25/2015.
 */
public abstract class PlaceFragment extends Fragment implements View.OnClickListener {
    Map<View, Place> placeMap = new HashMap<View, Place>();
    View mainView;

    View viewForPlace(Place p) throws JSONException {
        String[] placeIdSplit = p.id().split("/");
        String viewId = "seat" + placeIdSplit[placeIdSplit.length - 1];
        int resId = getResources().getIdentifier(viewId, "id", getActivity().getPackageName());
        return mainView.findViewById(resId);
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
                p.request();
            } catch (JSONException e) {
                e.printStackTrace();
            }
        } else {
            Toast.makeText(getActivity(), "Place is not available.", Toast.LENGTH_SHORT).show();
        }
    }

}
