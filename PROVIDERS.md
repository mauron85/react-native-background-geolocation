# Location providers

## Which provider should I use?

### DISTANCE_FILTER_PROVIDER

This is classic provider, originally from cristocracy. It's best to use this one as background location provider. It is using Stationary API and elastic distance filter to achieve optimal battery and data usage. You can read more about this provider in [DISTANCE_FILTER_PROVIDER.md](/DISTANCE_FILTER_PROVIDER.md).

### ACTIVITY_PROVIDER (Android only)

This one is best to use as foreground location provider (but works in background as well). It uses Android FusedLocationProviderApi and ActivityRecognitionApi for maximum battery saving. This provider is alternative to w3c ```window.navigator.watchPosition```, but you're in control how often should updates be polled from GPS. Slower updates means lower battery consumption. You can adjust position update interval by settings options ```interval``` and ```fastestInterval```. Option ```fastestInterval``` is used, when there are other apps asking for positions. In that case your app can be updated more often and ```fastestInterval``` is the upper limit of how fast can your app process location updates. Option ```activitiesInterval``` specifies how often activity recognition occurs. Larger values will result in fewer activity detections while improving battery life. Smaller values will result in more frequent activity detections but will consume more power since the device must be woken up more frequently

### RAW_PROVIDER

This provider doesn't do any location processing, but rather returns locations as recorded by device sensors.
