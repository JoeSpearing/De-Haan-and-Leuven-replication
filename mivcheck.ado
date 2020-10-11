// -mivcheck- plots cdfs for different miv2's stratified by miv1
// note that the order of arguments matters:
// . mivcheck y miv1 miv2

program mivcheck
syntax varlist [if], * [ifx(string) round(real -1)]
marksample touse

tokenize `varlist'
local y `1'
local miv1 `2'
local miv2 `3'

qui levelsof `miv1' if `touse', local(l1)
qui levelsof `miv2' if `touse', local(l2)	

di as inp                    _col(45) "  strict SD:       weak SD:"
di as inp "H1 for k-1 vs. k" _col(45) "  F_k<F_{k-1}    F_k>F_{k-1}"
di as inp "`miv1' - `miv2'"
foreach i of local l1 {
	foreach j of local l2 {
		if ("`ferest()'" == "") continue
		local k : word 1 of `ferest()'
			qui ksmirnov `y' if `touse' & `miv1'==`i' & inlist(`miv2', `j', `k'), by(`miv2') 
			di as txt "`i' - `j' vs. `k'" _col(40) as res %15.3f 1 - r(p_1) %15.3f r(p_2) _c
			qui count if `y'<. & `touse' & `miv1'==`i' & inlist(`miv2', `j', `k')
			di %10.0g r(N)
	}
qui count if `y'<. & `touse' & `miv1'==`i' & `miv2'<.
di as txt "N `miv1'==`i'" _col(70) as res %10.0g r(N)
}
qui count if `y'<. & `touse' & `miv1'<. & `miv2'<.
di as txt "N Total" _col(70) as res %10.0g r(N)

if ("`graph'" != "") exit

local lbl1 : value label `miv1'
local lbl2 : value label `miv2'

if (`round' > -1) replace `y' = round(`y', `round')

preserve
bysort `miv1' `miv2' : cumul `y' if `touse', gen(_cdf) equal
collapse _cdf if `touse', by(`y' `miv1' `miv2')

// store labels (if any)
foreach l of local l1 {
	capture local m`l' : label `lbl1' `l'
}
foreach l of local l2 {
	capture local n`l' : label `lbl2' `l'
}

qui reshape wide _cdf, i(`y' `miv1') j(`miv2')

// restore labels (if any)
foreach l of local l1 {
	if ("`m`l'" != "") label def `miv1' `l' "`m`l''", modify
}
cap label val `miv1'  `miv1'
foreach l of local l2 {
	cap label var _cdf`l' "`n`l''"
}

if ("`ifx'" != "") local ifx "if `y'`ifx'"

twoway line _cdf* `y' `ifx', by(`miv1', note("")) lpat(dot solid shortdash solid longdash) lwidth(thin thin medthick medthick thick) `options'

end
