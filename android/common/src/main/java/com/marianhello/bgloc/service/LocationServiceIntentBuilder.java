/*
 * Copyright 2017 R3BL LLC.
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more contributor
 * license agreements. See the NOTICE file distributed with this work for additional
 * information regarding copyright ownership. The ASF licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

package com.marianhello.bgloc.service;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Parcelable;
import android.support.annotation.IntDef;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

// CommandId enumeration
// more info - http://blog.shamanland.com/2016/02/int-string-enum.html
@IntDef({
        CommandId.INVALID,
        CommandId.START,
        CommandId.START_FOREGROUND_SERVICE,
        CommandId.STOP,
        CommandId.STOP_FOREGROUND,
        CommandId.START_FOREGROUND,
        CommandId.CONFIGURE,
        CommandId.REGISTER_HEADLESS_TASK,
        CommandId.START_HEADLESS_TASK,
        CommandId.STOP_HEADLESS_TASK
})
@Retention(RetentionPolicy.SOURCE)
@interface CommandId {
    int INVALID = -1;
    int START = 0;
    int START_FOREGROUND_SERVICE = 1;
    int STOP = 2;
    int STOP_FOREGROUND = 3;
    int START_FOREGROUND = 4;
    int CONFIGURE = 5;
    int REGISTER_HEADLESS_TASK = 6;
    int START_HEADLESS_TASK = 7;
    int STOP_HEADLESS_TASK = 8;
}

public class LocationServiceIntentBuilder {

    private static final String KEY_MESSAGE = "msg";
    private static final String KEY_COMMAND = "cmd";

    private Context mContext;
    private String mMessage;
    private Command mCommand;

    public static class Command {
        private static final String KEY_COMMAND_ID = "cmd_id";
        private static final String KEY_COMMAND_ARGUMENT = "cmd_arg";
        private static final String KEY_COMMAND_ARGUMENT_TYPE = "cmd_arg_type";
        private static final int ARGUMENT_TYPE_MISSING = 0;
        private static final int ARGUMENT_TYPE_STRING = 1;
        private static final int ARGUMENT_TYPE_PARCELABLE = 2;

        private final @CommandId int mCommandId;
        private Parcelable mParcelableArg;
        private String mStringArg;
        private int mArgType = 0;

        public Command(int id) {
            this.mCommandId = id;
        }

        public Command(int id, String argument) {
            mCommandId = id;
            mStringArg = argument;
            mArgType = ARGUMENT_TYPE_STRING;
        }

        public Command(int id, Parcelable argument) {
            mCommandId = id;
            mParcelableArg = argument;
            mArgType = ARGUMENT_TYPE_PARCELABLE;
        }

        public int getId() {
            return mCommandId;
        }

        public Object getArgument() {
            switch (mArgType) {
                case ARGUMENT_TYPE_STRING:
                    return mStringArg;
                case ARGUMENT_TYPE_PARCELABLE:
                    return mParcelableArg;
                default:
                    return null;
            }
        }

        public Bundle toBundle() {
            Bundle bundle = new Bundle();
            bundle.putInt(KEY_COMMAND_ID, mCommandId);

            if (mStringArg != null) {
                bundle.putInt(KEY_COMMAND_ARGUMENT_TYPE, ARGUMENT_TYPE_STRING);
                bundle.putString(KEY_COMMAND_ARGUMENT, mStringArg);
            } else if (mParcelableArg != null) {
                bundle.putInt(KEY_COMMAND_ARGUMENT_TYPE, ARGUMENT_TYPE_PARCELABLE);
                bundle.putParcelable(KEY_COMMAND_ARGUMENT, mParcelableArg);
            } else {
                bundle.putInt(KEY_COMMAND_ARGUMENT_TYPE, ARGUMENT_TYPE_MISSING);
            }

            return bundle;
        }

        public static Command from(Bundle bundle) {
            @CommandId int commandId =  bundle.getInt(KEY_COMMAND_ID);
            int argumentType = bundle.getInt(KEY_COMMAND_ARGUMENT_TYPE);

            if (argumentType == ARGUMENT_TYPE_STRING) {
                return new Command(commandId, bundle.getString(KEY_COMMAND_ARGUMENT));
            } else if (argumentType == ARGUMENT_TYPE_PARCELABLE) {
                // Important: don't remove Parcelable cast
                // required for Java 1.8 compatibility
                return new Command(commandId, (Parcelable) bundle.getParcelable(KEY_COMMAND_ARGUMENT));
            }

            return new Command(commandId);
        }
    }

    public static LocationServiceIntentBuilder getInstance(Context context) {
        return new LocationServiceIntentBuilder(context);
    }

    public LocationServiceIntentBuilder(Context context) {
        mContext = context;
    }

    public LocationServiceIntentBuilder setMessage(String message) {
        mMessage = message;
        return this;
    }

    /**
     * @param commandId Don't use {@link CommandId#INVALID} as a param. If you do then this method does
     *     nothing.
     */
    public LocationServiceIntentBuilder setCommand(@CommandId int commandId) {
        mCommand = new Command(commandId);
        return this;
    }

    public LocationServiceIntentBuilder setCommand(@CommandId int commandId, String arg) {
        mCommand = new Command(commandId, arg);
        return this;
    }

    public LocationServiceIntentBuilder setCommand(@CommandId int commandId, Parcelable arg) {
        mCommand = new Command(commandId, arg);
        return this;
    }

    public Intent build() {
        assert mContext != null : "Context can not be null!";
        Intent intent = new Intent(mContext, LocationServiceImpl.class);
        if (mCommand != null) {
            intent.putExtra(KEY_COMMAND, mCommand.toBundle());
        }
        if (mMessage != null) {
            intent.putExtra(KEY_MESSAGE, mMessage);
        }
        return intent;
    }

    public static boolean containsCommand(Intent intent) {
        return intent.hasExtra(KEY_COMMAND);
    }

    public static boolean containsMessage(Intent intent) {
        return intent.hasExtra(KEY_MESSAGE);
    }

    public static Command getCommand(Intent intent) {
        Bundle bundle = intent.getBundleExtra(KEY_COMMAND);
        return Command.from(bundle);
    }

    public static String getMessage(Intent intent) {
        return intent.getStringExtra(KEY_MESSAGE);
    }
} //end class LocationServiceIntentBuilder
