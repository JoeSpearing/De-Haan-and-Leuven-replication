# [JLE-2020-3803] [De Haan and Leuven (2020)] Replication files

Data files in this repository
----------------------------
 - nlsy79rawdata.dta: this file contrains raw nlsy79 data
 - familyincome1978.dta: this file contains 
 - NLSY79_analysis_ed.dta: this file contains the data after being cleaned by the stata codes in this repository
 - longtermindex.dta
 - weight94.dta
 
 
 Stata code do files
----------------------------
 - anchecks.do: this creates figures 4, 5, and 13. It checks that the MTS assumptions are reasonable
 - annlsy79.do: attempts to run the main analysis of the paper. There is a bug
 - datanlsy79ed.do: this takes the raw data and converts into NLSY79_analysis_ed.dta
 - grformat.do: not clear what this does. 
 - main.do: runs all other files in sequence
 
Stata code ado files: these are not commented, and I cannot work out which one does what
----------------------------
 - gwmean.ado
 - calc2.ado
  -grcdf.ado
 - grcompare.ado
 - greffect.ado
 - manybmiv.ado
 - manybmts.ado
 - manybmts_cond.ado
 - manybnoass.ado
 - mbound.ado
 - mivcheck.ado

R files
----------------------------
 - partial_de_han_and_Leuven_replication.R: this does what annlsy79.do is supposed to do

How to run this (partial) replication
----------------------------
1) download data files
2) run do files 'datanlsy79ed.do' and 'anchecks.do' to recreate the dataset and initial analysis checks
3) run R code 'partial_de_han_and_Leuven_replication' (this will automatically install the 'foreign', 'haven' and 'ggplot2' pacckages if not already installed)
 
