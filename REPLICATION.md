# [JLE-2020-3803] [De Haan and Leuven (2020)] Validation and Replication results


SUMMARY
-------

> INSTRUCTION: The Data Editor will fill this part out. It will be based on any [REQUIRED] and [SUGGESTED] action items that the report makes a note of. 

> INSTRUCTION: ALWAYS do "Data description", "Code description". If data is present, ALWAYS do "Data checks". If time is sufficient (initial assessment!), do "Replication steps", if not, explain why not.

> INSTRUCTION: leave this in.

> The openICPSR submission process has changed. If you have not already done so, please "Change Status -> Submit to AEA" from your deposit Workspace.


Data description
----------------

### Data Sources

> INSTRUCTIONS: Identify all INPUT data sources. Create a list (and commit the list together with this report) (not needed if filling out the "Data Citation and Information report"). For each data source, list in THIS document presence or absence of source, codebook/information on the data, and summary statistics. Summary statistics and codebook may not be necessary if they are available for public use data. In all cases, if the author of the article points to an online location for such information, that is OK. Check for data citation. IN THIS DOCUMENT, point out only a summary of shortcomings.

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

> INSTRUCTIONS: Most deposits will be at openICPSR, but all need to be checked for complete metadata. Detailed guidance is at [https://aeadataeditor.github.io/aea-de-guidance/data-deposit-aea-guidance.html](https://aeadataeditor.github.io/aea-de-guidance/data-deposit-aea-guidance.html). 

### Requirements 

No data deposit

No README

- [REQUIRED] Produce README and data deposit

### Deposit Metadata

> INSTRUCTIONS: Some of these are specific to openICPSR (JEL, Manuscript Number). Others may or may not be present at other trusted repositories (Dataverse, Zenodo, etc.). Verify all items for openICPSR, check with supervisor for other deposits.

- [ ] JEL Classification (required)
- [ ] Manuscript Number (required)
- [ ] Subject Terms (highly recommended)
- [ ] Geographic coverage (highly recommended)
- [ ] Time period(s) (highly recommended)
- [ ] Collection date(s) (suggested)
- [ ] Universe (suggested)
- [ ] Data Type(s) (suggested)
- [ ] Data Source (suggested)
- [ ] Units of Observation (suggested)

> INSTRUCTIONS: Go through the checklist above, and then choose ONE of the following results:

- [NOTE] openICPSR metadata is sufficient.

or

- [REQUIRED] Please update the openICPSR metadata fields marked as (required), in order to improve findability of your data and code supplement. 

and/or

- [SUGGESTED] We suggest you update the openICPSR metadata fields marked as (suggested), in order to improve findability of your data and code supplement. 

For additional guidance, see [https://aeadataeditor.github.io/aea-de-guidance/data-deposit-aea-guidance.html](https://aeadataeditor.github.io/aea-de-guidance/data-deposit-aea-guidance.html).

Data checks
-----------

Data are present and can be read
Stored in dta forrmat
Data have variable labels attached

Code description
----------------

There are four provided stata do files:
  anchecks.do
  annlsy79.do
  datanlsy79ed.do
  grformat.do

- Program code does not identify which figure is produced by which program or line

- Neither the program codes, nor the README, identify which tables are produced by what program.

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

> - (Windows) by right-clicking on "This PC"

- Stata/MP 15

Replication steps
-----------------

> INSTRUCTIONS: provide details about your process of accessing the code and data.
> Do NOT detail things like "I save them on my Desktop".
> DO describe actions   that you did  as per instructions ("I added a config.do")
> DO describe any other actions you needed to do ("I had to make changes in multiple programs"), without going into detail (the commit log can provide that information)

Example:

1. Downloaded code from URL provided.
2. Downloaded data from URL provided. 
3. Ran code in the order detailed in the main.do file
4. annlsy79.do file did not run

Findings
--------

### Data Preparation Code

- datanlsy79ed.do ran as expected. Produced cleaned data

### Tables

Examples:

- Table 1: Looks the same
- Table 2: (contains no data)
- Table 3: Minor differences in row 5, column 3, 0.003 instead of 0.3

### Figures

> INSTRUCTIONS: Please provide a comparison with the paper when describing that figures look different. Use a screenshot for the paper, and the graph generated by the programs for the comparison. Reference the graph generated by the programs as a local file within the repository.

Example:

- Figure 1: Looks the same
- Figure 2: no program provided
- Figure 3: Paper version looks different from the one generated by programs:

### In-Text Numbers

> INSTRUCTIONS: list page and line number of in-text numbers. If ambiguous, cite the surrounding text, i.e., "the rate fell to 52% of all jobs: verified".

[ ] There are no in-text numbers, or all in-text numbers stem from tables and figures.

[ ] There are in-text numbers, but they are not identified in the code

- Page 21, line 5: Same


Classification
--------------

> INSTRUCTIONS: Make an assessment here.

- [ ] partial reproduction (see above)

### Reason for incomplete reproducibility

> INSTRUCTIONS: mark the reasons here why full reproduciblity was not achieved, and enter this information in JIRA

- [ ] `Code not functional` is more severe than a simple bug: it  prevented the replicator from completing the reproducibility check
