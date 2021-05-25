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

// Block Statement Tokens
#define ZIMSqlEnclosureOpeningBrace				@"("
#define ZIMSqlEnclosureClosingBrace				@")"

// Connectors
#define ZIMSqlConnectorAnd						@"AND"
#define ZIMSqlConnectorOr						@"OR"

// Join Types -- http://sqlite.org/syntaxdiagrams.html#join-op
#define ZIMSqlJoinTypeCross						@"CROSS"
#define ZIMSqlJoinTypeInner						@"INNER"
#define ZIMSqlJoinTypeLeft						@"LEFT"
#define ZIMSqlJoinTypeLeftOuter					@"LEFT OUTER"
#define ZIMSqlJoinTypeNatural					@"NATURAL"
#define ZIMSqlJoinTypeNaturalCross				@"NATURAL CROSS"
#define ZIMSqlJoinTypeNaturalInner				@"NATURAL INNER"
#define ZIMSqlJoinTypeNaturalLeft				@"NATURAL LEFT"
#define ZIMSqlJoinTypeNaturalLeftOuter			@"NATURAL LEFT OUTER"
#define ZIMSqlJoinTypeNone						@""

// Expressions -- http://zetcode.com/databases/sqlitetutorial/expressions/
// Arithmetic Operators
#define ZIMSqlOperatorAdd						@"+"
#define ZIMSqlOperatorSubtract					@"-"
#define ZIMSqlOperatorMultiply					@"*"
#define ZIMSqlOperatorDivide					@"/"
#define ZIMSqlOperatorMod						@"%"

// Boolean Operators
#define ZIMSqlOperatorAnd						@"AND"
#define ZIMSqlOperatorOr						@"OR"
#define ZIMSqlOperatorNot						@"NOT"

// Relational Operators
#define ZIMSqlOperatorLessThan					@"<"
#define ZIMSqlOperatorLessThanOrEqualTo			@"<="
#define ZIMSqlOperatorGreaterThan				@">"
#define ZIMSqlOperatorGreaterThanOrEqualTo		@">="
#define ZIMSqlOperatorEqualTo					@"="
#define ZIMSqlOperatorNotEqualTo				@"<>"

// Bitwise Operators
#define ZIMSqlOperatorBitwiseAnd				@"&"
#define ZIMSqlOperatorBitwiseOr					@"|"
#define ZIMSqlOperatorBitwiseShiftLeft			@"<<"
#define ZIMSqlOperatorBitwiseShiftRight			@">>"
#define ZIMSqlOperatorBitwiseNegation			@"~"

// Additional Operators
#define ZIMSqlOperatorConcatenate				@"||"
#define ZIMSqlOperatorIn						@"IN"
#define ZIMSqlOperatorNotIn						@"NOT IN"
#define ZIMSqlOperatorIs						@"IS"
#define ZIMSqlOperatorIsNot						@"IS NOT"
#define ZIMSqlOperatorLike						@"LIKE"
#define ZIMSqlOperatorNotLike					@"NOT LIKE"
#define ZIMSqlOperatorGlob						@"GLOB"
#define ZIMSqlOperatorNotGlob					@"NOT GLOB"
#define ZIMSqlOperatorBetween					@"BETWEEN"
#define ZIMSqlOperatorNotBetween				@"NOT BETWEEN"

// Set Operators
#define ZIMSqlOperatorExcept					@"EXCEPT"
#define ZIMSqlOperatorIntersect					@"INTERSECT"
#define ZIMSqlOperatorUnion						@"UNION"
#define ZIMSqlOperatorUnionAll					@"UNION ALL"

// Show Types
#define ZIMSqlShowTypeAll						@"ALL"
#define ZIMSqlShowTypePermanent					@"PERMANENT"
#define ZIMSqlShowTypeTemporary					@"TEMPORARY"

// Order Operators (for Nulls)
#define ZIMSqlNullsFirst						@"FIRST"
#define ZIMSqlNullsLast							@"LAST"

// Default Values -- http://forums.realsoftware.com/viewtopic.php?f=3&t=35179
#define ZIMSqlDefaultValueIsAutoIncremented		@"PRIMARY KEY AUTOINCREMENT NOT NULL"
#define ZIMSqlDefaultValueIsNull				@"DEFAULT NULL"
#define ZIMSqlDefaultValueIsNotNull				@"NOT NULL"
#define ZIMSqlDefaultValueIsCurrentDate			@"DEFAULT CURRENT_DATE"
#define ZIMSqlDefaultValueIsCurrentDateTime		@"DEFAULT (datetime('now','localtime'))"
#define ZIMSqlDefaultValueIsCurrentTime			@"DEFAULT CURRENT_TIME"
#define ZIMSqlDefaultValueIsCurrentTimestamp	@"DEFAULT CURRENT_TIMESTAMP"
NSString *ZIMSqlDefaultValue(id value);

