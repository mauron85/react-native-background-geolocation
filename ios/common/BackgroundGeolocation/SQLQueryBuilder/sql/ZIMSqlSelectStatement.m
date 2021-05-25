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

#import "NSString+ZIMString.h"
#import "ZIMSqlSelectStatement.h"

@implementation ZIMSqlSelectStatement

#pragma mark -
#pragma mark Public Methods

- (instancetype) init {
	if ((self = [super init])) {
		_distinct = NO;
		_all = @"*";
		_column = [[NSMutableArray alloc] init];
		_table = [[NSMutableArray alloc] init];
		_join = [[NSMutableArray alloc] init];
		_where = [[NSMutableArray alloc] init];
		_groupBy = [[NSMutableArray alloc] init];
		_having = [[NSMutableArray alloc] init];
		_orderBy = [[NSMutableArray alloc] init];
		_limit = 0;
		_offset = 0;
		_combine = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) distinct: (BOOL)distinct {
	_distinct = distinct;
}

- (void) all: (NSString *)all {
	if (all != nil) {
		_all = [ZIMSqlExpression prepareIdentifier: all];
		if (![_all hasSuffix: @".*"]) {
			_all = [NSString stringWithFormat: @"%@.*", _all];
		}
	}
	else {
		_all = @"*";
	}
	[_column removeAllObjects];
}

- (void) column: (id)column {
	[_column addObject: [ZIMSqlExpression prepareIdentifier: column]];
}

- (void) column: (id)column alias: (NSString *)alias {
	[_column addObject: [NSString stringWithFormat: @"%@ AS %@", [ZIMSqlExpression prepareIdentifier: column], [ZIMSqlExpression prepareAlias: alias]]];
}

- (void) columns: (NSArray *)columns {
	for (id column in columns) {
		[_column addObject: [ZIMSqlExpression prepareIdentifier: column]];
	}
}

- (void) from: (id)table {
	[_table addObject: [ZIMSqlExpression prepareIdentifier: table]];
}

- (void) from: (id)table alias: (NSString *)alias {
	[_table addObject: [NSString stringWithFormat: @"%@ %@", [ZIMSqlExpression prepareIdentifier: table], [ZIMSqlExpression prepareAlias: alias]]];
}

- (void) join: (id)table {
	[self join: table type: ZIMSqlJoinTypeInner];
}

- (void) join: (id)table alias: (NSString *)alias {
	[self join: table alias: alias type: ZIMSqlJoinTypeInner];
}

- (void) join: (id)table type: (NSString *)type {
	NSString *join = [NSString stringWithFormat: @"%@ JOIN %@", [ZIMSqlExpression prepareJoinType: type], [ZIMSqlExpression prepareIdentifier: table]];
	[_join addObject: @[join, [[NSMutableArray alloc] init], [[NSMutableArray alloc] init]]];
}

- (void) join: (id)table alias: (NSString *)alias type: (NSString *)type {
	NSString *join = [NSString stringWithFormat: @"%@ JOIN %@ %@", [ZIMSqlExpression prepareJoinType: type], [ZIMSqlExpression prepareIdentifier: table], [ZIMSqlExpression prepareAlias: alias]];
	[_join addObject: @[join, [[NSMutableArray alloc] init], [[NSMutableArray alloc] init]]];
}

- (void) joinOn: (id)column1 operator: (NSString *)operator column: (id)column2 {
	[self joinOn: column1 operator: operator column: column2 connector: ZIMSqlConnectorAnd];
}

- (void) joinOn: (id)column1 operator: (NSString *)operator column: (id)column2 connector: (NSString *)connector {
	NSUInteger length = [_join count];
	if (length > 0) {
		NSUInteger index = length - 1;
		NSMutableArray *joinCondition = (NSMutableArray *)[[_join objectAtIndex: index] objectAtIndex: 2];
		if ([joinCondition count] > 0) {
			@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"May not declare two different types of constraints on a JOIN statement." userInfo: nil];
		}
		joinCondition = (NSMutableArray *)[[_join objectAtIndex: index] objectAtIndex: 1];
		[joinCondition addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@", [ZIMSqlExpression prepareIdentifier: column1], [operator uppercaseString], [ZIMSqlExpression prepareIdentifier: column2]]]];
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Must declare a JOIN clause before declaring a constraint." userInfo: nil];
	}
}

- (void) joinOn: (id)column operator: (NSString *)operator value: (id)value {
	[self joinOn: column operator: operator value: value connector: ZIMSqlConnectorAnd];
}

- (void) joinOn: (id)column operator: (NSString *)operator value: (id)value connector: (NSString *)connector {
	NSUInteger length = [_join count];
	if (length > 0) {
		NSUInteger index = length - 1;
		NSMutableArray *joinCondition = (NSMutableArray *)[[_join objectAtIndex: index] objectAtIndex: 2];
		if ([joinCondition count] > 0) {
			@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"May not declare two different types of constraints on a JOIN statement." userInfo: nil];
		}
		joinCondition = (NSMutableArray *)[[_join objectAtIndex: index] objectAtIndex: 1];
		operator = [operator uppercaseString];
		if ([operator isEqualToString: ZIMSqlOperatorBetween] || [operator isEqualToString: ZIMSqlOperatorNotBetween]) {
			if (![value isKindOfClass: [NSArray class]]) {
				@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Operator requires the value to be declared as an array." userInfo: nil];
			}
			[joinCondition addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@ AND %@", [ZIMSqlExpression prepareIdentifier: column], operator, [ZIMSqlExpression prepareValue: [(NSArray *)value objectAtIndex: 0]], [ZIMSqlExpression prepareValue: [(NSArray *)value objectAtIndex: 1]]]]];
		}
		else {
			if (([operator isEqualToString: ZIMSqlOperatorIn] || [operator isEqualToString: ZIMSqlOperatorNotIn]) && ![value isKindOfClass: [NSArray class]]) {
				@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Operator requires the value to be declared as an array." userInfo: nil];
			}
			else if ([value isKindOfClass: [NSNull class]]) {
				if ([operator isEqualToString: ZIMSqlOperatorEqualTo]) {
					operator = ZIMSqlOperatorIs;
				}
				else if ([operator isEqualToString: ZIMSqlOperatorNotEqualTo] || [operator isEqualToString: @"!="]) {
					operator = ZIMSqlOperatorIsNot;
				}
			}
			[joinCondition addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@", [ZIMSqlExpression prepareIdentifier: column], operator, [ZIMSqlExpression prepareValue: value]]]];
		}
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Must declare a JOIN clause before declaring a constraint." userInfo: nil];
	}
}

- (void) joinUsing: (NSString *)column {
	NSUInteger length = [_join count];
	if (length > 0) {
		NSUInteger index = length - 1;
		NSMutableArray *joinCondition = (NSMutableArray *)[[_join objectAtIndex: index] objectAtIndex: 1];
		if ([joinCondition count] > 0) {
			@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"May not declare two different types of constraints on a JOIN statement." userInfo: nil];
		}
		joinCondition = (NSMutableArray *)[[_join objectAtIndex: index] objectAtIndex: 2];
		[joinCondition addObject: [ZIMSqlExpression prepareIdentifier: column]];
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Must declare a JOIN clause before declaring a constraint." userInfo: nil];
	}
}

- (void) whereBlock: (NSString *)brace {
	[self whereBlock: brace connector: ZIMSqlConnectorAnd];
}

- (void) whereBlock: (NSString *)brace connector: (NSString *)connector {
	[_where addObject: @[[ZIMSqlExpression prepareConnector: connector], [ZIMSqlExpression prepareEnclosure: brace]]];
}

- (void) where: (id)column1 operator: (NSString *)operator column: (id)column2 {
	[self where: column1 operator: operator column: column2 connector: ZIMSqlConnectorAnd];
}

- (void) where: (id)column1 operator: (NSString *)operator column: (id)column2 connector: (NSString *)connector {
	[_where addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@", [ZIMSqlExpression prepareIdentifier: column1], [operator uppercaseString], [ZIMSqlExpression prepareIdentifier: column2]]]];
}

- (void) where: (id)column operator: (NSString *)operator value: (id)value {
	[self where: column operator: operator value: value connector: ZIMSqlConnectorAnd];
}

- (void) where: (id)column operator: (NSString *)operator value: (id)value connector: (NSString *)connector {
	operator = [operator uppercaseString];
	if ([operator isEqualToString: ZIMSqlOperatorBetween] || [operator isEqualToString: ZIMSqlOperatorNotBetween]) {
		if (![value isKindOfClass: [NSArray class]]) {
			@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Operator requires the value to be declared as an array." userInfo: nil];
		}
		[_where addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@ AND %@", [ZIMSqlExpression prepareIdentifier: column], operator, [ZIMSqlExpression prepareValue: [(NSArray *)value objectAtIndex: 0]], [ZIMSqlExpression prepareValue: [(NSArray *)value objectAtIndex: 1]]]]];
	}
	else {
		if (([operator isEqualToString: ZIMSqlOperatorIn] || [operator isEqualToString: ZIMSqlOperatorNotIn]) && ![value isKindOfClass: [NSArray class]]) {
			@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Operator requires the value to be declared as an array." userInfo: nil];
		}
		else if ([value isKindOfClass: [NSNull class]]) {
			if ([operator isEqualToString: ZIMSqlOperatorEqualTo]) {
				operator = ZIMSqlOperatorIs;
			}
			else if ([operator isEqualToString: ZIMSqlOperatorNotEqualTo] || [operator isEqualToString: @"!="]) {
				operator = ZIMSqlOperatorIsNot;
			}
		}
		[_where addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@", [ZIMSqlExpression prepareIdentifier: column], operator, [ZIMSqlExpression prepareValue: value]]]];
	}
}

- (void) groupBy: (NSString *)column {
	[_groupBy addObject: [ZIMSqlExpression prepareIdentifier: column]];
}

- (void) groupByHavingBlock: (NSString *)brace {
	[self groupByHavingBlock: brace connector: ZIMSqlConnectorAnd];
}

- (void) groupByHavingBlock: (NSString *)brace connector: (NSString *)connector {
	if ([_groupBy count] > 0) {
		[_having addObject: @[[ZIMSqlExpression prepareConnector: connector], [ZIMSqlExpression prepareEnclosure: brace]]];
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Must declare a GROUP BY clause before declaring a constraint." userInfo: nil];
	}
}

- (void) groupByHaving: (id)column1 operator: (NSString *)operator column: (id)column2 {
	[self groupByHaving: column1 operator: operator column: column2 connector: ZIMSqlConnectorAnd];
}

- (void) groupByHaving: (id)column1 operator: (NSString *)operator column: (id)column2 connector: (NSString *)connector {
	if ([_groupBy count] > 0) {
		[_having addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@", [ZIMSqlExpression prepareIdentifier: column1], [operator uppercaseString], [ZIMSqlExpression prepareIdentifier: column2]]]];
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Must declare a GROUP BY clause before declaring a constraint." userInfo: nil];
	}
}

- (void) groupByHaving: (id)column operator: (NSString *)operator value: (id)value {
	[self groupByHaving: column operator: operator value: value connector: ZIMSqlConnectorAnd];
}

- (void) groupByHaving: (id)column operator: (NSString *)operator value: (id)value connector: (NSString *)connector {
	if ([_groupBy count] > 0) {
		operator = [operator uppercaseString];
		if ([operator isEqualToString: ZIMSqlOperatorBetween] || [operator isEqualToString: ZIMSqlOperatorNotBetween]) {
			if (![value isKindOfClass: [NSArray class]]) {
				@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Operator requires the value to be declared as an array." userInfo: nil];
			}
			[_having addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@ AND %@", [ZIMSqlExpression prepareIdentifier: column], operator, [ZIMSqlExpression prepareValue: [(NSArray *)value objectAtIndex: 0]], [ZIMSqlExpression prepareValue: [(NSArray *)value objectAtIndex: 1]]]]];
		}
		else {
			if (([operator isEqualToString: ZIMSqlOperatorIn] || [operator isEqualToString: ZIMSqlOperatorNotIn]) && ![value isKindOfClass: [NSArray class]]) {
				@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Operator requires the value to be declared as an array." userInfo: nil];
			}
			else if ([value isKindOfClass: [NSNull class]]) {
				if ([operator isEqualToString: ZIMSqlOperatorEqualTo]) {
					operator = ZIMSqlOperatorIs;
				}
				else if ([operator isEqualToString: ZIMSqlOperatorNotEqualTo] || [operator isEqualToString: @"!="]) {
					operator = ZIMSqlOperatorIsNot;
				}
			}
			[_having addObject: @[[ZIMSqlExpression prepareConnector: connector], [NSString stringWithFormat: @"%@ %@ %@", [ZIMSqlExpression prepareIdentifier: column], operator, [ZIMSqlExpression prepareValue: value]]]];
		}
	}
	else {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"Must declare a GROUP BY clause before declaring a constraint." userInfo: nil];
	}
}

- (void) orderBy: (NSString *)column {
	[self orderBy: column descending: NO nulls: nil];
}

- (void) orderBy: (NSString *)column descending: (BOOL)descending {
	[self orderBy: column descending: descending nulls: nil];
}

- (void) orderBy: (NSString *)column nulls: (NSString *)weight {
	[self orderBy: column descending: NO nulls: weight];
}

- (void) orderBy: (NSString *)column descending: (BOOL)descending nulls: (NSString *)weight {
	NSString *field = [ZIMSqlExpression prepareIdentifier: column];
	NSString *order = [ZIMSqlExpression prepareSortOrder: descending];
	weight = [ZIMSqlExpression prepareSortWeight: weight];
	if ([weight isEqualToString: @"FIRST"]) {
		[_orderBy addObject: [NSString stringWithFormat: @"CASE WHEN %@ IS NULL THEN 0 ELSE 1 END, %@ %@", field, field, order]];
	}
	else if ([weight isEqualToString: @"LAST"]) {
		[_orderBy addObject: [NSString stringWithFormat: @"CASE WHEN %@ IS NULL THEN 1 ELSE 0 END, %@ %@", field, field, order]];
	}
	else {
		[_orderBy addObject: [NSString stringWithFormat: @"%@ %@", field, order]];
	}
}

- (void) limit: (NSUInteger)limit {
	_limit = limit;
}

- (void) limit: (NSUInteger)limit offset: (NSUInteger)offset {
	_limit = limit;
	_offset = offset;
}

- (void) offset: (NSUInteger)offset {
	_offset = offset;
}

- (void) combine: (NSString *)statement operator: (NSString *)operator {
	statement = [statement stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" ;\n\r\t\f"]];
	if (![statement matchesRegex: @"^select .+$" options: NSRegularExpressionCaseInsensitive]) {
		@throw [NSException exceptionWithName: @"ZIMSqlException" reason: @"May only combine a select statement." userInfo: nil];
	}
	[_combine addObject: [NSString stringWithFormat: @"%@ %@", [ZIMSqlExpression prepareOperator: operator ofType: @"SET"], statement]];
}

- (NSString *) statement {
	NSMutableString *sql = [[NSMutableString alloc] init];
	
	[sql appendString: @"SELECT "];
	
	if (_distinct) {
		[sql appendString: @"DISTINCT "];
	}

	if ([_column count] > 0) {
		[sql appendString: [_column componentsJoinedByString: @", "]];
	}
	else {
		[sql appendString: _all];
	}

	if ([_table count] > 0) {
		[sql appendString: @" FROM "];
		[sql appendString: [_table componentsJoinedByString: @", "]];
	}

	for (NSArray *join in _join) {
		[sql appendFormat: @" %@", [join objectAtIndex: 0]];
		NSArray *joinCondition = (NSArray *)[join objectAtIndex: 1];
		if ([joinCondition count] > 0) {
            [sql appendString: @" ON ("];
            int i = 0;
            for (NSArray *joinParts in joinCondition) {
                NSString *onClause = [joinParts objectAtIndex: 1];
                if (i > 0) {
                    [sql appendFormat: @" %@ ", [joinParts objectAtIndex: 0]];
                }
                [sql appendString: onClause];
                i++;
            }
            [sql appendString: @")"];
		}
		else {
			joinCondition = (NSArray *)[join objectAtIndex: 2];
			if ([joinCondition count] > 0) {
				[sql appendFormat: @" USING (%@)", [joinCondition componentsJoinedByString: @", "]];
			}
		}
	}

	if ([_where count] > 0) {
		BOOL doAppendConnector = NO;
		[sql appendString: @" WHERE "];
		for (NSArray *where in _where) {
			NSString *whereClause = [where objectAtIndex: 1];
			if (doAppendConnector && ![whereClause isEqualToString: ZIMSqlEnclosureClosingBrace]) {
				[sql appendFormat: @" %@ ", [where objectAtIndex: 0]];
			}
			[sql appendString: whereClause];
			doAppendConnector = (![whereClause isEqualToString: ZIMSqlEnclosureOpeningBrace]);
		}
	}

	if ([_groupBy count] > 0) {
		[sql appendFormat: @" GROUP BY %@", [_groupBy componentsJoinedByString: @", "]];
	}
	
	if ([_having count] > 0) {
		BOOL doAppendConnector = NO;
		[sql appendString: @" HAVING "];
		for (NSArray *having in _having) {
			NSString *havingClause = [having objectAtIndex: 1];
			if (doAppendConnector && ![havingClause isEqualToString: ZIMSqlEnclosureClosingBrace]) {
				[sql appendFormat: @" %@ ", [having objectAtIndex: 0]];
			}
			[sql appendString: havingClause];
			doAppendConnector = (![havingClause isEqualToString: ZIMSqlEnclosureOpeningBrace]);
		}
	}
	
	if ([_orderBy count] > 0) {
		[sql appendFormat: @" ORDER BY %@", [_orderBy componentsJoinedByString: @", "]];
	}
	
	if (_limit > 0) {
		[sql appendFormat: @" LIMIT %lu", (unsigned long)_limit];
	}

	if (_offset > 0) {
		[sql appendFormat: @" OFFSET %lu", (unsigned long)_offset];
	}

	for (NSString *combine in _combine) {
		[sql appendFormat: @" %@", combine];
	}

	[sql appendString: @";"];

	return sql;
}

@end
