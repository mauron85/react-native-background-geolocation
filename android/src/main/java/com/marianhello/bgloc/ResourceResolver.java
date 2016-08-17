package com.marianhello.bgloc;

import android.app.Application;

/**
 * Created by finch on 19/07/16.
 */
public class ResourceResolver {

    private Application app;

    private ResourceResolver(Application app) {
        this.app = app;
    }

    public int getAppResource(String name, String type) {
        return app.getResources().getIdentifier(name, type, app.getPackageName());
    }

    public Integer getDrawableResource(String resourceName) {
        return getAppResource(resourceName, "drawable");
    }

    public String getStringResource(String name) {
        return app.getString(getAppResource(name, "string"));
    }

    public static ResourceResolver newInstance(Application app) {
        return new ResourceResolver(app);
    }
}
