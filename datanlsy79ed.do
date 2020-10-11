clear all
set more off
cap log close
log using datanlsy79ed, replace

insheet using _raw/nlsy79_03_12_2013/nlsy79_03_12_2013.csv, clear
do _raw/nlsy79_03_12_2013/nlsy79_03_12_2013-value-labels

merge 1:1 PUBID using _raw/weight94, keepusing(weight94) nogen
merge 1:1 PUBID using _raw/familyincome1978, nogen
merge 1:1 PUBID using _raw/longtermindex, nogen

g ageatfirstchild = .
lookfor "AGE OF YNGST"
foreach v of var `r(varlist)' {
	local year : word 8 of `: var label  `v''
	if (`year' > 82) exit
	replace ageatfirstchild = min(ageatfirstchild, `year' - birthyear - `v') if `v'>=0	
}
g teenpregnancy = ageatfirstchild < 18

g convicted = R0307800 ==1
g probation = R0310600==1
g sentenced =  R0310900==1


save _dta/nlsy79rawdata, replace

/// head start started in 1965 so only those born 1960 or later could be eligible
*keep if birthyear>=60

// participation in head start measured in 1994, missing codes:
// -5 = not interviewd
// -4 = a valid skip, these are the individuals born before 1960 and who cannot have attended head start
// -2 = dont't know
// -1 = refused to answer 
replace headstart = . if headstart<0

// gen education variables: take highest grade completed in 1994 same year as head start is measured
// in 1994 respondents are between 29 and 34 years old
// highest grade completed measured in 1979 and every survey changes in highest grade completed are recorded
order highestgradecompl*, seq
recode highestgradecompl* (-5/-1=.) (95=0)
egen grades = rmax(highestgradecompl1979-highestgradecompl1994)

gen gradesm = highestgradecompl1979
recode gradesm -5=. -4=. -3=. -2=. -1=. 95=0
forvalues i=80/94 {
	replace gradesm = highestgradecompl19`i' if  highestgradecompl19`i'>0 & highestgradecompl19`i'<90
}


/// MIV's ; education of father and mother
egen maxeduparent = rowmax(highestgradecompl_FATHER highestgradecompl_MOTHER)

recode highestgradecompl_MOTHER (1/11=3) (12=2) (13/max=1) (*=.), gen(mivmom)
recode highestgradecompl_FATHER (1/11=3) (12=2) (13/max=1) (*=.), gen(mivdad)
gen revmivmom = 4 - mivmom
gen revmivdad = 4 - mivdad

recode maxeduparent (0/9=1) (10/11=2) (12=3) (13/15=4) (16=5) (17/20=6), gen(mivparent)
gen mivparent_reverse = 7 - mivparent



// AFQT scores
gen afqt = AFQT_3 / 1000 if AFQT_3>=0

/// hourly wages (in cents) in current or most recent job
replace hourlywage1993  = . if  hourlywage1993<0
replace hourlywage1993  = hourlywage1993
replace hourlywage1994  = . if  hourlywage1994<0
replace hourlywage1994  = hourlywage1994

/// recode income variables to missing if <0
/// recode wage income from missing to zero if individual indicates that he or she worker 0 weeks
foreach i of numlist 1979(1)1992 1993(2)2009 {
	replace totwageinc`i'          = . if totwageinc`i'<=0  // zeros start only in 1994
	replace totnetfamincome`i'     = . if totnetfamincome`i'<0
	replace povertystatus`i'       = . if povertystatus`i'<0
	replace totincfarmbusiness`i'  = . if totincfarmbusiness`i'<0
	gen totwageincwithzeros`i'     = totwageinc`i'
	replace totwageincwithzeros`i' = 0 if totwageinc`i'==. & weeksworked`i'==0
	egen totearnings`i'            = rowtotal(totwageinc`i' totincfarmbusiness`i'), missing
	egen totearningswithzeros`i'   = rowtotal(totwageincwithzeros`i' totincfarmbusiness`i'), missing
}

// net family income
egen avrfaminc9395 = rowmean(totnetfamincome1993 totnetfamincome1995)
egen avrfaminc0305 = rowmean(totnetfamincome2003 totnetfamincome2005)

// yearly wage income in 2000 dollars
gen wageinc1991_2000 = totwageinc1991 * (172.2 / 136.2)    
gen wageinc1992_2000 = totwageinc1992 * (172.2 / 140.3)  
gen wageinc1993_2000 = totwageinc1993 * (172.2 / 144.5)
gen wageinc1995_2000 = totwageinc1995 * (172.2 / 152.4)
gen wageinc1997_2000 = totwageinc1997 * (172.2 / 160.5)
gen wageinc1999_2000 = totwageinc1999 * (172.2 / 166.6)

egen avrwagein31_35_60 = rowmean(wageinc1991_2000 wageinc1992_2000 wageinc1993_2000 wageinc1995_2000) if birthyear==60
egen avrwagein31_35_61 = rowmean(wageinc1992_2000 wageinc1993_2000 wageinc1995_2000) if birthyear==61
egen avrwagein31_35_62 = rowmean(wageinc1993_2000 wageinc1995_2000 wageinc1997_2000) if birthyear==62
egen avrwagein31_35_63 = rowmean(wageinc1995_2000 wageinc1997_2000) if birthyear==63
egen avrwagein31_35_64 = rowmean(wageinc1995_2000 wageinc1997_2000 wageinc1999_2000) if birthyear==64

gen avrwageinc31_35 = .
replace avrwageinc31_35 = avrwagein31_35_60 if birthyear==60
replace avrwageinc31_35 = avrwagein31_35_61 if birthyear==61
replace avrwageinc31_35 = avrwagein31_35_62 if birthyear==62
replace avrwageinc31_35 = avrwagein31_35_63 if birthyear==63
replace avrwageinc31_35 = avrwagein31_35_64 if birthyear==64

drop avrwagein31_35_*

egen avrwageinc9395 = rowmean(totwageinc1993 totwageinc1995)
egen avrwageinc0305 = rowmean(totwageinc2003 totwageinc2005)

recode employmentstatus* (-5/-1=.) (1=1) (*=0)
rename employmentstatus* empl*

d totwageinc*
rename totwageinc* wageinc*

keep PUBID SAMPLE_ID weight94 gender otherpreschool headstart *miv* grades* afqt birthyear ///
	hourlywage1993 hourlywage1994 avrfaminc9395 avrfaminc0305 avrwageinc31_35 avrwageinc9395 avrwageinc0305 empl* ///
	totearnings1993 totearnings1995 totearnings2003 totearnings2005 ///
	totearningswithzeros1993 totearningswithzeros1995 totearningswithzeros2003 totearningswithzeros2005 ///
	wageinc1993* wageinc1995* wageinc2003* wageinc2005* ///
	wageincwithzeros1993 wageincwithzeros1995 wageincwithzeros2003 wageincwithzeros2005 ///
	totnetfamincome1993 totnetfamincome1995 totnetfamincome2003 totnetfamincome2005 ///
	weeksworked1993 weeksworked1995 weeksworked2003 weeksworked2005 nrsiblings maxeduparent race totnetfamincome1978 ///
	ageatfirstchild

// all amounts in 1000s
foreach v of var *inc* *earn* {
	replace `v' = `v' / 1000
}

rename hourlywage* wage*
rename avrfaminc* finc*
rename totnetfamincome* finc*
rename avrwageinc* wageinc*
rename totearnings* earnings*
rename weeksworked* weeks*

replace finc1978 = . if finc1978<0
label var finc1978 "Family Income, 1978"


compress
save _dta/NLSY79_analysis_ed, replace
