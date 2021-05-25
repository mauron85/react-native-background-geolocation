package com.marianhello.bgloc.data;

import java.util.Collection;

public interface LocationDAO {
    Collection<BackgroundLocation> getAllLocations();
    Collection<BackgroundLocation> getValidLocations();
    BackgroundLocation getLocationById(long id);
    BackgroundLocation getFirstUnpostedLocation();
    BackgroundLocation getNextUnpostedLocation(long fromId);
    long getUnpostedLocationsCount();
    long getLocationsForSyncCount(long millisSinceLastBatch);
    long persistLocation(BackgroundLocation location);
    long persistLocation(BackgroundLocation location, int maxRows);
    long persistLocationForSync(BackgroundLocation location, int maxRows);
    void updateLocationForSync(long locationId);
    void deleteLocationById(long locationId);
    BackgroundLocation deleteFirstUnpostedLocation();
    int deleteAllLocations();
    int deleteUnpostedLocations();
}
