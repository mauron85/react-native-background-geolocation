package com.marianhello.bgloc.headless;

/**
 * Interface for passing code that will be executed after the JS has finished
 */

public interface JsCallback {
	void onResult(String value);
	void onError(String errorMessage);
}
