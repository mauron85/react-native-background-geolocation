package com.marianhello.bgloc.test;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ProviderInfo;
import android.content.res.Resources;
import android.test.AndroidTestCase;
import android.test.IsolatedContext;
import android.test.RenamingDelegatingContext;
import android.test.mock.MockContentResolver;
import android.test.mock.MockContext;

import com.marianhello.bgloc.data.provider.LocationContentProvider;
import com.marianhello.bgloc.test.TestConstants;

/**
 * @author diego
 * https://stackoverflow.com/a/5281044
 *
 */
public class LocationProviderTestCase extends AndroidTestCase {
    Class<LocationContentProvider> mProviderClass;
    String mProviderAuthority;

    private IsolatedContext mProviderContext;
    private LocationContentProvider mProvider;
    private MockContentResolver mResolver;

    /**
     * The renaming prefix.
     */
    private static final String filenamePrefix = "test.";

    public LocationProviderTestCase() {
        mProviderClass = LocationContentProvider.class;
        mProviderAuthority = TestConstants.Authority;
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();

        mResolver = new MockContentResolver();
        RenamingDelegatingContext targetContextWrapper = new RenamingDelegatingContext(
                new DelegatedMockContext(getContext()), // The context that most methods are delegated to
                getContext(), // The context that file methods are delegated to
                filenamePrefix);
        mProviderContext = new IsolatedContext(mResolver, targetContextWrapper);

        ProviderInfo providerInfo = new ProviderInfo();
        providerInfo.authority = mProviderAuthority;

        mProvider = mProviderClass.newInstance();
        mProvider.attachInfo(mProviderContext, providerInfo);
        assertNotNull(mProvider);
        mResolver.addProvider(mProviderAuthority, mProvider);
    }

    public LocationContentProvider getProvider() {
        return mProvider;
    }

    public MockContentResolver getMockContentResolver() {
        return mResolver;
    }

    public IsolatedContext getMockContext() {
        return mProviderContext;
    }

    public void testProviderSampleCreation() {
        LocationContentProvider provider = getProvider();
        assertNotNull(provider);
    }

    /**
     * The DelegatedMockContext.
     *
     */
    private static class DelegatedMockContext extends MockContext {

        private Context mDelegatedContext;

        public DelegatedMockContext(Context context) {
            mDelegatedContext = context;
        }

        @Override
        public SharedPreferences getSharedPreferences(String name, int mode) {
            return mDelegatedContext.getSharedPreferences(filenamePrefix + name, mode);
        }

        @Override
        public Context getApplicationContext() {
            return mDelegatedContext.getApplicationContext();
        }

        @Override
        public Resources getResources() {
            return mDelegatedContext.getResources();
        }

        @Override
        public String getPackageName() {
            return mDelegatedContext.getPackageName();
        }
    }}
