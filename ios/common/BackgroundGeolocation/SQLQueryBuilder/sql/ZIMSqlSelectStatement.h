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

#import "ZIMSqlStatement.h"
#import "ZIMSqlDataManipulationCommand.h"

/*!
 @class					ZIMSqlSelectStatement
 @discussion			This class represents an SQL select statement.
 @updated				2012-04-10
 @see					http://www.sqlite.org/lang_select.html
 */
@interface ZIMSqlSelectStatement : NSObject <ZIMSqlStatement, ZIMSqlDataManipulationCommand> {

	@protected
		BOOL _distinct;
		NSString *_all;
		NSMutableArray *_column;
		NSMutableArray *_table;
		NSMutableArray *_join;
		NSMutableArray *_where;
		NSMutableArray *_groupBy;
		NSMutableArray *_having;
		NSMutableArray *_orderBy;
		NSUInteger _limit;
		NSUInteger _offset;
		NSMutableArray *_combine;

}
/*!
 @method				distinct:
 @discussion			This method will add the "DISTINCT" keyword to the SQL statement.
 @param distinct		This will determine whether the "DISTINCT" keyword should added.
 @updated				2011-03-17
 */
- (void) distinct: (BOOL)distinct;
/*!
 @method				all:
 @discussion			This method will set the wildcard to be used in the SQL statement.
 @param column			The column to be selected.
 @updated				2012-04-10
 */
- (void) all: (NSString *)all;
/*!
 @method				column:
 @discussion			This method will add a column to the SQL statement.
 @param column			The column to be selected.
 @updated				2012-03-24
 */
- (void) column: (id)column;
/*!
 @method				column:alias:
 @discussion			This method will add a column to the SQL statement.
 @param column			The column to be selected.
 @param alias			The alias to be used.
 @updated				2012-03-24
 */
- (void) column: (id)column alias: (NSString *)alias;
/*!
 @method				columns:
 @discussion			This method will add the columns to the SQL statement.
 @param column			The columns to be selected.
 @updated				2012-04-10
 */
- (void) columns: (NSArray *)columns;
/*!
 @method				from:
 @discussion			This method will add a from clause to the SQL statement.
 @param table			The table to used in the clause.
 @updated				2012-03-24
 */
- (void) from: (id)table;
/*!
 @method				from:alias:
 @discussion			This method will add a from clause to the SQL statement.
 @param table			The table to used in the clause.
 @param alias			The alias to be used.
 @updated				2012-03-24
 */
- (void) from: (id)table alias: (NSString *)alias;
/*!
 @method				join:
 @discussion			This method will add a join clause to the SQL statement.
 @param table			The table to used in the clause.
 @updated				2012-03-24
 */
- (void) join: (id)table;
/*!
 @method				join:alias:
 @discussion			This method will add a join clause to the SQL statement.
 @param table			The table to used in the clause.
 @param alias			The alias to be used.
 @updated				2012-03-24
 */
- (void) join: (id)table alias: (NSString *)alias;
/*!
 @method				join:type:
 @discussion			This method will add a join clause to the SQL statement.
 @param table			The table to used in the clause.
 @param type			The type of join clause.
 @updated				2012-03-24
 */
- (void) join: (id)table type: (NSString *)type;
/*!
 @method				join:alias:type:
 @discussion			This method will add a join clause to the SQL statement.
 @param table			The table to used in the clause.
 @param alias			The alias to be used.
 @param type			The type of join clause.
 @updated				2012-03-24
 */
- (void) join: (id)table alias: (NSString *)alias type: (NSString *)type;
/*!
 @method				joinOn:operator:column:
 @discussion			This method will add a join condition to the last defined join clause.
 @param column1			The column to be tested.
 @param operator		The operator to be used.
 @param column2			The column to be tested on.
 @updated				2012-03-24
 */
- (void) joinOn: (id)column1 operator: (NSString *)operator column: (id)column2;
/*!
 @method				joinOn:operator:column:connector:
 @discussion			This method will add a join condition to the last defined join clause.
 @param column1			The column to be tested.
 @param operator		The operator to be used.
 @param column2			The column to be tested on.
 @param connector		The connector to be used.
 @updated				2012-03-24
 */
