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

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

public class SqlExpression {
    public static final String NULL = "NULL";

    // Block Statement Tokens
    public static final String SqlEnclosureOpeningBrace = "(";
    public static final String SqlEnclosureClosingBrace = ")";

    // Connectors
    public static final String SqlConnectorAnd = "AND";
    public static final String SqlConnectorOr = "OR";

    // Join Types -- http://sqlite.org/syntaxdiagrams.html#join-op
    public static final String SqlJoinTypeCross = "CROSS";
    public static final String SqlJoinTypeInner = "INNER";
    public static final String SqlJoinTypeLeft = "LEFT";
    public static final String SqlJoinTypeLeftOuter = "LEFT OUTER";
    public static final String SqlJoinTypeNatural = "NATURAL";
    public static final String SqlJoinTypeNaturalCross = "NATURAL CROSS";
    public static final String SqlJoinTypeNaturalInner = "NATURAL INNER";
    public static final String SqlJoinTypeNaturalLeft = "NATURAL LEFT";
    public static final String SqlJoinTypeNaturalLeftOuter = "NATURAL LEFT OUTER";
    public static final String SqlJoinTypeNone = "";

    // Expressions -- http://zetcode.com/databases/sqlitetutorial/expressions/
    // Arithmetic Operators
    public static final String SqlOperatorAdd = "+";
    public static final String SqlOperatorSubtract = "-";
    public static final String SqlOperatorMultiply = "*";
    public static final String SqlOperatorDivide = "/";
    public static final String SqlOperatorMod = "%";

    // Boolean Operators
    public static final String SqlOperatorAnd = "AND";
    public static final String SqlOperatorOr = "OR";
    public static final String SqlOperatorNot = "NOT";

    // Relational Operators
    public static final String SqlOperatorLessThan = "<";
    public static final String SqlOperatorLessThanOrEqualTo = "<=";
    public static final String SqlOperatorGreaterThan = ">";
    public static final String SqlOperatorGreaterThanOrEqualTo = ">=";
    public static final String SqlOperatorEqualTo = "=";
    public static final String SqlOperatorNotEqualTo = "<>";

    // Bitwise Operators
    public static final String SqlOperatorBitwiseAnd = "&";
    public static final String SqlOperatorBitwiseOr = "|";
    public static final String SqlOperatorBitwiseShiftLeft = "<<";
    public static final String SqlOperatorBitwiseShiftRight = ">>";
    public static final String SqlOperatorBitwiseNegation = "~";

    // Additional Operators
    public static final String SqlOperatorConcatenate = "||";
    public static final String SqlOperatorIn = "IN";
    public static final String SqlOperatorNotIn = "NOT IN";
    public static final String SqlOperatorIs = "IS";
    public static final String SqlOperatorIsNot = "IS NOT";
    public static final String SqlOperatorLike = "LIKE";
    public static final String SqlOperatorNotLike = "NOT LIKE";
    public static final String SqlOperatorGlob = "GLOB";
    public static final String SqlOperatorNotGlob = "NOT GLOB";
    public static final String SqlOperatorBetween = "BETWEEN";
    public static final String SqlOperatorNotBetween = "NOT BETWEEN";

    // Set Operators
    public static final String SqlOperatorExcept = "EXCEPT";
    public static final String SqlOperatorIntersect = "INTERSECT";
    public static final String SqlOperatorUnion = "UNION";
    public static final String SqlOperatorUnionAll = "UNION ALL";

    // Show Types
    public static final String SqlShowTypeAll = "ALL";
    public static final String SqlShowTypePermanent = "PERMANENT";
    public static final String SqlShowTypeTemporary = "TEMPORARY";

    // Order Operators (for Nulls)
    public static final String SqlNullsFirst = "FIRST";
    public static final String SqlNullsLast = "LAST";

    // Default Values -- http://forums.realsoftware.com/viewtopic.php?f=3&t=35179
    public static final String SqlDefaultValueIsAutoIncremented = "PRIMARY KEY AUTOINCREMENT NOT NULL";
    public static final String SqlDefaultValueIsNull = "DEFAULT NULL";
    public static final String SqlDefaultValueIsNotNull = "NOT NULL";
    public static final String SqlDefaultValueIsCurrentDate = "DEFAULT CURRENT_DATE";
    public static final String SqlDefaultValueIsCurrentDateTime = "DEFAULT (datetime('now','localtime'))";
    public static final String SqlDefaultValueIsCurrentTime = "DEFAULT CURRENT_TIME";
    public static final String SqlDefaultValueIsCurrentTimestamp = "DEFAULT CURRENT_TIMESTAMP";

