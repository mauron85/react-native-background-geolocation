#!/usr/bin/env bash

git submodule init
git submodule update

cp -r android/common/src/main/* android/lib/src/main/