- (void) joinOn: (id)column1 operator: (NSString *)operator column: (id)column2 connector: (NSString *)connector;
/*!
 @method				joinOn:operator:value:
 @discussion			This method will add a join condition to the last defined join clause.
 @param column			The column to be tested.
 @param operator		The operator to be used.
 @param value			The value to be compared.
 @updated				2012-03-24
 */
- (void) joinOn: (id)column operator: (NSString *)operator value: (id)value;
/*!
 @method				joinOn:operator:value:connector:
 @discussion			This method will add a join condition to the last defined join clause.
 @param column			The column to be tested.
 @param operator		The operator to be used.
 @param value			The value to be compared.
 @param connector		The connector to be used.
 @updated				2012-03-24
 */
- (void) joinOn: (id)column operator: (NSString *)operator value: (id)value connector: (NSString *)connector;
/*!
 @method				joinUsing:
 @discussion			This method will add a join condition to the last defined join clause.
 @param column			The column to be tested.
 @updated				2011-07-15
 */
- (void) joinUsing: (NSString *)column;
/*!
 @method				whereBlock:
 @discussion			This method will start or end a block.
 @param brace			The brace to be used; it is either an opening or closing brace.
 @updated				2011-03-13
 */
- (void) whereBlock: (NSString *)brace;
/*!
 @method				whereBlock:connector:
 @discussion			This method will start or end a block.
 @param brace			The brace to be used; it is either an opening or closing brace.
 @param connector		The connector to be used.
 @updated				2011-04-01
 */
- (void) whereBlock: (NSString *)brace connector: (NSString *)connector;
/*!
 @method				where:operator:column:
 @discussion			This method will add a where clause to the SQL statement.
 @param column1			The column to be tested.
 @param operator		The operator to be used.
 @param column2			The column to be compared.
 @updated				2012-03-24
 */
- (void) where: (id)column1 operator: (NSString *)operator column: (id)column2;
/*!
 @method				where:operator:column:connector:
 @discussion			This method will add a where clause to the SQL statement.
 @param column1			The column to be tested.
 @param operator		The operator to be used.
 @param column2			The column to be compared.
 @param connector		The connector to be used.
 @updated				2012-03-24
 */
- (void) where: (id)column1 operator: (NSString *)operator column: (id)column2 connector: (NSString *)connector;
/*!
 @method				where:operator:value:
 @discussion			This method will add a where clause to the SQL statement.
 @param column			The column to be tested.
 @param operator		The operator to be used.
 @param value			The value to be compared.
 @updated				2012-03-24
 */
- (void) where: (id)column operator: (NSString *)operator value: (id)value; // wrap primitives with NSNumber
/*!
 @method				where:operator:value:connector:
 @discussion			This method will add a where clause to the SQL statement.
 @param column			The column to be tested.
 @param operator		The operator to be used.
 @param value			The value to be compared.
 @param connector		The connector to be used.
 @updated				2012-03-24
 */
- (void) where: (id)column operator: (NSString *)operator value: (id)value connector: (NSString *)connector; // wrap primitives with NSNumber
/*!
 @method				groupBy:
 @discussion			This method will add a group by clause to the SQL statement.
 @param column			The column to be grouped.
 @updated				2011-04-01
 */
- (void) groupBy: (NSString *)column;
/*!
 @method				groupByHavingBlock:
 @discussion			This method will start or end a block.
 @param brace			The brace to be used; it is either an opening or closing brace.
 @updated				2011-03-18
 */
- (void) groupByHavingBlock: (NSString *)brace;
/*!
 @method				groupByHavingBlock:connector:
 @discussion			This method will start or end a block.
 @param brace			The brace to be used; it is either an opening or closing brace.
 @param connector		The connector to be used.
 @updated				2011-03-18
 */
- (void) groupByHavingBlock: (NSString *)brace connector: (NSString *)connector;
/*!
 @method				groupByHaving:operator:column:
 @discussion			This method will add a having clause to the SQL statement.
 @param column1			The column to be tested.
 @param operator		The operator to be used.
 @param column2			The column to be compared.
 @updated				2012-03-24
 */
- (void) groupByHaving: (id)column1 operator: (NSString *)operator column: (id)column2;
/*!
 @method				groupByHaving:operator:column:connector:
 @discussion			This method will add a having clause to the SQL statement.
 @param column1			The column to be tested.
 @param operator		The operator to be used.
 @param column2			The column to be compared.
 @param connector		The connector to be used.
 @updated				2012-03-24
 */