    // Declared Datetype -- http://www.sqlite.org/datatype3.html
    public static final String SqlDataTypeBigInt = "BIGINT";
    public static final String SqlDataTypeBlob = "BLOB";
    public static final String SqlDataTypeBoolean = "BOOLEAN";
    public static final String SqlDataTypeClob = "CLOB";
    public static final String SqlDataTypeDate = "DATE";
    public static final String SqlDataTypeDateTime = "DATETIME";
    public static final String SqlDataTypeDouble = "DOUBLE";
    public static final String SqlDataTypeDoublePrecision = "DOUBLE PRECISION";
    public static final String SqlDataTypeFloat = "FLOAT";
    public static final String SqlDataTypeInt = "INT";
    public static final String SqlDataTypeInt2 = "INT2";
    public static final String SqlDataTypeInt8 = "INT8";
    public static final String SqlDataTypeInteger = "INTEGER";
    public static final String SqlDataTypeMediumInt = "MEDIUMINT";
    public static final String SqlDataTypeNumeric = "NUMERIC";
    public static final String SqlDataTypeReal = "REAL";
    public static final String SqlDataTypeSmallInt = "SMALLINT";
    public static final String SqlDataTypeText = "TEXT";
    public static final String SqlDataTypeTimestamp = "TIMESTAMP";
    public static final String SqlDataTypeTinyInt = "TINYINT";
    public static final String SqlDataTypeUnsignedBigInt = "UNSIGNED BIG INT";
    public static final String SqlDataTypeVariant = "VARIANT";

    static String SqlDefaultValue(Object value) {
        throw new UnsupportedOperationException();
    };
    static String SqlDataTypeChar(long x) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeCharacter(long x) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeDecimal(long x, long y) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeNativeCharacter(long x) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeNChar(long x) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeNVarChar(long x) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeVarChar(long x) {
        throw new UnsupportedOperationException();
    }
    static String SqlDataTypeVaryingCharacter(long x) {
        throw new UnsupportedOperationException();
    }

    static Object SqlDefaultValue = null;
    static Integer SqlDataTypeChar = 0;
    static Integer SqlDataTypeCharacter = 0;
    static Integer SqlDataTypeDecimal = 0;
    static Integer SqlDataTypeNativeCharacter = 0;
    static Integer SqlDataTypeNChar = 0;
    static Integer SqlDataTypeNVarChar = 0;
    static Integer SqlDataTypeVarChar = 0;
    static Integer SqlDataTypeVaryingCharacter = 0;

    protected String _expression = null;

    public SqlExpression() {

    }

    /*!
     @method				initWithSqlExpression:
     @discussion			This method initialize the class with the specified SQL expression.
     @param sql				The SQL expression to be wrapped.
     @return				An instance of this class.
     @updated				2012-03-14
     */
    public SqlExpression(String sql) {
        this();
        _expression = sql;
    }

    /*!
     @method				expression
     @discussion			This method returns the wrapped SQL expression.
     @return				The wrapped SQL expression.
     @updated				2012-03-14
     */
    public String expression() {
        return _expression;
    }

    /*!
     @method				sql:
     @discussion			This method will wrap the SQL expression.
     @param sql				The SQL expression to be wrapped
     @return				The wrapped SQL expression.
     @updated				2012-03-17
     */
    public static SqlExpression sql(String sql) {
        return new SqlExpression(sql);
    }

    /*!
     @method				prepareConnector:
     @discussion			This method will prepare an alias for an SQL statement.
     @param token			The token to be prepared.
     @return				The prepared token.
     @updated				2012-03-24
     */
    public static String prepareAlias(String token) {
        String pattern = "(?i)[^a-z0-9_ ]";
        if (token != null) {
            token = token.replaceAll(pattern, "");
            token = token.replaceAll("[\\n\\r\\s]+", ""); //trim whitespaceAndNewlineCharacterSet
            token = String.format("[%s]", token);
        }
        return token;
    }

    /*!
     @method				prepareConnector:
     @discussion			This method will prepare a connector for an SQL statement.
     @param token			The token to be prepared.
     @return				The prepared token.
     @updated				2012-03-18
     */
    public static String prepareConnector(String token) {
        if (token != null) {
            if (token.matches("^(and|or)?i$")) {
                throw new IllegalArgumentException("Invalid connector token provided");
            }
            token = token.toUpperCase();
        }
        return token;
    }

