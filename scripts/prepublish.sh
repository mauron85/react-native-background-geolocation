#!/usr/bin/env bash

git submodule init
git submodule update

mkdir -p android/lib/src/main/res/
cp -r android/common/src/main/java/* android/lib/src/main/java/
cp -r android/common/src/main/res/* android/lib/src/main/res/
