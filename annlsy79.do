capture log close
log using annlsy79, text replace

clear all
set matsize 2500
set seed 633866292 // from random.org
parallel setclusters 4

// NLSY79
use _dta/NLSY79_analysis_ed, clear
keep if birthyear >= 60 // the cohorts who could go to HS
drop if headstart==.

label var wageinc1993 "Wage Income"
label var grades "Years of schooling"

recode maxeduparent ///
	(0/9   = 5 "Less than High School") ///
	(10/11 = 4 "Some High School")      ///
	(12    = 3 "High School")           ///
	(13/15 = 2 "College (1-3 years)")   ///
	(16/20 = 1 "College (4+ years)") (*=.), gen(mivparent5m)

// define some locals with sample cuts
local all          otherpreschool!=1
local cross       `all' & SAMPLE<10
local men         `all' & gender==1
local women       `all' & gender==2
local hispa       `all' & race==1
local black       `all' & race==2
local white       `all' & race==3
local headstart   `all' & headstart==1
local noheadstart `all' & headstart==0


// TABLE 1: descr statistics
preserve

replace finc1978 = finc1978 * 1000
g age94 = 94 - birthyear
g white = race==3
g black = race==2
g hispa = race==1
tab mivparent5m, g(revpar)

// calculate descriptive stats on background characteristics for sample with 
// nonmissing years of schooling
foreach v of var headstart age94 gender white black hispa revpar* finc1978  {
	replace `v' = . if missing(grades)
}

foreach weight in 1 weight94 {
	di
	di as res "> weight = `weight'"
	di as txt "{hline 105}"
	local adj -
	foreach head in variable all headstart noheadstart white black hispa {
		di as txt %`adj'15s "`head'" _c
		local adj
	}
	di
	di as txt "{hline 105}"
	foreach v of var headstart age94 gender white black hispa revpar* finc1978 grades wageinc1993 {
		di as txt "`v'" _c
		foreach stat in mean N {
			di _col(15) _c
			foreach sample in all headstart noheadstart white black hispa {
				qui sum `v' if mivparent5m<. & ``sample'' [aw=`weight']
				if ("`stat'"=="N" & !inlist("`v'", "grades", "wageinc1993")) continue
				di as res %15.2f r(`stat') _c
			}
			di
		}
	} // varlist
	di as txt "{hline 105}"
} // weight

restore // TABLE 1

// ANALYSIS
replace headstart = headstart + 1

// -calc2- wants discrete nr on support
replace wageinc1993 = wageinc1993 * 10 
// support where we will bound cdf
local atwageinc1993 at(10(5)200 210(10)650)
local atgrades at(8(1)20)

// ATE, weights
foreach v of var grades wageinc1993 {
	//foreach sample in all cross men women black white hispa {	
	foreach sample in cross {	
		// main results
		calc2 `v' headstart mivparent5m if ``sample'' [aw=weight94], `at`v'' saving(_res/`v'_`sample'_par5mweight, replace)
		estimates save _res/`v'_`sample'_par5mweight, replace
		calc2 `v' headstart mivparent5m if ``sample'', `at`v'' saving(_res/`v'_`sample'_par5m, replace)
		estimates save _res/`v'_`sample'_par5m, replace
	}
}

// ATE
replace wageinc1993 = wageinc1993 / 10 // we want it here in 1000$
local fgrades %8.2f
local fwageinc1993 %8.1f
g mivz = - mivparent5m // more (years of schooling/inc) is better now: need to reverse miv and mts
foreach sample in all men women white black  hispa {	
	di "`sample'" _col(10) _c
	foreach v of var grades wageinc1993 {
		qui sum `v'
		qui calc2 `v' headstart mivz if ``sample'', meanonly  miny(`=r(min)') maxy(`=r(max)') mts(<) 
		mat b95 = e(ci95_im)
		di `f`v'' b95[1,3] `f`v'' b95[2,3] `f`v'' b95[4,3] `f`v'' b95[3,3] "   " _c
		//qui mbound `v' (headstart=mivz)  if ``sample'', miny(0) maxy(`max`v'') mts(<) 
		//di %10.2f _b[LB:2_1] %10.2f _b[UB:2_1] _c
	}
	di
}
drop mivz
replace wageinc1993 = wageinc1993 * 10 


// extra analysis with separate assumptions
local sample all
foreach v of var grades wageinc1993 {
	//foreach ass in noass miv mts mts_cond {	
	foreach ass in mts {	
		// main results
		calc2 `v' headstart mivparent5m if ``sample'', `at`v'' ass(`ass')
		estimates save _res/`v'_`sample'_par5m_`ass', replace
	}
}

local weight [aw=weight94]
local noweight

foreach w in noweight weight {
	foreach v of var grades wageinc1993 {
		foreach sample in all men women black white hispa {	
			// main results
			calc2 `v' headstart mivparent5m if ``sample'' ``w'', `at`v'' saving(_res/`v'_`sample'_par5m`w', replace)
			estimates save _res/`v'_`sample'_par5m`w', replace

			// what follows only for the whole sample
			if ("`sample'" != "all") continue

			// 2-MIV
			calc2 `v' headstart mivdad mivmom if `all' ``w'', `at`v''
			estimates save _res/`v'_all_miv2`w', replace

			// other preschool included
			calc2 `v' headstart mivparent5m ``w'', `at`v''
			estimates save _res/`v'_otherpreincl_par5m`w', replace
			// other preschool included
			calc2 `v' headstart mivdad mivmom ``w'', `at`v''
			estimates save _res/`v'_otherpreincl_miv2`w', replace
		}
	}
}

log close
