#!/usr/bin/env bash

git submodule init
git submodule update

cp -r android/common/src/main/java/* android/lib/src/main/java/