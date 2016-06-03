/*
 * Kindly taken from
 * http://stackoverflow.com/questions/1590831/safely-casting-long-to-int-in-java
 */

package com.marianhello.utils;

public class Convert {

  public static Integer safeLongToInt(Long l) {
    if (l == null) return null;
    return l.intValue();
  }
}
