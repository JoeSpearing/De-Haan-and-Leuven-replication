clear all
set r on
set more off
set scheme s2mono
set matsize 2500

cd"C:\Users\jms41081\Documents\labour_econ\replication"

cap log close
log using anchecks, text replace

// NLSY
use _dta/NLSY79_analysis_ed, clear
replace headstart = 0 if birthyear < 60
g noheadstart = headstart==0

//rename some variables
label var wageinc1993 "Wage Income"
label var grades "Years of education"
label var finc1978 "Family income, 1978"

//create some dummies
recode maxeduparent ///
	(0/9   = 1 "Less than High School") ///
	(10/11 = 2 "Some High School")      ///
	(12    = 3 "High School")           ///
	(13/15 = 4 "College (1-3 years)")   ///
	(16/20 = 5 "College (4+ years)") (*=.), gen(revmivparent5m)

//loval assigns strings to lcoal macro names
local main revmivparent5m<. & headstart<. & birthyear>=60
	
local all_otherpreincl 1

local all          otherpreschool!=1
local men         `all' & gender==1
local women       `all' & gender==2
local hispa       `all' & race==1
local black       `all' & race==2
local white       `all' & race==3
local headstart   `all' & headstart==1
local noheadstart `all' & headstart==0


g mivall = 1
label var mivall "Sample"
label def mivall 1 "Pre-headstart cohorts" // wrong, but only for the labelling of graphs
label val mivall mivall

// CHECKS ON MIVs
// -mivcheck- plots cdfs for different miv2's stratified by miv1
// note that the order of arguments matters:
// . mivcheck y miv1 miv2
local miv2md revmivmom revmivdad
local miv2dm revmivdad revmivmom
local par5m  mivall    revmivparent5m

local xlabwageinc1993 xlabel(0(10)100)
local xlabgrades      xlabel(4(2)20)

local ifxgrades >=4
local optpar5m subtitle(, size(zero) margin(zero) nobox)

local rowspar5m  2
local rowsmiv2md 1
local rowsmiv2dm 1

local mivcheck birthyear<60 & revmivparent5m<.
replace otherpreschool = 0 if birthyear<60


// FIGURE 9
local samplewageinc1993 `mivcheck'
local samplegrades      `mivcheck'
local samplefinc1978    `main'
local titlewageinc1993  "Pre-headstart cohorts"
local titlegrades       "Pre-headstart cohorts"
local titlefinc1978     "Headstart cohorts"
local ytitlewageinc1993 "F{sub:Y(0)}( {&gamma} | race )"
local ytitlegrades      "F{sub:Y(0)}( {&gamma} | race )"
local ytitlefinc1978    "F{sub:Y}( {&gamma} | race )"
recode race (1=3 "Hispanic") (2=2 "black") (3=1 "white"), gen(xrace)

