clear all
set more off
set matsize 1000

// global options
local grades       legend(off) scale(1.5) xtitle("Years of education ({&gamma})", size(medlarge) ) ylabel( , labsize(medlarge)) xlabel(8(2)18, labsize(medlarge)) graphregion(fcolor(white) lcolor(white)) legend(region(lcolor(white))) ytitle(, size(large))
local wageinc1993  legend(off) scale(1.5) xtitle("Wage Income ({&gamma})", size(medlarge))   ylabel( , labsize(medlarge)) xlabel(0(10)60, labsize(medlarge)) graphregion(fcolor(white) lcolor(white)) legend(region(lcolor(white))) ytitle(, size(large)) xscale(.1)
local permwsal     xtitle("Permanent Income ({&gamma})", size(medlarge))   ylabel( , labsizemed(large)) xlabel(0(10)60, labsize(medlarge)) graphregion(fcolor(white) lcolor(white)) legend(region(lcolor(white))) ytitle(, size(large))

local scale_grades      amax(0.12) amin(-.1) ylabel(-0.10(0.05)0.12, angle(0) format(%4.2f)) ytitle(F{sub:Y(0)}({&gamma}) - F{sub:Y(1)}({&gamma})) 
local scale_wageinc1993 amax(0.12) amin(-.1) ylabel(-0.10(0.05)0.12, angle(0) format(%4.2f)) ytitle(F{sub:Y(0)}({&gamma}) - F{sub:Y(1)}({&gamma}))
local scale_permwsal    amax(0.12) amin(-.1) ylabel(-0.10(0.05)0.12, angle(0) format(%4.2f)) ytitle(F{sub:Y(0)}({&gamma}) - F{sub:Y(1)}({&gamma})) 

local scale_grades_base  amax(0.12) amin(-.10) ylabel(-0.10(0.05)0.12, angle(0) format(%4.2f)) ytitle(F{sub:Y(0)}({&gamma}) - F{sub:Y(1)}({&gamma})) 
local scale_grades_all   amax(0.04) amin(-.04) ylabel(-0.04(0.02)0.04, angle(0) format(%4.2f)) ytitle(F{sub:Y(0)}({&gamma}) - F{sub:Y(1)}({&gamma})) 
local scale_grades_otherpreincl   amax(0.04) amin(-.04) ylabel(-0.04(0.02)0.04, angle(0) format(%4.2f)) ytitle(F{sub:Y(0)}({&gamma}) - F{sub:Y(1)}({&gamma})) 

local cdfscale_grades      ylabel(0(0.2)1, angle(0) format(%4.1f)) ytitle(F{sub:Y(h)}({&gamma})) legend(order(1 "LB/UB F{sub:Y(0)}" 3 "LB/UB F{sub:Y(1)}"))
local cdfscale_wageinc1993 ylabel(0(0.2)1, angle(0) format(%4.1f)) ytitle(F{sub:Y(h)}({&gamma})) legend(order(1 "LB/UB F{sub:Y(0)}" 3 "LB/UB F{sub:Y(1)}"))
local cdfscale_permwsal    ylabel(0(0.2)1, angle(0) format(%4.1f)) ytitle(F{sub:Y(h)}({&gamma})) legend(order(1 "LB/UB F{sub:Y(0)}" 3 "LB/UB F{sub:Y(1)}"))

local weight weight
local noweight

local xlinewageinc1993 xline(7518 11631) xscale(.1)

// FIG A8?
local sample all
local miv par5m
foreach ass in noass miv mts mts_cond {
	foreach y in grades wageinc1993 {
		local scale_grades `scale_grades_base'
		if ("`sample'" == "all") local scale_grades `scale_grades_all'
		capture est use _res/`y'_`sample'_`miv'``w''_`ass'
		if (_rc) continue
		//greffect, `scale_`y'' ``y'' acol(bluishgray)
		//gr export _fig_slides/`y'_`sample'_`miv'``w''_`ass'_effect_nolegend.pdf, replace
		grcdf, `cdfscale_`y'' ``y'' 
		gr export _fig_slides/`y'_`sample'_`miv'``w''_`ass'_nolegend.pdf, replace
	}
}


foreach w in weight noweight {
	foreach miv in par5m miv2 {
		foreach y in grades wageinc1993 {
			foreach sample in all men women white black hispa otherpreincl {
				local scale_grades `scale_grades_base'
				if ("`sample'" == "all") local scale_grades `scale_grades_all'
				if ("`sample'" == "otherpreincl") local scale_grades `scale_grades_otherpreincl'
				capture est use _res/`y'_`sample'_`miv'``w''
				if (_rc) continue
				greffect, `scale_`y'' ``y'' acol(bluishgray)
				gr export _fig_slides/`y'_`sample'_`miv'``w''_effect_nolegend.pdf, replace
				grcdf, `cdfscale_`y'' ``y'' 
				gr export _fig_slides/`y'_`sample'_`miv'``w''_nolegend.pdf, replace
			}
		}
	}
}



// make 2 legends
local grades legend(symxsize(*.6)) legend(rows(2)) scale(1.5) xtitle("Years of schooling ({&gamma})") xlabel(8(2)18) graphregion(fcolor(white) lcolor(white)) legend(region(lcolor(white))) scheme(s2mono)
est use _res/grades_all_par5m
grcdf, `cdfscale_grades' `grades'
gr export _fig_slides/legendcdf.eps, replace
greffect, `scale_grades' `grades'
gr export _fig_slides/legendeffect.eps, replace
