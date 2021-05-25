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

#import <sqlite3.h> // Requires libsqlite3.dylib
#import "NSString+ZIMString.h"
#import "ZIMSqlExpression.h"
#import "ZIMSqlSelectStatement.h"

NSString *ZIMSqlDefaultValue(id value) {
	if ((value == nil) || [value isKindOfClass: [NSNull class]]) {
		return @"DEFAULT NULL";
	}
	else if ([value isKindOfClass: [NSNumber class]]) {
		return [NSString stringWithFormat: @"DEFAULT %@", value];
	}
	else if ([value isKindOfClass: [NSString class]]) {
		char *escapedValue = sqlite3_mprintf("DEFAULT '%q'", [(NSString *)value UTF8String]);
		NSString *string = [NSString stringWithUTF8String: (const char *)escapedValue];
		sqlite3_free(escapedValue);
		return string;
	}
	else if ([value isKindOfClass: [NSData class]]) {
		NSData *data = (NSData *)value;
		NSInteger length = [data length];
		NSMutableString *buffer = [[NSMutableString alloc] init];
		[buffer appendString: @"DEFAULT x'"];
		const unsigned char *dataBuffer = [data bytes];
		for (NSInteger i = 0; i < length; i++) {
			[buffer appendFormat: @"%02lx", (unsigned long)dataBuffer[i]];
		}
		[buffer appendString: @"'"];
		return buffer;
	}
	else if ([value isKindOfClass: [NSDate class]]) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
		NSString *date = [NSString stringWithFormat: @"DEFAULT '%@'", [formatter stringFromDate: (NSDate *)value]];
		return date;
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: [NSString stringWithFormat: @"Unable to set default value. '%@'", value] userInfo: nil];
	}
}

NSString *ZIMSqlDataTypeChar(NSUInteger x) {
	return [NSString stringWithFormat: @"CHAR(%lu)", (unsigned long)x];
}

NSString *ZIMSqlDataTypeCharacter(NSUInteger x) {
	return [NSString stringWithFormat: @"CHARACTER(%lu)", (unsigned long)x];
}

NSString *ZIMSqlDataTypeDecimal(NSUInteger x, NSUInteger y) {
	return [NSString stringWithFormat: @"DECIMAL(%lu, %lu)", (unsigned long)x, (unsigned long)y];
}

NSString *ZIMSqlDataTypeNativeCharacter(NSUInteger x) {
	return [NSString stringWithFormat: @"NATIVE CHARACTER(%lu)", (unsigned long)x];
}

NSString *ZIMSqlDataTypeNChar(NSUInteger x) {
	return [NSString stringWithFormat: @"NCHAR(%lu)", (unsigned long)x];
}

NSString *ZIMSqlDataTypeNVarChar(NSUInteger x) {
	return [NSString stringWithFormat: @"NVARCHAR(%lu)", (unsigned long)x];
}

NSString *ZIMSqlDataTypeVarChar(NSUInteger x) {
	return [NSString stringWithFormat: @"VARCHAR(%lu)", (unsigned long)x];
}

NSString *ZIMSqlDataTypeVaryingCharacter(NSUInteger x) {
	return [NSString stringWithFormat: @"VARYING CHARACTER(%lu)", (unsigned long)x];
}

@implementation ZIMSqlExpression

#pragma mark -
#pragma mark Public Methods

- (instancetype) initWithSqlExpression: (NSString *)sql {
	if ((self = [super init])) {
		_expression = sql;
	}
	return self;
}

- (NSString *) expression {
	return _expression;
}

+ (ZIMSqlExpression *) sql: (NSString *)sql {
	return [[ZIMSqlExpression alloc] initWithSqlExpression: sql];
}

+ (NSString *) prepareAlias: (NSString *)token {
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"[^a-z0-9_ ]" options: NSRegularExpressionCaseInsensitive error: &error];
	token = [regex stringByReplacingMatchesInString: token options: 0 range: NSMakeRange(0, [token length]) withTemplate: @""];
	token = [token stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	token = [NSString stringWithFormat: @"[%@]", token];
	return token;
}

+ (NSString *) prepareConnector: (NSString *)token {
	if (![token matchesRegex: @"^(and|or)$" options: NSRegularExpressionCaseInsensitive]) {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Invalid connector token provided." userInfo: nil];
	}
	return [token uppercaseString];
}

+ (NSString *) prepareEnclosure: (NSString *)token {
	if (!([token isEqualToString: ZIMSqlEnclosureOpeningBrace] || [token isEqualToString: ZIMSqlEnclosureClosingBrace])) {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Invalid enclosure token provided." userInfo: nil];
	}
	return token;
}

