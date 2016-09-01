package com.marianhello.bgloc.sync;

import android.accounts.Account;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class AuthenticatorService extends Service {
    public static final String ACCOUNT_NAME = "dummy";

    private Authenticator mAuthenticator;

    public AuthenticatorService() {
    }

    @Override
    public void onCreate() {
        // Create a new authenticator object
        mAuthenticator = new Authenticator(this);
    }

    /*
     * When the system binds to this Service to make the RPC call
     * return the authenticator's IBinder.
     */
    @Override
    public IBinder onBind(Intent intent) {
        return mAuthenticator.getIBinder();
    }


    public static Account getAccount(String accountType) {
        return new Account(ACCOUNT_NAME, accountType);
    }
}
