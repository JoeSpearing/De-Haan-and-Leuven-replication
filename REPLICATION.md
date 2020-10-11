# [JLE-2020-3803] [De Haan and Leuven (2020)] Validation and Replication results


SUMMARY
-------

Data description
----------------

### Data Sources

- [ ] Data files mentioned, provided. File names listed below
  - familyincome1978.dta
  - longtermindex.dta
  - weight94.dta

### Analysis Data Files

- [ ] Analysis data files mentioned, provided. File names listed below.
  - nlsy79rawdata.dta
  - NLSY79_analysis_ed.dta

Data deposit
------------

### Requirements 

No data deposit at openICPSR

No README

- [REQUIRED] Produce README and data deposit

### Deposit Metadata

- [NOTE] openICPSR metadata is sufficient/nonexistent


Data checks
-----------

Data are present and can be read
Stored in dta forrmat
Data have variable labels attached

Code description
----------------

There are four provided stata do files:
  - anchecks.do
  - annlsy79.do
  - datanlsy79ed.do
  - grformat.do
  - main.do (nests all other do files in it)

Program code does not identify which figure is produced by which program or line

Neither the program codes, nor the README, identify which tables are produced by what program.

Stated Requirements
---------------------

- [ ] No requirements specified



Actual Requirements, if different
---------------------------------


- [ ] Software Requirements 
  - [ ] Stata
    -command: parallel
  
> [REQUIRED] Please amend README to contain complete requirements. 

Computing Environment of the Replicator
---------------------

- Stata/MP 15

Replication steps
-----------------

1. Downloaded code from URL provided.
2. Downloaded data from URL provided. 
3. Ran code in the order detailed in the main.do file
4. annlsy79.do file did not run

Findings
--------

### Data Preparation Code

- datanlsy79ed.do ran as expected. Produced cleaned data

### Tables


### Figures

- Figure 4: Looks the same
- Figure 5: Looks the same
- Figure 13: Looks the same

Other figures: program not provided, or program mulfunctioned

### In-Text Numbers

[ ] There are in-text numbers, but they are not identified in the code




Classification
--------------

- [ ] partial reproduction: large parts of the paper cannot be replicated

### Reason for incomplete reproducibility

> INSTRUCTIONS: mark the reasons here why full reproduciblity was not achieved, and enter this information in JIRA

- [ ] `Code not functional`. There is a bug in one of the ADO files (not clear which one) which prevents the code from running