//this creates some graphs
foreach v  of var finc1978 wageinc1993 grades  {
    label def mivall 1 "`title`v''", modify // wrong, but only for the labelling of graphs
	mivcheck `v' mivall xrace if `sample`v'' & `all', ///
		lcol(black ..) ylabel(, angle(0)) ///
		xtitle("`: var label `v'' ({&gamma})") ///
		ytitle(`ytitle`v'') ///
		legend(region(lcolor(white)) row(1)) ///
		by(,graphregion(fcolor(white) lcolor(white)) scale(1.3)) ///
		subtitle(, fcolor(white) lcolor(white)) ///
		ylabel(0 1) name(`v', replace)  lw(medthick ..)  xsize(4) ysize(4)

		qui gr export _res/selection_byrace_`v'.pdf, replace
}


// SINGLE MIV


// make the legend
mivcheck grades mivall revmivparent5m if `mivcheck' & `all', ///
	xtitle(Years of education ({&gamma})) ///
	lcol(black ..) ylabel(, angle(0)) ///
	ytitle("F{sub:Y(0)}({&gamma})") ylabel(0 1) ///
	legend(region(lcolor(white)) colfirst) scheme(s2mono) ///
	subtitle(, size(zero) margin(zero) nobox) ///
	xlabel(4(2)20) ///
	by(, scale(1.2)  graphregion(fcolor(white) lcolor(white))) ///
	subtitle(, fcolor(white) lcolor(white))
gr export _res/legendmivcheck.eps, replace


foreach miv in par5m {
foreach v of var grades wageinc1993 {
	foreach sample in all men women white black hispa {
			di as inp "`miv', `v', `sample'"
			mivcheck `v' ``miv'' if `mivcheck' & ``sample'', ///
				xtitle(`: var label `v'' ({&gamma}), size(large)) ///
				lcol(black ..) ylabel(, angle(0)) ///
				ytitle("F{sub:Y(0)}( {&gamma} )", size(vlarge)) ylabel(0 1) ///
				legend(off) scheme(s2mono) ///
				`opt`miv'' `xlab`v'' ifx(`ifx`v'') ///
				by(, rows(`rows`miv'') scale(1.2) legend(off) graphregion(fcolor(white) lcolor(white))) ///
				subtitle(, fcolor(white) lcolor(white))
			qui gr export _res/`v'_`sample'_check`miv'_nolegend.pdf, replace
		}
	}
}


////////////////
// DOUBLE MIV //
////////////////
label def revmiv 1 "Some High School" 2 "High School" 3 "College (1+)"
label val revmivmom revmiv
label val revmivdad revmiv

// make legend
mivcheck grades `miv2md' if `mivcheck' & `all', ///
	xtitle(Years of education ({&gamma})) ///
	lcol(black ..) ylabel(, angle(0)) ///
	ytitle("F{sub:Y(0)}({&gamma})") ylabel(0 1) ///
	scheme(s2mono) ///
	xlabel(4(2)20) ifx(>=4) xsize(6) ysize(2) ///
	legend(rows(1) region(lcolor(white)) nocolfirst) ///
	by(, rows(1) scale(2)  ///
	graphregion(fcolor(white) lcolor(white))) ///
	subtitle(, fcolor(white) lcolor(white))
gr export _res/legendmiv2check.eps, replace


label def revmivmom 1 "Mother: Some High School" 2 "Mother: High School" 3 "Mother: College (1+)"
label def revmivdad 1 "Father: Some High School" 2 "Father: High School" 3 "Father: College (1+)"
label val revmivmom revmivmom
label val revmivdad revmivdad

// do all checks
foreach miv in miv2md miv2dm {
foreach v of var grades wageinc1993 {
	foreach sample in all {
			di as inp "`miv', `v', `sample'"
			mivcheck `v' ``miv'' if `mivcheck' & ``sample'', ///
				xtitle(`: var label `v'' ({&gamma})) ///
				lcol(black ..) ylabel(, angle(0)) ///
				ytitle("F{sub:Y(0)}( {&gamma} )") ylabel(0 1) ///
				legend(off) scheme(s2mono) ///
				`xlab`v'' ifx(`ifx`v'') xsize(6) ysize(2) ///
				by(, rows(`rows`miv'') scale(2) legend(off)  ///
				graphregion(fcolor(white) lcolor(white))) ///
				subtitle(, fcolor(white) lcolor(white))
			qui gr export _res/`v'_`sample'_check`miv'_nolegend.pdf, replace
		}
	}
}

// MTS CHECK
preserve
expand 2, gen(_new)
replace revmivparent5m = 99 if _new
label def revmivparent5m 99 "All (unconditional)", add
label def noheadstart 1 "Non-participants" 0 "Head Start participants"
label val noheadstart noheadstart

foreach sample in all all_otherpreincl men women white black hispa {
		di "sample = `sample'"
		mivcheck finc1978 revmivparent5m noheadstart if `main' & ``sample'', ///
			xtitle("Family Income ( {&gamma} )") lcol(black ..) ylabel(, angle(0)) ///
			ytitle("Pr( Family Income {&le} {&gamma} | MIV)") ///
			legend(region(lcolor(white))) scheme(s2mono) ///
			by(, graphregion(fcolor(white) lcolor(white))) subtitle(, fcolor(white) lcolor(white)) ///
			ylabel(0 1) legend(order(1 "Head Start participants" 2 "Non-participants"))

		gr export _res/finc1978_`sample'_check_mts.pdf, replace
}

restore

log close
