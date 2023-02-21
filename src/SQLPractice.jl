# SQL Practice
# Author: Isaiah Steinke
# Last Modified: February 20, 2023
# Written, Tested, and Debugged in Julia v.1.8.1

# We'll use the DuckDB package to query a database created in memory.
# The various datasets will be read in as dataframes and added as views to
# this database.

# Import libraries/packages
using CSV, DataFrames, DuckDB

# Set working directory
workdir = "D:/GitHub/SQL-Practice"

# Read in data needed for queries
worldcitycoords = CSV.read(joinpath(workdir, "data/worldcitycoords.csv"), DataFrame)
countries = CSV.read(joinpath(workdir, "data/countries.csv"), DataFrame)
oilprod = CSV.read(joinpath(workdir, "data/oilprod.csv"), DataFrame)
worldtemps = CSV.read(joinpath(workdir, "data/worldtemps.csv"), DataFrame)

# Create a new in-memory database
my_db = DBInterface.connect(DuckDB.DB)

# Register dataframes as views in the database
# I'm going to alias the names of these dataframes here so they won't need to
# be aliased in the SQL queries.
DuckDB.register_data_frame(my_db, worldcitycoords, "wcc")
DuckDB.register_data_frame(my_db, countries, "c")
DuckDB.register_data_frame(my_db, oilprod, "op")
DuckDB.register_data_frame(my_db, worldtemps, "wt")

# ==============================================================================

# Query 1: Find the coordinates and capitals of oil-producing countries.

q1 = "SELECT wcc.City, wcc.Country, wcc.Latitude, wcc.Longitude
      FROM wcc, c
      WHERE wcc.Country in (SELECT Country
                            FROM op)
            AND c.Capital = wcc.City
            AND c.Name = wcc.Country
     "

q1_out = DBInterface.execute(my_db, q1)
print(q1_out)

# ==============================================================================

# Query 2: Find all of the cities in "worldcitycoords" and "worldtemps" (no
# duplicates).

# On the homework, I wrote out two different queries that should achieve the
# same results.

q2_1 = "SELECT wcc.City, wcc.Country
        FROM wcc
        FULL JOIN wt
            ON wcc.City = wt.City AND wcc.Country = wt.Country
        ORDER BY wcc.Country ASC
       "

q2_1_out = DBInterface.execute(my_db, q2_1)
print(q2_1_out)

q2_2 = "SELECT City, Country
        FROM wcc
        UNION
        SELECT City, Country
        FROM wt
        ORDER BY Country ASC
       "

q2_2_out = DBInterface.execute(my_db, q2_2)
print(q2_2_out)

# The first query returns two rows as "missing," although I am not sure why.
# Let's add the results of these queries to the in-memory database and see which
# rows are missing.

DuckDB.register_data_frame(my_db, DataFrame(q2_1_out), "test1")
DuckDB.register_data_frame(my_db, DataFrame(q2_2_out), "test2")

q2_3 = "SELECT *
        FROM test2
        WHERE NOT EXISTS (SELECT *
                          FROM test1
                          WHERE test1.City = test2.City
                          AND test1.Country = test2.Country)
       "
result = DBInterface.execute(my_db, q2_3)
print(result)

# The two cities are Hong Kong, China and Geneva, Switzerland. These cities are
# in "worldtemps" but not "worldcitycoords." I am not quite sure why this
# happens. It appears that the city and country are not propagating to the
# output when FULL JOIN is used.

# ==============================================================================

# Query 3: Find cities present in "worldcitycoords" but not "worldtemps."

q3 = "SELECT City, Country
      FROM wcc
      EXCEPT
      SELECT City, Country
      FROM wt
     "

q3_out = DBInterface.execute(my_db, q3)
print(q3_out)

# There are 212 records in "worldcitycoords" and 59 in "worldtemps." This means
# that there are 212 - 59 = 153 records in the result if all of the cities in
# "worldtemps" are in "worldcitycoords." However, we know that there are two
# cities in "worldtemps" that are not in "worldcitycoords" from Query 2. Hence,
# the result of Query 3 should have 155 records (which is does).
