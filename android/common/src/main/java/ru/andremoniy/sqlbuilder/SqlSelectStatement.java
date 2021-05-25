/*
 * Java port of Objective-C SQL Query Builder
 *
 * https://github.com/ziminji/objective-c-sql-query-builder
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

package ru.andremoniy.sqlbuilder;

import ru.andremoniy.utils.TextUtils;

import java.util.ArrayList;
import java.util.List;

/*!
 @class					SqlSelectStatement
 @discussion			This class represents an SQL select statement.
 @updated				2012-04-10
 @see					http://www.sqlite.org/lang_select.html
 */
public class SqlSelectStatement implements SqlStatement {

    protected Boolean _distinct = null;
    protected String _all = null;
    protected List _column = null;
    protected List _table = null;
    protected List _join = null;
    protected List _where = null;
    protected List _groupBy = null;
    protected List _having = null;
    protected List _orderBy = null;
    protected Integer _limit = 0;
    protected Integer _offset = 0;
    protected List _combine = null;

    public SqlSelectStatement() {
        _distinct = false;
        _all = "*";
        _column = new ArrayList();
        _table = new ArrayList();
        _join = new ArrayList();
        _where = new ArrayList();
        _groupBy = new ArrayList();
        _having = new ArrayList();
        _orderBy = new ArrayList();
        _limit = 0;
        _offset = 0;
        _combine = new ArrayList();
    }

    /*!
     @method				distinct:
     @discussion			This method will add the "DISTINCT" keyword to the SQL statement.
     @param distinct		This will determine whether the "DISTINCT" keyword should added.
     @updated				2011-03-17
     */
    public void distinct(Boolean distinct) {
        _distinct = distinct;
    }

    /*!
     @method				all:
     @discussion			This method will set the wildcard to be used in the SQL statement.
     @param column			The column to be selected.
     @updated				2012-04-10
     */
    public void all(String all) {
        if (all != null) {
            _all = SqlExpression.prepareIdentifier(all);
            if (!_all.endsWith(".*")) {
                _all = String.format("%s.*", _all);
            }
        }
        else {
            _all = "*";
        }
        _column.clear();
    }

    /*!
     @method				column:
     @discussion			This method will add a column to the SQL statement.
     @param column			The column to be selected.
     @updated				2012-03-24
     */
    public void column(Object column) {
        _column.add(SqlExpression.prepareIdentifier(column));
    }

    /*!
     @method				column:alias:
     @discussion			This method will add a column to the SQL statement.
     @param column			The column to be selected.
     @param alias			The alias to be used.
     @updated				2012-03-24
     */
    public void column(Object column, String alias) {
        _column.add(String.format("%s AS %s", SqlExpression.prepareIdentifier(column), SqlExpression.prepareAlias(alias)));
    }

    /*!
     @method				columns:
     @discussion			This method will add the columns to the SQL statement.
     @param column			The columns to be selected.
     @updated				2012-04-10
     */
    public void columns(String[] columns) {
        for (String column : columns) {
            _column.add(SqlExpression.prepareIdentifier(column));
        }
    }

    /*!
     @method				from:
     @discussion			This method will add a from clause to the SQL statement.
     @param table			The table to used in the clause.
     @updated				2012-03-24
     */
    public void from(String table) {
        _table.add(SqlExpression.prepareIdentifier(table));
    }

    /*!
     @method				from:alias:
     @discussion			This method will add a from clause to the SQL statement.
     @param table			The table to used in the clause.
     @param alias			The alias to be used.
     @updated				2012-03-24
     */
    public void from(String table, String alias) {
        _table.add(String.format("%s %s", _all, SqlExpression.prepareIdentifier(table), SqlExpression.prepareAlias(alias)));
    }

    /*!
     @method				join:
     @discussion			This method will add a join clause to the SQL statement.
     @param table			The table to used in the clause.
     @updated				2012-03-24
     */
    public void join(String table) {
        join(table, SqlExpression.SqlJoinTypeInner);
    }

    /*!
     @method				join:alias:
     @discussion			This method will add a join clause to the SQL statement.
     @param table			The table to used in the clause.
     @param alias			The alias to be used.
     @updated				2012-03-24
     */
    public void join(String table, String alias) {
        join(table, alias, SqlExpression.SqlJoinTypeInner);
    }

    /*!
     @method				join:type:
     @discussion			This method will add a join clause to the SQL statement.
     @param table			The table to used in the clause.
     @param type			The type of join clause.
     @updated				2012-03-24
     */
    public void join(String table, Object type) {
        String join = String.format("%s JOIN %s", SqlExpression.prepareJoinType((String)type), SqlExpression.prepareIdentifier(table));
        _join.add(new Object[] { join, new ArrayList(), new ArrayList() });
    }

