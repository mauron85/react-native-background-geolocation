/*
 * Copyright 2011-2015 Ziminji
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

/*!
 @category			NSString (ZIMString)
 @discussion		This category extends the functionality of the NSString class.
 @updated			2011-07-16
 */
@interface NSString (ZIMString)
/*!
 @method			matchesRegex:options:
 @discussion		This method determines whether the pattern is matched.
 @param pattern		The regular expression to be used.
 @param options		The options to be used.
 @return			A boolean value denoting whether the pattern was matched.
 @updated			2012-03-20
 @see				http://developer.apple.com/library/ios/#documentation/Foundation/Reference/NSRegularExpression_Class/Reference/Reference.html
 @see				http://quickies.seriot.ch/index.php?id=279
 */
- (BOOL) matchesRegex: (NSString *)pattern options: (NSRegularExpressionOptions)options;
/*!
 @method			capitalizeFirstCharacterInString:
 @discussion		This method will capitalize the first letter in the specified string.
 @param string		The string to be modified.
 @return			The modified string.
 @updated			2011-06-29
 @see				http://stackoverflow.com/questions/883897/easy-way-to-set-a-single-character-of-an-nsstring-to-uppercase
 */
+ (NSString *) capitalizeFirstCharacterInString: (NSString *)string;
/*!
 @method			firstTokenInString:scanUpToCharactersFromSet:
 @discussion		This method returns the first token found in the specified string.
 @param string		The string to be parsed.
 @param stopSet		The set of characters up to which to scan.
 @return			The first token found.
 @updated			2011-06-29
 */
+ (NSString *) firstTokenInString: (NSString *)string scanUpToCharactersFromSet: (NSCharacterSet *)stopSet;

@end
