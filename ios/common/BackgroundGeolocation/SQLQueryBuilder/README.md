# Objective-C SQL Query Builder

This Objective-C SQLite project is a lightweight library that offers more than just a set of [SQLite](http://www.sqlite.org/)
wrapper classes.  It is divided up into five parts.  The first part consists of a set of Objective-C classes that handle
communications with an SQLite database.  Inside the "src" folder, these Objective-C classes are further subdivided into five
folders.  The "db" folder (formerly, the "dao" folder) contains an SQLite wrapper class that easily manages the database
connection. The "ext" folder contains some class extensions. The "sql" folder contains a collection of SQL builder classes
that can be used to construct well-formed SQL statements for SQLite via a plethora of convenience methods similar to those
found in LINQ.  Likewise, the "orm" folder has an assortment of classes that can control and manipulate data within an SQLite
database via the Active Record design pattern. And, the "util" folder contains a set of various helper classes.  The
second part consists of an easy-to-read API, which both documents and diagrams each Objective-C class and XML/DTD file.
The third part consists of a BASH script that can be used to generate the necessary ORM models using the SQLite's database
schema.  The fourth part consists of the database configuration files for the SQLite database connection.  The final part
has the schema for handling XML to DDL.

All classes are designed to be used in iPhone/iOS applications.  The classes in the "ARC" branches are compliant with iOS 5's
[automatic reference counting](http://clang.llvm.org/docs/AutomaticReferenceCounting.html).  For projects still using Retains,
Releases, and Autoreleases (i.e. Pre-ARC) use the classes in the "RRA" branches.

## Supported Platforms

- Mac OS X 10.7+
- iOS 4.0+

## Motivation

The goal of this project is to make these classes the "de facto" standard for communicating with SQLite databases on
iPhone/iOS devices.

With the abundance of third-party libraries for Objective-C, it was apparent that a successful SQLite library needs to
be simple to learn and intuitive.  It must also be cleanly written with clear naming conventions and must be well-documented
for too many SQLite libraries are hard to understand and are not user-friendly.  For these reasons, this SQLite library was
written.

## Features

The following is a short-list of some of the features:

* [Automatic reference counting](http://longweekendmobile.com/2011/09/07/objc-automatic-reference-counting-in-xcode-explained/);
* Cleanly wraps-up the sqlite3 C based functions.
* Automatically places the SQLite database in the "Document" directory.
* Allows for read-only databases.
* Provides multi-threading support for asynchronous SQLite database calls;
* Utilizes a PLIST file for configuring SQLite database connections;
* Allows database privileges to be restricted.
* Has an easy to use SQLite database connection pool.
* Capable of executing an SQL statement with one line of code.
* Able to execute more than one SQL statement at a time.
* Has a huge collection of SQL builder classes with methods that mimic their SQL statement equivalents.
* Converts XML to DDL/SQL statements.
* Helps ensure that SQL statements are well-formed.
* Supports all major Objective-C datatypes, including NSNull, NSNumber, NSDecimalNumber, NSString, NSData, and NSDate.
* Sanitizes data using best practices.
* Handles most complex queries and works with raw SQL statements.
* Has a powerful SQLite tokenizer.
* Contains a message digest to hash strings using md2, md4, md5, sha1, sha224, sha256, sha384, and sha512.
* Has a data access layer (DAL) that offers Object Relational Mapping (ORM).
* Data access objects (DAO) handle composite primary keys.
* Via a Bash script, models (i.e. Active Records) can be auto-generated for each table in the SQLite database.
* Handles foreign keys via true lazy loading.
* Requires only those Objective-C classes that are absolutely needed.
* Classes are easily extendible.
* Has clear API documentation generated via [Doxygen](http://www.stack.nl/~dimitri/doxygen/).

## Getting Started

Using these classes in an Xcode project is easy to do.  Here is how:

1. Download the source code via Github as a tarball (i.e. .tar.gz).
2. Navigate to the tarball in Finder.
3. Unarchive the tarball by double-clicking it in a Finder window.
4. Open an Xcode project.
5. Right-click on the "Classes" folder and click on the "Add >> Existing Files..." option.
6. Highlight the files, then click the "Add" button.
7. Check "Copy items into destination group's folder (if needed)".
8. Select "Default" for the "Reference Type".
9. Choose "Recursively create groups for any added folders".
10. Click "Add".

### Required Files

A lot of work has gone into making the classes in this repository as independent as possible; however, a few
dependencies just can't be avoided.  To make life easier, the following SDK import files have been created to
make the implementation process as painless as possible:

* ZIMDaoSdk.h
* ZIMSqlSdk.h
* ZIMOrmSdk.h

Based on which SDK is needed, only those classes listed (i.e. imported) in the SDK import file are needed to be
added to the respective Xcode project.

### Required Frameworks

To use these Objective-C classes in an Xcode project, add the following framework:

* libsqlite3.dylib

### Documentation

All classes are heavily documented using [HeaderDoc](http://developer.apple.com/library/mac/#documentation/DeveloperTools/Conceptual/HeaderDoc/intro/intro.html#//apple_ref/doc/uid/TP40001215-CH345-SW1).
You can get familiar with each class by simply looking at the API or by opening its respective ".h" file.  Similarly,
all XML/DTD files are documented using [DTDDoc](http://dtddoc.sourceforge.net). You can also find more information on
this repository's Wiki.

### Tutorials / Examples

Checkout this SQLite repository's Wiki for a handful of examples.  There, you will find examples on how to make
an SQLite database connection and how to build [DCL, DDL, DML, and TCL commands](http://download.oracle.com/docs/cd/B12037_01/server.101/b10759/statements_1001.htm)
(including Create, Read, Update, and Delete (CRUD) statements).  The Wiki also has tutorials on how to use Object
Relational Mapping (ORM) and how to generate the necessary models (i.e. active records).

### Further Assistance

If you need further assistance in implementing these classes, you can always send an email to oss@ziminji.com with
any questions that you may have about this repository.  Any frequently asked questions (FAQ) will be posted on this
repository's Wiki.

You can also seek assistance via the blogs.  A great Web site for community assistance is [Stack Overflow](http://stackoverflow.com).

## Reporting Bugs & Making Recommendations

Help debug the code in repository by reporting any bugs.  The more detailed the report the better.  If you have a bug-fix
or a unit-test, please create an issue under the "Issues" tab of this repository and someone will follow-up with it as
soon as possible.

Likewise, if you would like to make a recommendation on how to improve the code in this repository, take the time to send
a message so that it can be considered for an upcoming release.  Or, if you would like to contribute to the development of
this Objective-C SQLite repository, go ahead and create a fork.

You can also email any bug-fixes, unit-tests, or recommendations to oss@ziminji.com.

### Known Issues

Usually, code is not posted to this SQLite repository unless it works; however, there are times when some code may get
posted even though it still contains some bugs.  When this occurs, every attempt will be made to list these known bugs
in this README (if they are not already listed under the "Issues" tab).

At the current time, there are no known bugs. However, the "XML to DDL" schema processing is still being developed.

### Updates

This Objective-C SQLite project is updated frequently with bug-fixes and new features.  Be sure to add this repository
to your watch list so that you can be notified when such updates are made.  You can also request email notifications
regarding updates by emailing oss@ziminji.com.

## Future Development

This project is under heavy development.  There are development plans to add:

* Improved functionality to parse "XML to DDL" schema and raw SQLite statements into their SQL builder class equivalents;
* More utilities (e.g. classes to handle validation, filtering, imports, exports, pagination, partitioning, and migration);
* A database encryption layer for password protecting an SQLite database;
* Unit-tests; and,
* Additional tutorials and examples.

Help expand this list with your feedback.

## License (Apache v2.0)

>Copyright 2011-2015 Ziminji
>
>Licensed under the Apache License, Version 2.0 (the "License"); you may not use these files except in compliance with the
>License. You may obtain a copy of the License at:
>
>[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)
>
>Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
>"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific
>language governing permissions and limitations under the License.