    /*!
     @method				join:alias:type:
     @discussion			This method will add a join clause to the SQL statement.
     @param table			The table to used in the clause.
     @param alias			The alias to be used.
     @param type			The type of join clause.
     @updated				2012-03-24
     */
    public void join(String table, String alias, String type) {
        String join = String.format("%s JOIN %s %s", SqlExpression.prepareJoinType(type), SqlExpression.prepareIdentifier(table), SqlExpression.prepareAlias(alias));
        _join.add(new Object[] { join, new ArrayList(), new ArrayList() });
    }

    /*!
     @method				joinOn:operator:column:
     @discussion			This method will add a join condition to the last defined join clause.
     @param column1			The column to be tested.
     @param operator		The operator to be used.
     @param column2			The column to be tested on.
     @updated				2012-03-24
     */
    public void joinOn(String column1, String operator, String column2) {
        joinOn(column1, operator, column2, SqlExpression.SqlConnectorAnd);
    }

    /*!
     @method				joinOn:operator:column:connector:
     @discussion			This method will add a join condition to the last defined join clause.
     @param column1			The column to be tested.
     @param operator		The operator to be used.
     @param column2			The column to be tested on.
     @param connector		The connector to be used.
     @updated				2012-03-24
     */
    public void joinOn(String column1, String operator, String column2, String connector) {
        int length = _join.size();
        if (length > 0) {
            int index = length - 1;
            ArrayList joinCondition = (ArrayList) ((Object[]) _join.get(index))[2];
            if (joinCondition.size() > 0) {
                throw new IllegalArgumentException("May not declare two different types of constraints on a JOIN statement.");
            }
            joinCondition = (ArrayList)((Object[]) _join.get(index))[1];
            joinCondition.add(new Object[]{
                    SqlExpression.prepareConnector(connector),
                    String.format("%s %s %s",
                            SqlExpression.prepareIdentifier(column1),
                            operator != null ? operator.toUpperCase() : "",
                            SqlExpression.prepareIdentifier(column2)
                    )
            });
        } else {
            throw new IllegalArgumentException("Must declare a JOIN clause before declaring a constraint.");
        }
    }

    /*!
     @method				joinOn:operator:value:
     @discussion			This method will add a join condition to the last defined join clause.
     @param column			The column to be tested.
     @param operator		The operator to be used.
     @param value			The value to be compared.
     @updated				2012-03-24
     */
    public void joinOn(String column, String operator, Object value) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				joinOn:operator:value:connector:
     @discussion			This method will add a join condition to the last defined join clause.
     @param column			The column to be tested.
     @param operator		The operator to be used.
     @param value			The value to be compared.
     @param connector		The connector to be used.
     @updated				2012-03-24
     */
    public void joinOn(Object column, String operator, Object value, String connector) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				joinUsing:
     @discussion			This method will add a join condition to the last defined join clause.
     @param column			The column to be tested.
     @updated				2011-07-15
     */
    public void joinUsing(String column) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				whereBlock:
     @discussion			This method will start or end a block.
     @param brace			The brace to be used; it is either an opening or closing brace.
     @updated				2011-03-13
     */
    public void whereBlock(String brace) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				whereBlock:connector:
     @discussion			This method will start or end a block.
     @param brace			The brace to be used; it is either an opening or closing brace.
     @param connector		The connector to be used.
     @updated				2011-04-01
     */
    public void whereBlock(String brace, String connector) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				where:operator:column:
     @discussion			This method will add a where clause to the SQL statement.
     @param column1			The column to be tested.
     @param operator		The operator to be used.
     @param column2			The column to be compared.
     @updated				2012-03-24
     */
    public void where(String column1, String operator, String column2) {
        where(column1, operator, column2, SqlExpression.SqlConnectorAnd);
    }

    /*!
     @method				where:operator:column:connector:
     @discussion			This method will add a where clause to the SQL statement.
     @param column1			The column to be tested.
     @param operator		The operator to be used.
     @param column2			The column to be compared.
     @param connector		The connector to be used.
     @updated				2012-03-24
     */
    public void where(String column1, String operator, String column2, String connector) {
        _where.add(new Object[]{
                SqlExpression.prepareConnector(connector),
                String.format("%s %s %s", SqlExpression.prepareIdentifier(column1), SqlExpression.prepareIdentifier(column2))
        });
    }

    /*!
     @method				where:operator:value:
     @discussion			This method will add a where clause to the SQL statement.
     @param column			The column to be tested.
     @param operator		The operator to be used.
     @param value			The value to be compared.
     @updated				2012-03-24
     */
    public void where(String column, String operator, Object value) {
        where(column, operator, value, SqlExpression.SqlConnectorAnd);
    }