- (void) groupByHaving: (id)column1 operator: (NSString *)operator column: (id)column2 connector: (NSString *)connector;
/*!
 @method				groupByHaving:operator:value:
 @discussion			This method will add a having clause to the SQL statement.
 @param column			The column to be tested.
 @param operator		The operator to be used.
 @param value			The value to be compared.
 @updated				2012-03-24
 */
- (void) groupByHaving: (id)column operator: (NSString *)operator value: (id)value; // wrap primitives with NSNumber
/*!
 @method				groupByHaving:operator:value:connector:
 @discussion			This method will add a having clause to the SQL statement.
 @param column			The column to be tested.
 @param operator		The operator to be used.
 @param value			The value to be compared.
 @param connector		The connector to be used.
 @updated				2012-03-24
 */
- (void) groupByHaving: (id)column operator: (NSString *)operator value: (id)value connector: (NSString *)connector; // wrap primitives with NSNumber
/*!
 @method				orderBy:
 @discussion			This method will add an order by clause to the SQL statement.
 @param column			The column to be ordered.
 @updated				2012-03-19
 */
- (void) orderBy: (NSString *)column; // ORDER BY [COLUMN] ASC
/*!
 @method				orderBy:descending:
 @discussion			This method will add an order by clause to the SQL statement.
 @param column			The column to be ordered.
 @param descending		This will determine whether the column should be ordered in descending order.
 @updated				2012-03-19
 */
- (void) orderBy: (NSString *)column descending: (BOOL)descending; // ORDER BY [COLUMN] [ASC | DESC]
/*!
 @method				orderBy:nulls:
 @discussion			This method will add an order by clause to the SQL statement.
 @param column			The column to be ordered.
 @param weight			This indicates how nulls are to be weighed when comparing with non-nulls.
 @updated				2012-03-19
 @see					http://sqlite.org/cvstrac/wiki?p=UnsupportedSql
 @see					https://hibernate.onjira.com/browse/HHH-465
 @see					http://sqlblog.com/blogs/denis_gobo/archive/2007/10/19/3048.aspx
 */
- (void) orderBy: (NSString *)column nulls: (NSString *)weight; // ORDER BY [COLUMN] ASC [NULLS FIRST | NULLS LAST]
/*!
 @method				orderBy:descending:nulls:
 @discussion			This method will add an order by clause to the SQL statement.
 @param column			The column to be ordered.
 @param descending		This will determine whether the column should be ordered in descending order.
 @param weight			This indicates how nulls are to be weighed when comparing with non-nulls.
 @updated				2012-03-19
 @see					http://sqlite.org/cvstrac/wiki?p=UnsupportedSql
 @see					https://hibernate.onjira.com/browse/HHH-465
 @see					http://sqlblog.com/blogs/denis_gobo/archive/2007/10/19/3048.aspx
 */
- (void) orderBy: (NSString *)column descending: (BOOL)descending nulls: (NSString *)weight; // ORDER BY [COLUMN] [ASC | DESC] [NULLS FIRST | NULLS LAST]
/*!
 @method				limit:
 @discussion			This method will add a limit clause to the SQL statement.
 @param limit			The number of records to be returned.
 @updated				2012-03-18
 */
- (void) limit: (NSUInteger)limit;
/*!
 @method				limit:offset:
 @discussion			This method will add a limit clause and an offset clause to the SQL statement.
 @param limit			The number of records to be returned.
 @param offset			The starting point to start evaluating.
 @updated				2012-03-18
 */
- (void) limit: (NSUInteger)limit offset: (NSUInteger)offset;
/*!
 @method				offset:
 @discussion			This method will add an offset clause to the SQL statement.
 @param offset			The starting point to start evaluating.
 @updated				2012-03-18
 */
- (void) offset: (NSUInteger)offset;
/*!
 @method				combine:operator:
 @discussion			This method will combine a select statement using the specified operator.
 @param statement		The select statement that will be appended.
 @param operator		The operator to be used.  Must use UNION, UNION ALL, INTERSECT, or EXCEPT.
 @updated				2012-03-18
 */
- (void) combine: (NSString *)statement operator: (NSString *)operator;
/*!
 @method				statement
 @discussion			This method will return the SQL statement.
 @return				The SQL statement that was constructed.
 @updated				2012-04-10
 */
- (NSString *) statement;

@end
