# SQL Practice
# Author: Isaiah Steinke
# Last Modified: March 2, 2023
# Written, Tested, and Debugged in Python v3.9.12

# We'll use SQLAlchemy to set up a local database in memory, add tables to this
# database, and then run queries.

# Import libraries/packages
import pandas as pd # v1.4.2
from sqlalchemy import create_engine # v1.4.32

# Create local database
engine = create_engine("sqlite:///:memory:")

# Read in data needed for queries
worldcitycoords = pd.read_csv('data/worldcitycoords.csv')
worldtemps = pd.read_csv('data/worldtemps.csv')

# Insert data as tables into the database. Pandas has a method "to_sql" to
# push dataframes to the database as tables. Again, we'll alias the names here
# so they won't need to be aliased in the queries.
worldcitycoords.to_sql('wcc', engine, if_exists = 'replace')
worldtemps.to_sql('wt', engine, if_exists = 'replace')

# ==============================================================================

# Query 1: Find cities in both "worldcitycoords" and "worldtemps."

q1 = """
        SELECT wcc.City, wcc.Country
        FROM wcc, wt
        WHERE wcc.City = wt.City 
              AND wcc.Country = wt.Country
        ORDER BY wcc.City
     """
pd.read_sql(q1, engine)

# There are 57 cities that are in both "worldcitycoords" and "worldtemps."
# Alternatively, we can use INTERSECT.

q1 = """
        SELECT City, Country
        FROM wcc
        INTERSECT
        SELECT City, Country
        FROM wt
     """
pd.read_sql(q1, engine)

# ==============================================================================

# Query 2: Find unique cities from "worldcitycoords" or "worldtemps" but not in
# both tables.

q2 = """
        SELECT City, Country
        FROM wcc
        EXCEPT SELECT City, Country FROM wt
        UNION
        SELECT City, Country
        FROM wt
        EXCEPT SELECT City, Country FROM wcc
     """
pd.read_sql(q2, engine)

# Only outputs the result of the second query in the UNION, i.e., the two
# unique cities in "wt" (Geneva and Hong Kong).

q3 = """
        SELECT City, Country
        FROM wcc
        EXCEPT SELECT City, Country
               FROM wt
     """
pd.read_sql(q3, engine)

# The output here returns 155 rows/cities.

q4 = """
        SELECT City, Country
        FROM wt
        EXCEPT SELECT City, Country
               FROM wcc
     """
pd.read_sql(q4, engine)

# As stated above, the output returns two rows/cities. Thus, the union of these
# queries should return 155 + 2 = 157 cities. Let's do a simpler query to see
# if the UNION is working as I think it is.

q5 = """
        SELECT City, Country
        FROM wcc
        UNION
        SELECT City, Country
        FROM wt
     """
pd.read_sql(q5, engine)

# This correctly returns 214 rows/cities. The table "wcc" has 212 rows, and
# "wt" has 59 rows. Because UNION inherently filters out duplicates, the
# resulting union of the two tables should be 212 + 2 = 214. However, we want
# to return these results without the cities common to both tables. (There are
# 57 cities in common between the two tables, so the resulting table should
# have 214 - 57 = 157 rows.)

# So, the problem seems to be the use of EXCEPT in both subqueries. My original
# homework solution used parentheses around each of the subqueries in q2 above.
# Apparently, the SAS sql procedure must allow this or is programmed to
# process queries slightly differently. Adding the parentheses in this manner
# to q2 results in an error, as the parentheses are not allowed (this was
# cross-checked with code in R as well; same result). I think the lesson is
# that SAS allows some improper SQL code to be valid, as seen in some of the
# other queries I've rewritten in the R and Julia scripts.

# Using more proper SQL syntax (i.e., only one EXCEPT clause that applies after
# the UNION), we can obtain the intended results by merging the two tables 
# (without duplicates) and then subtracting the common cities.

q6 = """
        SELECT City, Country
        FROM wcc
        UNION
        SELECT City, Country
        FROM wt
        EXCEPT SELECT wcc.City, wcc.Country
               FROM wcc, wt
               WHERE wcc.City = wt.City AND wcc.Country = wt.Country
     """
pd.read_sql(q6, engine)

# This query returns 157 rows, as expected.