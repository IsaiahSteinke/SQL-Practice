/* SAS code for extracting datasets from sql.cpo file used in Homework 3 for */
/* MATH 678. Unfortunately, this file cannot be  directly read by programs   */
/* other than SAS (as far as I know). I'll use proc export to create *.csv   */
/* files.                                                                    */
/* Last Modified: January 28, 2023 using SAS Studio (online)                 */

/* Import datasets/tables from SAS cport file after uploading to SAS server. */
proc cimport library = Work infile = "/home/u63182256/sasuser.v94/sql.cpo";
run; quit;

/* Export datasets */
proc export data=work.cityreport
     outfile="/home/u63182256/sasuser.v94/cityreport.csv"
     dbms=csv 
     replace;
run;

proc export data=work.continents
     outfile="/home/u63182256/sasuser.v94/continents.csv"
     dbms=csv 
     replace;
run;

proc export data=work.countries
     outfile="/home/u63182256/sasuser.v94/countries.csv"
     dbms=csv 
     replace;
run;

proc export data=work.densities
     outfile="/home/u63182256/sasuser.v94/densities.csv"
     dbms=csv 
     replace;
run;

proc export data=work.extremetemps
     outfile="/home/u63182256/sasuser.v94/extremetemps.csv"
     dbms=csv 
     replace;
run;

proc export data=work.features
     outfile="/home/u63182256/sasuser.v94/features.csv"
     dbms=csv 
     replace;
run;

proc export data=work.newpop
     outfile="/home/u63182256/sasuser.v94/newpop.csv"
     dbms=csv 
     replace;
run;

proc export data=work.oilprod
     outfile="/home/u63182256/sasuser.v94/oilprod.csv"
     dbms=csv 
     replace;
run;

proc export data=work.oilsrvs
     outfile="/home/u63182256/sasuser.v94/oilsrvs.csv"
     dbms=csv 
     replace;
run;

proc export data=work.postalcodes
     outfile="/home/u63182256/sasuser.v94/postalcodes.csv"
     dbms=csv 
     replace;
run;

proc export data=work.statecodes
     outfile="/home/u63182256/sasuser.v94/statecodes.csv"
     dbms=csv 
     replace;
run;

proc export data=work.unitedstates
     outfile="/home/u63182256/sasuser.v94/unitedstates.csv"
     dbms=csv 
     replace;
run;

proc export data=work.uscitycoords
     outfile="/home/u63182256/sasuser.v94/uscitycoords.csv"
     dbms=csv 
     replace;
run;

proc export data=work.worldcitycoords
     outfile="/home/u63182256/sasuser.v94/worldcitycoords.csv"
     dbms=csv 
     replace;
run;

proc export data=work.worldcountries
     outfile="/home/u63182256/sasuser.v94/worldcountries.csv"
     dbms=csv 
     replace;
run;

proc export data=work.worldtemps
     outfile="/home/u63182256/sasuser.v94/worldtemps.csv"
     dbms=csv 
     replace;
run;

/* Note: Not all datasets were exported. I did not export tables with no     */
/* data (i.e., no rows) and those that only contained a few entries that     */
/* did not appear to be related to the other data tables (e.g., REFEREE).    */