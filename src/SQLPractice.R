# SQL Practice
# Author: Isaiah Steinke
# Last Modified: February 17, 2023
# Written, Tested, and Debugged in R v.4.2.1

# We'll use the "sqldf" package so that we can call SQL queries on locally
# created dataframes.

# Load libraries/packages
library(sqldf) # v.0.4-11

# Set working directory
setwd("D:/GitHub/SQL-Practice")

# Load datasets/tables
# We'll retain the full table names to practice aliasing. Further, we will keep
# the default setting for "stringsAsFactors = FALSE" in read.csv(). Hence, I
# won't explicitly call this option/flag.
uscitycoords <- read.csv("data/uscitycoords.csv", header = TRUE)
worldcitycoords <- read.csv("data/worldcitycoords.csv", header = TRUE)
unitedstates <- read.csv("data/unitedstates.csv", header = TRUE)
statecodes <- read.csv("data/statecodes.csv", header = TRUE)
worldcountries <- read.csv("data/worldcountries.csv", header = TRUE)
countries <- read.csv("data/countries.csv", header = TRUE)

#===============================================================================

# Query 1: Display the coordinates of U.S. cities located north of Shanghai,
# China.
sqldf("SELECT *
       FROM uscitycoords AS usc, worldcitycoords AS w
       WHERE w.City = 'Shanghai' AND w.Country = 'China' AND
             usc.Latitude > w.Latitude
      ")

# The resulting output table repeats the information for Shanghai, so we should
# clean it up a bit.
# Get the latitude for Shanghai
sqldf("SELECT *
       FROM worldcitycoords
       WHERE City = 'Shanghai' AND Country = 'China'
      ")

# It's not likely that I need to include the country in the WHERE clause, but
# this would make it more robust in the future in case another city called
# Shanghai in a different country is added to worldcitycoords.
# Cleaner output
sqldf("SELECT usc.City, usc.State, usc.Latitude, usc.Longitude
       FROM uscitycoords AS usc, worldcitycoords AS w
       WHERE w.City = 'Shanghai' AND w.Country = 'China' AND
             usc.Latitude > w.Latitude
      ")

#===============================================================================

# Query 2: Find the coordinates of cities for U.S. states that have
# populations greater than that of Belgium but less than that of Australia.

# Solution used on homework
sqldf("SELECT usc.City, usc.State, usc.Latitude, usc.Longitude,
              us.Population
       FROM uscitycoords AS usc, unitedstates AS us, statecodes AS sc,
            worldcountries AS wc
       WHERE wc.Country = 'Belgium' AND sc.State = us.Name AND
             sc.Code = usc.State AND us.Population > wc.Population
       INTERSECT
       SELECT usc.City, usc.State, usc.Latitude, usc.Longitude,
              us.Population
       FROM uscitycoords AS usc, unitedstates AS us, statecodes AS sc,
            worldcountries AS wc
       WHERE wc.Country = 'Australia' AND sc.State = us.Name AND
             sc.Code = usc.State AND us.Population < wc.Population
      ")

# Different solution
sqldf("SELECT usc.City, usc.State, usc.Latitude, usc.Longitude,
              us.Population
       FROM uscitycoords AS usc, unitedstates AS us, statecodes AS sc
       WHERE sc.State = us.Name AND sc.Code = usc.State
             AND us.Population > (SELECT Population
                                  FROM worldcountries
                                  WHERE Country = 'Belgium')
             AND us.Population < (SELECT Population
                                  FROM worldcountries
                                  WHERE Country = 'Australia')
       ")

# The latter solution should be better since the database system will not need
# to create two sets of results and then find the common entries between them.
# I used system.time() to time the two queries, but the times are similar.

#===============================================================================

# Query 3: Find the capital cities nearest each capital in "worldcitycoords" 
# (find capitals in "countries").

# Solution I used on the homework with some edits to remove SAS-only syntax.
system.time(
sqldf("SELECT w1.City, w1.Country, w1.Latitude, w1.Longitude,
              w2.City, w2.Country, w2.Latitude, w2.Longitude,
              SQRT(POWER((w1.Latitude - w2.Latitude), 2) +
                   POWER((w1.Longitude - w2.Longitude), 2)) AS Distance
       FROM worldcitycoords AS w1, worldcitycoords AS w2
       WHERE w1.City <> w2.City
             AND Distance = (SELECT MIN(SQRT(POWER((w3.Latitude - w4.Latitude), 2)
                                    + POWER((w3.Longitude - w4.Longitude), 2)))
                             FROM worldcitycoords AS w3, worldcitycoords AS w4
                             WHERE w3.City = w1.City
                                   AND w3.Country = w1.Country
                                   AND w3.City <> w4.City
                                   AND w3.City IN (SELECT c1.Capital
                                                   FROM countries AS c1
                                                   WHERE w3.Country = c1.Name)
                                   AND w4.City IN (SELECT c2.Capital
                                                   FROM countries AS c2
                                                   WHERE w4.Country = c2.Name))
      ")
)

# This query takes awhile to run (108.62 s), although it's only using one
# core/thread on my computer. This is most likely because it's calculating
# a lot of distances that it doesn't need to in "worldcitycoords" (we're only
# interested in capital cities, after all). Further, there are some redundant
# entries in the output since the precision of the latitude and longitude
# is not very high (only whole numbers). Thus, some capitals have more than one
# other capital/city that is the same distance away. Finally, there are also
# some errors, e.g., Belize, Belize is not a capital city. (For these errors,
# I'm thinking that I don't have enough constraints on some of the subqueries.)

# I'm guessing that it would be better to first construct a table of capital
# cities and their coordinates from "worldcitycoords" and "countries" and then
# use that table to calculate distances to find the closest capital city.

capitals <- sqldf("SELECT c.Capital, c.Name, w.Latitude, w.Longitude
                   FROM worldcitycoords AS w, countries AS c
                   WHERE w.Country = c.Name
                         AND w.City = c.Capital
                  ")

# Using system.time(), this query takes very little time (0.02 s).

system.time(
sqldf("SELECT cp1.Capital, cp1.Name, cp1.Latitude, cp1.Longitude,
              cp2.Capital, cp2.Name, cp2.Latitude, cp2.Longitude,
              SQRT(POWER((cp1.Latitude - cp2.Latitude), 2) +
                   POWER((cp1.Longitude - cp2.Longitude), 2)) AS Distance
       FROM capitals AS cp1, capitals AS cp2
       WHERE cp1.Capital <> cp2.Capital
             AND Distance = (SELECT MIN(SQRT(POWER((cp3.Latitude - cp4.Latitude), 2)
                                    + POWER((cp3.Longitude - cp4.Longitude), 2)))
                             FROM capitals AS cp3, capitals AS cp4
                             WHERE cp3.Capital = cp1.Capital
                                   AND cp3.Name = cp1.Name
                                   AND cp3.Capital <> cp4.Capital)
      ")
)

# This query is also quite fast (0.25 s). The total time is 0.27 s, which is
# quite a speedup from my homework solution above (a factor of more than 400!).

# The problem is that requires two separate queries or one query and some local
# processing of the data. To combine this into one whole query that's a bit
# more elegant, we'll use a common table expression (CTE) using the WITH clause
# (following the discussion at https://learnsql.com/blog/reasons-to-use-ctes/).
# Note that I've purposely used the name to "world_capitals" to ensure that
# the "capitals" table that I created earlier is not called during the query.

system.time(
sqldf("WITH world_capitals AS
            (SELECT c.Capital, c.Name, w.Latitude, w.Longitude
             FROM worldcitycoords AS w, countries AS c
             WHERE w.Country = c.Name
                   AND w.City = c.Capital)
       
       SELECT cp1.Capital, cp1.Name, cp1.Latitude, cp1.Longitude,
              cp2.Capital, cp2.Name, cp2.Latitude, cp2.Longitude,
              SQRT(POWER((cp1.Latitude - cp2.Latitude), 2) +
                   POWER((cp1.Longitude - cp2.Longitude), 2)) AS Distance
       FROM world_capitals AS cp1, world_capitals AS cp2
       WHERE cp1.Capital <> cp2.Capital
             AND Distance = (SELECT MIN(SQRT(POWER((cp3.Latitude - cp4.Latitude), 2)
                                    + POWER((cp3.Longitude - cp4.Longitude), 2)))
                             FROM world_capitals AS cp3, world_capitals AS cp4
                             WHERE cp3.Capital = cp1.Capital
                                   AND cp3.Name = cp1.Name
                                   AND cp3.Capital <> cp4.Capital)
      ")
)

# The execution time is roughly the same as the two separate queries
# (0.25–0.27 s).