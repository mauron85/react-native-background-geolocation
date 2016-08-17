package com.marianhello.logging;

import org.apache.commons.io.input.ReversedLinesFileReader;

import java.io.File;
import java.nio.charset.Charset;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Comparator;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.core.CoreConstants;

/**
 * Created by finch on 01/08/16.
 */
public class FileLogReader implements LogReader {

    private static final SimpleDateFormat ISO8601Format =  new SimpleDateFormat("yyyy-MM-dd HH:mm:ss,S");
    private static final SimpleDateFormat LogFileDateFormat = new SimpleDateFormat("yyyy-MM-dd");

    @Override
    public Collection<LogEntry> getEntries(Integer limit) {
        Collection<LogEntry> entries = new ArrayList<LogEntry>();

        int lineNumber = 0;
        Iterator<File> it = getLogFiles().iterator();
        while (lineNumber <= limit && it.hasNext()) {
            try {
                String line;
                ReversedLinesFileReader fr = new ReversedLinesFileReader(it.next(), 4096, Charset.forName("UTF-8"));

                while ((lineNumber++ < limit && (line = fr.readLine()) != null)) {
                    entries.add(parseLine(line));
                }

                fr.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        return entries;
    }

    private List<File> getLogFiles() {
        LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();
        final Pattern pattern = Pattern.compile("plugin\\.(.+)\\.log");
        File logDir = new File(context.getProperty(CoreConstants.DATA_DIR_KEY) + File.separator + LoggerManager.LOG_DIR);

        File logFiles[] = logDir.listFiles();
        Arrays.sort(logFiles, new Comparator<File>() {
            @Override
            public int compare(File f1, File f2) {
                Date d1 = new Date();
                Date d2 = d1;

                Matcher matcher1 = pattern.matcher(f1.getName());
                Matcher matcher2 = pattern.matcher(f2.getName());

                try {
                    if (matcher1.find()) d1 = LogFileDateFormat.parse(matcher1.group(1));
                    if (matcher2.find()) d2 = LogFileDateFormat.parse(matcher2.group(1));
                } catch (ParseException e) {
                    e.printStackTrace();
                }

                return -d1.compareTo(d2);
            }
        });

        return Arrays.asList(logFiles);
    }

    private LogEntry parseLine(String line) throws ParseException {
        String parts[] = line.split("\\s+", 5);
        LogEntry entry = new LogEntry();
        entry.setContext(0);
        entry.setTimestamp(ISO8601Format.parse(parts[0] + " " + parts[1]).getTime());
        entry.setLevel(parts[2]);
        entry.setLoggerName(parts[3]);
        entry.setMessage(parts[4].substring(2));

        return entry;
    }
}
