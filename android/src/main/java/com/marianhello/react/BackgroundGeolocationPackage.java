package com.marianhello.react;

import android.app.Activity;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.views.view.ReactViewManager;
import com.facebook.react.uimanager.ViewManager;

public class BackgroundGeolocationPackage implements ReactPackage {

  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    List<NativeModule> modules = new ArrayList<NativeModule>();
    modules.add(new BackgroundGeolocationModule(reactContext));
    return modules;
  }

  @Override
  public List<Class<? extends JavaScriptModule>> createJSModules() {
      return Collections.emptyList();
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
      return Collections.emptyList();
  }
}
