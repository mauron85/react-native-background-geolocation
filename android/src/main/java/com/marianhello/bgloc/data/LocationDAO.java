package com.marianhello.bgloc.data;

import java.util.Collection;

public interface LocationDAO {
    public Collection<BackgroundLocation> getAllLocations();
    public Long persistLocation(BackgroundLocation l);
    public void deleteLocation(Long locationId);
    public void deleteAllLocations();
}
