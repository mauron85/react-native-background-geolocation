#!/usr/bin/env bash

mkdir -p android/lib/src/main/res/

git submodule init && git submodule update && cp -r android/common/src/main/java/* android/lib/src/main/java/ && cp -r android/common/src/main/res/* android/lib/src/main/res/