// Declared Datetype -- http://www.sqlite.org/datatype3.html
#define ZIMSqlDataTypeBigInt					@"BIGINT"
#define ZIMSqlDataTypeBlob						@"BLOB"
#define ZIMSqlDataTypeBoolean					@"BOOLEAN"
#define ZIMSqlDataTypeClob						@"CLOB"
#define ZIMSqlDataTypeDate						@"DATE"
#define ZIMSqlDataTypeDateTime					@"DATETIME"
#define ZIMSqlDataTypeDouble					@"DOUBLE"
#define ZIMSqlDataTypeDoublePrecision			@"DOUBLE PRECISION"
#define ZIMSqlDataTypeFloat						@"FLOAT"
#define ZIMSqlDataTypeInt						@"INT"
#define ZIMSqlDataTypeInt2						@"INT2"
#define ZIMSqlDataTypeInt8						@"INT8"
#define ZIMSqlDataTypeInteger					@"INTEGER"
#define ZIMSqlDataTypeMediumInt					@"MEDIUMINT"
#define ZIMSqlDataTypeNumeric					@"NUMERIC"
#define ZIMSqlDataTypeReal						@"REAL"
#define ZIMSqlDataTypeSmallInt					@"SMALLINT"
#define ZIMSqlDataTypeText						@"TEXT"
#define ZIMSqlDataTypeTimestamp					@"TIMESTAMP"
#define ZIMSqlDataTypeTinyInt					@"TINYINT"
#define ZIMSqlDataTypeUnsignedBigInt			@"UNSIGNED BIG INT"
#define ZIMSqlDataTypeVariant					@"VARIANT"
NSString *ZIMSqlDataTypeChar(NSUInteger x);
NSString *ZIMSqlDataTypeCharacter(NSUInteger x);
NSString *ZIMSqlDataTypeDecimal(NSUInteger x, NSUInteger y);
NSString *ZIMSqlDataTypeNativeCharacter(NSUInteger x);
NSString *ZIMSqlDataTypeNChar(NSUInteger x);
NSString *ZIMSqlDataTypeNVarChar(NSUInteger x);
NSString *ZIMSqlDataTypeVarChar(NSUInteger x);
NSString *ZIMSqlDataTypeVaryingCharacter(NSUInteger x);

/*!
 @class					ZIMSqlExpression
 @discussion			This class handles the formatting of an SQL expression.
 @updated				2012-04-04
 */
@interface ZIMSqlExpression : NSObject {

	@protected
		NSString *_expression;

}

/*!
 @method				initWithSqlExpression:
 @discussion			This method initialize the class with the specified SQL expression.
 @param sql				The SQL expression to be wrapped.
 @return				An instance of this class.
 @updated				2012-03-14
 */
- (instancetype) initWithSqlExpression: (NSString *)sql;
/*!
 @method				expression
 @discussion			This method returns the wrapped SQL expression.
 @return				The wrapped SQL expression.
 @updated				2012-03-14
 */
- (NSString *) expression;
/*!
 @method				sql:
 @discussion			This method will wrap the SQL expression.
 @param sql				The SQL expression to be wrapped
 @return				The wrapped SQL expression.
 @updated				2012-03-17
 */
+ (ZIMSqlExpression *) sql: (NSString *)sql;
/*!
 @method				prepareConnector:
 @discussion			This method will prepare an alias for an SQL statement.
 @param token			The token to be prepared.
 @return				The prepared token.
 @updated				2012-03-24
 */
+ (NSString *) prepareAlias: (NSString *)token;
/*!
 @method				prepareConnector:
 @discussion			This method will prepare a connector for an SQL statement.
 @param token			The token to be prepared.
 @return				The prepared token.
 @updated				2012-03-18
 */
+ (NSString *) prepareConnector: (NSString *)token;
/*!
 @method				prepareEnclosure:
 @discussion			This method will prepare an enclosure character for an SQL statement.
 @param token			The token to be prepared.
 @return				The prepared token.
 @updated				2011-06-25
 */
+ (NSString *) prepareEnclosure: (NSString *)token;
/*!
 @method				prepareIdentifier:
 @discussion			This method will prepare an identifier for an SQL statement.
 @param identifier		The identifier to be prepared.
 @return				The prepared identifier.
 @updated				2012-03-19
 */
+ (NSString *) prepareIdentifier: (id)identifier;
/*!
 @method				prepareJoinType:
 @discussion			This method will prepare a join type token for an SQL statement.
 @param token			The token to be prepared.
 @return				The prepared token.
 @updated				2012-03-18
 */
+ (NSString *) prepareJoinType: (NSString *)token;
/*!
 @method				prepareOperator:type
 @discussion			This method will prepare an operator for an SQL statement.
 @param operator		The operator to be prepared.
 @param type			The type of operator.
 @return				The prepared operator.
 @updated				2012-03-18
 */
+ (NSString *) prepareOperator: (NSString *)operator ofType: (NSString *)type;
/*!
 @method				prepareSortOrder:
 @discussion			This method will prepare a sort order token for an SQL statement.
 @param descending		This will determine whether the token represents a descending tkoen
						or an ascending token.
 @return				The prepared sort order token.
 @updated				2011-07-02
 */
+ (NSString *) prepareSortOrder: (BOOL)descending;
/*!
 @method				prepareSortWeight:
 @discussion			This method will prepare the sort weight for an SQL statement.
 @param weight			This indicates how nulls are to be weighed when comparing with non-nulls.
 @return				The prepared sort weight.
 @updated				2011-11-06
 */
+ (NSString *) prepareSortWeight: (NSString *)weight;
/*!
 @method				prepareValue:
 @discussion			This method will prepare a value for an SQL statement.
 @param value			The value to be prepared.
 @return				The prepared value.
 @updated				2012-03-08
 @see					http://www.sqlite.org/c3ref/mprintf.html
 @see					http://codingrecipes.com/objective-c-a-function-for-escaping-values-before-inserting-into-sqlite
 @see					http://wiki.sa-mp.com/wiki/Escaping_Strings_SQLite
 */
+ (NSString *) prepareValue: (id)value;

@end