    /*!
     @method				where:operator:value:connector:
     @discussion			This method will add a where clause to the SQL statement.
     @param column			The column to be tested.
     @param operator		The operator to be used.
     @param value			The value to be compared.
     @param connector		The connector to be used.
     @updated				2012-03-24
     */
    public void where(String column, String operator, Object value, String connector) {
        if (operator == null) {
            return;
        }
        operator = operator.toUpperCase();
        if (SqlExpression.SqlOperatorBetween.equals(operator) || SqlExpression.SqlOperatorNotBetween.equals(operator)) {
            if (!(value != null && value.getClass().isArray())) {
                throw new IllegalArgumentException("Operator requires the value to be declared as an array");
            }
            _where.add(new Object[] {
                    SqlExpression.prepareConnector(connector),
                    String.format("%s %s %s AND %s",
                            SqlExpression.prepareIdentifier(column),
                            operator,
                            SqlExpression.prepareValue(((Object[])value)[0]),
                            SqlExpression.prepareValue(((Object[])value)[1])
                    )
            });
        } else {
            if ((SqlExpression.SqlOperatorIn.equals(operator)
                    || SqlExpression.SqlOperatorNotIn.equals(operator))
                    && !(value != null && value.getClass().isArray())) {
                throw new IllegalArgumentException("Operator requires the value to be declared as an array");
            } else if (SqlExpression.NULL.equals(value)) {
                if (SqlExpression.SqlOperatorEqualTo.equals(operator)) {
                    operator = SqlExpression.SqlOperatorIs;
                } else if (SqlExpression.SqlOperatorNotEqualTo.equals(operator) || "!=".equals(operator)) {
                    operator = SqlExpression.SqlOperatorIsNot;
                }
            }
            _where.add(new Object[] {
                    SqlExpression.prepareConnector(connector),
                    String.format("%s %s %s",
                            SqlExpression.prepareIdentifier(column),
                            operator,
                            SqlExpression.prepareValue(value)
                    )
            });
        }
    }

    /*!
     @method				groupBy:
     @discussion			This method will add a group by clause to the SQL statement.
     @param column			The column to be grouped.
     @updated				2011-04-01
     */
    public void groupBy(String column) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				groupByHavingBlock:
     @discussion			This method will start or end a block.
     @param brace			The brace to be used; it is either an opening or closing brace.
     @updated				2011-03-18
     */
    public void groupByHavingBlock(String brace) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				groupByHavingBlock:connector:
     @discussion			This method will start or end a block.
     @param brace			The brace to be used; it is either an opening or closing brace.
     @param connector		The connector to be used.
     @updated				2011-03-18
     */
    public void groupByHavingBlock(String brace, String connector) {
        throw new UnsupportedOperationException();
    }

    ;

    /*!
     @method				groupByHaving:operator:column:
     @discussion			This method will add a having clause to the SQL statement.
     @param column1			The column to be tested.
     @param operator		The operator to be used.
     @param column2			The column to be compared.
     @updated				2012-03-24
     */
    public void groupByHaving(Object column1, String operator, Object column2) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				groupByHaving:operator:column:connector:
     @discussion			This method will add a having clause to the SQL statement.
     @param column1			The column to be tested.
     @param operator		The operator to be used.
     @param column2			The column to be compared.
     @param connector		The connector to be used.
     @updated				2012-03-24
     */
    public void groupByHaving(Object column1, String operator, Object column2, String connector) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				groupByHaving:operator:value:
     @discussion			This method will add a having clause to the SQL statement.
     @param column			The column to be tested.
     @param operator		The operator to be used.
     @param value			The value to be compared.
     @updated				2012-03-24
     */
    public void groupByHavingValue(Object column, String operator, Object value) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				groupByHaving:operator:value:connector:
     @discussion			This method will add a having clause to the SQL statement.
     @param column			The column to be tested.
     @param operator		The operator to be used.
     @param value			The value to be compared.
     @param connector		The connector to be used.
     @updated				2012-03-24
     */
    public void groupByHavingValue(Object column, String operator, Object value, String connector) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				orderBy:
     @discussion			This method will add an order by clause to the SQL statement.
     @param column			The column to be ordered.
     @updated				2012-03-19
     */
    public void orderBy(String column) {
        orderBy(column, false, null);
    }

    /*!
     @method				orderBy:descending:
     @discussion			This method will add an order by clause to the SQL statement.
     @param column			The column to be ordered.
     @param descending		This will determine whether the column should be ordered in descending order.
     @updated				2012-03-19
     */
    public void orderBy(String column, Boolean descending) {
        orderBy(column, descending, null);
    }

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
    public void orderBy(String column, String weight) {
        orderBy(column, false, weight);
    }

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
    public void orderBy(String column, Boolean descending, String weight) {
        String field = SqlExpression.prepareIdentifier(column);
        String order = SqlExpression.prepareSortOrder(descending);
        weight = SqlExpression.prepareSortWeight(weight);
        if ("FIRST".equals(weight)) {
            _orderBy.add(String.format("CASE WHEN %s IS NULL THEN 0 ELSE 1 END, %s %s",
                    field, field, order));
        } else if ("LAST".equals(weight)) {
            _orderBy.add(String.format("CASE WHEN %s IS NULL THEN 1 ELSE 0 END, %s %s",
                    field, field, order));
        } else {
            _orderBy.add(String.format("%s %s", field, order));
        }
    }

