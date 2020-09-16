# f1
Formula 1 - PostgreSQL Reports Playground

Formula one source data from http://ergast.com/mrd/db/

Modified for compatibility with PostgreSQL from https://github.com/tomredsky/f1db.git

### Setup

####  create schema/tables
* `psql -h 0.0.0.0  -c 'create database f1'`
* `psql -h 0.0.0.0 -d f1 -f f1db_postgres.sql`
* `CREATE EXTENSION tablefunc`
* follow the queries in `f1.sql`