    /*!
     @method				prepareEnclosure:
     @discussion			This method will prepare an enclosure character for an SQL statement.
     @param token			The token to be prepared.
     @return				The prepared token.
     @updated				2011-06-25
     */
    public static String prepareEnclosure(String token) {
        if (!(SqlEnclosureOpeningBrace.equals(token) || SqlEnclosureClosingBrace.equals(token))) {
            throw new IllegalArgumentException("Invalid enclosure token provided");
        }
        return token;
    }

    /*!
     @method				prepareIdentifier:
     @discussion			This method will prepare an identifier for an SQL statement.
     @param identifier		The identifier to be prepared.
     @return				The prepared identifier.
     @updated				2012-03-19
     */
    public static String prepareIdentifier(Object identifier) {
        if (identifier instanceof String) {
            StringBuilder buffer = new StringBuilder();
            String[] tokens = ((String)identifier).split("\\.");
            int length = tokens.length;
            String pattern = "(?i)[^a-z0-9_ ]";
            for (int index = 0; index < length; index++) {
                if (index > 0) {
                    buffer.append(".");
                }
                String token = tokens[index];
                if (token.matches("^\\\\s*\\\\*\\\\s*$\"")) {
                    buffer.append("*");
                } else {
                    token = token.replaceAll(pattern, "");
                    token = token.replaceAll("[\\n\\r\\s]+", ""); //trim whitespaceAndNewlineCharacterSet
                    buffer.append(String.format("[%s]", token));
                }
            }
            return buffer.toString();
        } else if (identifier instanceof SqlExpression) {
            return ((SqlExpression)identifier).expression();

        } else if (identifier instanceof SqlStatement) {
            String statement = ((SqlStatement) identifier).statement();
            statement = statement.substring(0, statement.length() - 1);
            statement = String.format("(%s)", statement);
            return statement;
        }
        throw new IllegalArgumentException(String.format("Unable to prepare identifier. '%s'", identifier));
    }

    /*!
     @method				prepareJoinType:
     @discussion			This method will prepare a join type token for an SQL statement.
     @param token			The token to be prepared.
     @return				The prepared token.
     @updated				2012-03-18
     */
    public static String prepareJoinType(String token) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				prepareOperator:type
     @discussion			This method will prepare an operator for an SQL statement.
     @param operator		The operator to be prepared.
     @param type			The type of operator.
     @return				The prepared operator.
     @updated				2012-03-18
     */
    public static String prepareOperator(String operator, String type) {
        throw new UnsupportedOperationException();
    }

    /*!
     @method				prepareSortOrder:
     @discussion			This method will prepare a sort order token for an SQL statement.
     @param descending		This will determine whether the token represents a descending tkoen
                            or an ascending token.
     @return				The prepared sort order token.
     @updated				2011-07-02
     */
    public static String prepareSortOrder(boolean descending) {
        return descending ? "DESC" : "ASC";
    }

    /*!
     @method				prepareSortWeight:
     @discussion			This method will prepare the sort weight for an SQL statement.
     @param weight			This indicates how nulls are to be weighed when comparing with non-nulls.
     @return				The prepared sort weight.
     @updated				2011-11-06
     */
    public static String prepareSortWeight(String weight) {
        if (weight != null) {
            if (!weight.matches("^(first|last)?i$")) {
                throw new IllegalArgumentException("Invalid weight token provided.");
            }
            return weight.toUpperCase();
        }
        return "DEFAULT";
    }

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
    public static String prepareValue(Object value) {
        if (value == null || SqlExpression.NULL.equals(value)) {
            return "NULL";
        } else if (value.getClass().isArray()) {
            StringBuilder buffer = new StringBuilder();
            buffer.append("(");
            for (int i = 0; i < ((Object[])value).length; i++) {
                if (i > 0) {
                    buffer.append(", ");
                }
                buffer.append(prepareValue(((Object[])value)[i]));
            }
            buffer.append(")");
            return buffer.toString();
        } else if (value instanceof Number) {
            // TODO: maybe use %d and %f for integers and floats...
            return String.format("%s", value);
        } else if (value instanceof String) {
            // TODO: maybe use sqlite3_mprintf
            String escapedValue = String.format("'%s'", value);
            return escapedValue;
        } else if (value instanceof Date) {
            DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            return String.format("'%s'", df.format((Date)value));
        } else if (value instanceof SqlExpression) {
            return ((SqlExpression)value).expression();
        } else if (value instanceof SqlSelectStatement) {
            String statement = ((SqlSelectStatement)value).statement();
            statement = statement.substring(0, statement.length() - 1);
            statement = String.format("(%s)", statement);
            return statement;
        }

        throw new IllegalArgumentException(String.format("Unable to prepare value. '%s'", value));
    }
}
