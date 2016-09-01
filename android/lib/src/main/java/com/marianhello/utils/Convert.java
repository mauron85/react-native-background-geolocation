/*
 * Kindly taken from
 * http://stackoverflow.com/questions/1590831/safely-casting-long-to-int-in-java
 */

package com.marianhello.utils;

public class Convert {

  public static int safeLongToInt(long l) {
    if (l < Integer.MIN_VALUE || l > Integer.MAX_VALUE) {
      throw new IllegalArgumentException
        (l + " cannot be cast to int without changing its value.");
    }
    return (int) l;
  }
}
