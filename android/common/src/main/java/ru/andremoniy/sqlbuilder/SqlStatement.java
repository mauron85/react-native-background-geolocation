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

interface SqlStatement {
    /*!
     @method				statement
     @discussion			This method will return the SQL statement.
     @return				The SQL statement that was constructed.
     @updated				2011-04-02
     */
    String statement();
}