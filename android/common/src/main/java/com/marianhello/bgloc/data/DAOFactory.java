package com.marianhello.bgloc.data;

import android.content.Context;

import com.marianhello.bgloc.data.provider.ContentProviderLocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteConfigurationDAO;

public abstract class DAOFactory {
    public static LocationDAO createLocationDAO(Context context) {
        return new ContentProviderLocationDAO(context);
    }

    public static ConfigurationDAO createConfigurationDAO(Context context) {
        return new SQLiteConfigurationDAO(context);
    }
}
