package com.marianhello.bgloc;

import android.content.Context;

/**
 * Created by finch on 19/07/16.
 */
public class ResourceResolver {

    private static final String RESOURCE_PREFIX = "mauron85_bgloc_";
    private static final String ACCOUNT_NAME_RESOURCE = RESOURCE_PREFIX + "account_name";
    private static final String ACCOUNT_TYPE_RESOURCE = RESOURCE_PREFIX + "account_type";
    private static final String AUTHORITY_TYPE_RESOURCE = RESOURCE_PREFIX + "content_authority";

    private Context mContext;

    protected ResourceResolver() {}

    private ResourceResolver(Context context) {
        mContext = context;
    }

    private Context getApplicationContext() {
        return mContext.getApplicationContext();
    }

    public int getAppResource(String name, String type) {
        Context appContext = getApplicationContext();
        return appContext.getResources().getIdentifier(name, type, appContext.getPackageName());
    }

    public Integer getDrawable(String resourceName) {
        return getAppResource(resourceName, "drawable");
    }

    public String getString(String name) {
        return getApplicationContext().getString(getAppResource(name, "string"));
    }

    public String getAccountName() {
        return getString(ACCOUNT_NAME_RESOURCE);
    }

    public String getAccountType() {
        return getString(ACCOUNT_TYPE_RESOURCE);
    }

    public String getAuthority() {
        return getString(AUTHORITY_TYPE_RESOURCE);
    }

    public static ResourceResolver newInstance(Context context) {
        return new ResourceResolver(context);
    }
}
