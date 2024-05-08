/// <reference path="node_modules/react-native-mauron85-background-geolocation/index.d.ts" />

// Type definitions for react-native-mauron85-background-geolocation
// Project: https://github.com/mauron85/react-native-background-geolocation
// Definitions by: Mauron85 (@mauron85)
// Definitions: https://github.com/mauron85/react-native-background-geolocation/blob/master/index.d.ts

namespace BackgroundGeolocationPlugin {
export interface LocationZ {
    speed: number
}

    /**
     * One time location check to get current location of the device.
     *
     * Error codes:
     *  1. PERMISSION_DENIED
     *  2. LOCATION_UNAVAILABLE
     *  3. TIMEOUT
     *
     * @param success
     * @param fail
     * @param options
     */
    export function getCurrentLocationAsync(
        options?: PositionOptions
    ): Promise<Location>;
}

export { BackgroundGeolocationPlugin as BackgroundGeolocation }