+ (NSString *) prepareIdentifier: (id)identifier {
	if ([identifier isKindOfClass: [NSString class]]) {
		NSMutableString *buffer = [[NSMutableString alloc] init];
		NSArray *tokens = [(NSString *)identifier componentsSeparatedByString: @"."];
		NSInteger length = [tokens count];
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"[^a-z0-9_ ]" options: NSRegularExpressionCaseInsensitive error: &error];
		for (NSInteger index = 0; index < length; index++) {
			if (index > 0) {
				[buffer appendString: @"."];
			}
			NSString *token = (NSString *)[tokens objectAtIndex: index];
			if ([token matchesRegex: @"^\\s*\\*\\s*$" options: NSRegularExpressionCaseInsensitive]) {
				[buffer appendString: @"*"];
			}
			else {
				token = [regex stringByReplacingMatchesInString: token options: 0 range: NSMakeRange(0, [token length]) withTemplate: @""];
				token = [token stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				[buffer appendFormat: @"[%@]", token];
			}
		}
		return buffer;
	}
	else if ([identifier isKindOfClass: [ZIMSqlExpression class]]) {
		return [(ZIMSqlExpression *)identifier expression];
	}
	else if ([identifier isKindOfClass: [ZIMSqlSelectStatement class]]) {
		NSString *statement = [(ZIMSqlSelectStatement *)identifier statement];
		statement = [statement substringWithRange: NSMakeRange(0, [statement length] - 1)];
		statement = [NSString stringWithFormat: @"(%@)", statement];
		return statement;
	}
	@throw [NSException exceptionWithName: @"ZIMSqlException" reason: [NSString stringWithFormat: @"Unable to prepare identifier. '%@'", identifier] userInfo: nil];
}

+ (NSString *) prepareJoinType: (NSString *)token {
	if ((token == nil) || [token isEqualToString: ZIMSqlJoinTypeNone]) {
		token = ZIMSqlJoinTypeInner;
	}
	else if ([token isEqualToString: @","]) {
		token = ZIMSqlJoinTypeCross;
	}
	if (![token matchesRegex: @"^((natural )?(cross|inner|(left( outer)?)))|(natural)$" options: NSRegularExpressionCaseInsensitive]) {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Invalid join type token provided." userInfo: nil];
	}
	return [token uppercaseString];
}

+ (NSString *) prepareOperator: (NSString *)operator ofType: (NSString *)type {
	if ([[type uppercaseString] isEqualToString: @"SET"] && ![operator matchesRegex: @"^(except|intersect|(union( all)?))$" options: NSRegularExpressionCaseInsensitive]) {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Invalid set operator token provided." userInfo: nil];
	}
	return [operator uppercaseString];
}

+ (NSString *) prepareSortOrder: (BOOL)descending {
	return (descending) ? @"DESC" : @"ASC";
}

+ (NSString *) prepareSortWeight: (NSString *)weight {
	if (weight != nil) {
		if (![weight matchesRegex: @"^(first|last)$" options: NSRegularExpressionCaseInsensitive]) {
			@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Invalid weight token provided." userInfo: nil];
		}
		return [weight uppercaseString];
	}
	return @"DEFAULT";
}

+ (NSString *) prepareValue: (id)value {
	if ((value == nil) || [value isKindOfClass: [NSNull class]]) {
		return @"NULL";
	}
	else if ([value isKindOfClass: [NSArray class]]) {
		NSMutableString *buffer = [[NSMutableString alloc] init];
		[buffer appendString: @"("];
		for (NSInteger i = 0; i < [value count]; i++) {
			if (i > 0) {
				[buffer appendString: @", "];
			}
			[buffer appendString: [self prepareValue: [value objectAtIndex: i]]];
		}
		[buffer appendString: @")"];
		return buffer;
	}
	else if ([value isKindOfClass: [NSNumber class]]) {
		return [NSString stringWithFormat: @"%@", value];
	}
	else if ([value isKindOfClass: [NSString class]]) {
		char *escapedValue = sqlite3_mprintf("'%q'", [(NSString *)value UTF8String]);
		NSString *string = [NSString stringWithUTF8String: (const char *)escapedValue];
		sqlite3_free(escapedValue);
		return string;
	}
	else if ([value isKindOfClass: [NSData class]]) {
		NSData *data = (NSData *)value;
		NSInteger length = [data length];
		NSMutableString *buffer = [[NSMutableString alloc] init];
		[buffer appendString: @"x'"];
		const unsigned char *dataBuffer = [data bytes];
		for (NSInteger i = 0; i < length; i++) {
			[buffer appendFormat: @"%02lx", (unsigned long)dataBuffer[i]];
		}
		[buffer appendString: @"'"];
		return buffer;
	}
	else if ([value isKindOfClass: [NSDate class]]) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
		NSString *date = [NSString stringWithFormat: @"'%@'", [formatter stringFromDate: (NSDate *)value]];
		return date;
	}
	else if ([value isKindOfClass: [ZIMSqlExpression class]]) {
		return [(ZIMSqlExpression *)value expression];
	}
	else if ([value isKindOfClass: [ZIMSqlSelectStatement class]]) {
		NSString *statement = [(ZIMSqlSelectStatement *)value statement];
		statement = [statement substringWithRange: NSMakeRange(0, [statement length] - 1)];
		statement = [NSString stringWithFormat: @"(%@)", statement];
		return statement;
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: [NSString stringWithFormat: @"Unable to prepare value. '%@'", value] userInfo: nil];
	}
}

@end
