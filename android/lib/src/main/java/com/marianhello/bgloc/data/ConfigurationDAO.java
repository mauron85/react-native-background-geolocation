package com.marianhello.bgloc.data;

import java.util.Date;
import java.util.Collection;

import org.json.JSONException;

import com.marianhello.bgloc.Config;

public interface ConfigurationDAO {
    boolean persistConfiguration(Config config) throws NullPointerException;
    Config retrieveConfiguration() throws JSONException;
}