    /*!
     @method				limit:
     @discussion			This method will add a limit clause to the SQL statement.
     @param limit			The number of records to be returned.
     @updated				2012-03-18
     */
    public void limit(Integer limit) {
        _limit = limit;
    }

    /*!
     @method				limit:offset:
     @discussion			This method will add a limit clause and an offset clause to the SQL statement.
     @param limit			The number of records to be returned.
     @param offset			The starting point to start evaluating.
     @updated				2012-03-18
     */
    public void limit(Integer limit, Integer offset) {
        _limit = limit;
        _offset = offset;
    }

    /*!
     @method				offset:
     @discussion			This method will add an offset clause to the SQL statement.
     @param offset			The starting point to start evaluating.
     @updated				2012-03-18
     */
    public void offset(Integer offset) {
        _offset = offset;
    }


    /*!
     @method				combine:operator:
     @discussion			This method will combine a select statement using the specified operator.
     @param statement		The select statement that will be appended.
     @param operator		The operator to be used.  Must use UNION, UNION ALL, INTERSECT, or EXCEPT.
     @updated				2012-03-18
     */
    public void combine(String statement, String operator) {
        throw new UnsupportedOperationException();
    }


    /*!
     @method				statement
     @discussion			This method will return the SQL statement.
     @return				The SQL statement that was constructed.
     @updated				2012-04-10
    */
    public String statement() {
        StringBuilder b = new StringBuilder();
        b.append("SELECT ");

        if (_distinct) {
            b.append("DISTINCT ");
        }

        if (_column.size() > 0) {
            b.append(TextUtils.join(", ", _column));
        } else {
            b.append(_all);
        }

        if (_table.size() > 0) {
            b.append(" FROM ");
            b.append(TextUtils.join(", ", _table));
        }

        for (Object join : _join) {
            Object[] joinArray = (Object[])join;
            b.append(" ").append(joinArray[0]);
            Object[] joinCondition = (Object[])joinArray[1];
            if (joinCondition.length > 0) {
                b.append(" ON (");
                int i = 0;
                for (Object joinParts : joinCondition) {
                    Object[] joinPartsArray = (Object[])join;
                    String onClause = (String)joinPartsArray[1];
                    if (i > 0) {
                        b.append(joinPartsArray[0]).append(" ");
                    }
                    b.append(onClause);
                    i++;
                }
                b.append(")");
            } else {
                joinCondition = (Object[])joinArray[2];
                if (joinCondition.length > 0) {
                    b.append(" USING (").append(TextUtils.join(", ", joinCondition)).append(")");
                }
            }
        }

        if (_where.size() > 0) {
            boolean doAppendConnector = false;
            b.append(" WHERE ");
            for (Object where : _where) {
                Object[] whereArray = (Object[])where;
                String whereClause = (String)whereArray[1];
                if (doAppendConnector && !SqlExpression.SqlEnclosureClosingBrace.equals(whereClause)) {
                    b.append(" ").append(whereArray[0]).append(" ");
                }
                b.append(whereClause);
                doAppendConnector = (!SqlExpression.SqlEnclosureOpeningBrace.equals(whereClause));
            }
        }

        if (_groupBy.size() > 0) {
            b.append(" GROUP BY ").append(TextUtils.join(", ", _groupBy));
        }

        if (_having.size() > 0) {
            boolean doAppendConnector = false;
            b.append(" HAVING ");
            for (Object having : _having) {
                Object[] havingArray = (Object[])having;
                String havingClause = (String)havingArray[1];
                if (doAppendConnector && !SqlExpression.SqlEnclosureClosingBrace.equals(havingClause)) {
                    b.append(" ").append(havingArray[0]).append(" ");
                }
                b.append(havingClause);
                doAppendConnector = (!SqlExpression.SqlEnclosureOpeningBrace.equals(havingClause));
            }
        }

        if (_orderBy.size() > 0) {
            b.append(" ORDER BY ").append(TextUtils.join(", ", _orderBy));
        }

        if (_limit > 0) {
            b.append(" LIMIT ").append(_limit);
        }

        if (_offset > 0) {
            b.append(" OFFSET ").append(_offset);
        }

        for (Object combine : _combine) {
            b.append(" ").append(combine);
        }

        b.append(";");

        return b.toString();
    }
}
