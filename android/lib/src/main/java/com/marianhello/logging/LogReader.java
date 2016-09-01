package com.marianhello.logging;

import java.util.Collection;

/**
 * Created by finch on 01/08/16.
 */
public interface LogReader {
    Collection<LogEntry> getEntries(Integer limit);
}
