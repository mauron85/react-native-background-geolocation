# Run tests

# Unit

Notice: currently not possible - [read explanation](lib/src/test/java/com/marianhello/bgloc/react/ConfigMapperTest.java)

```
ndkDir=$(pwd)/react-ndk/all/x86_64 \
  JAVA_OPTS="-Djava.library.path=\".:$ndkDir\"" \
  LD_LIBRARY_PATH="$ndkDir:$LD_LIBRARY_PATH" ./gradlew lib:test
```

# Instrumented

Test, that run on android device can be run from Android Studio.
