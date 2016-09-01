package com.marianhello.bgloc.data;

import java.util.Collection;

public interface LocationDAO {
    public Collection<BackgroundLocation> getAllLocations();
    public Collection<BackgroundLocation> getValidLocations();
    public Long locationsForSyncCount(Long millisSinceLastBatch);
    public Long persistLocation(BackgroundLocation location);
    public Long persistLocationWithLimit(BackgroundLocation location, Integer maxRows);
    public void deleteLocation(Long locationId);
    public void deleteAllLocations();
}
