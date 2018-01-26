package com.marianhello.bgloc.data;

import java.util.Collection;

public interface LocationDAO {
    Collection<BackgroundLocation> getAllLocations();
    Collection<BackgroundLocation> getValidLocations();
    Long locationsForSyncCount(Long millisSinceLastBatch);
    Long persistLocation(BackgroundLocation location);
    Long persistLocationWithLimit(BackgroundLocation location, Integer maxRows);
    void deleteLocation(Long locationId);
    void deleteAllLocations();
}
