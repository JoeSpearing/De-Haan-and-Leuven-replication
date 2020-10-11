program manybmiv, eclass properties(svyb)
	syntax varlist [if] [fweight aweight iweight pweight] , [Wgtvar(varname)  miny(string) maxy(string) mts(string)]
	marksample touse
	markout `touse' miv* headstart `wgtvar'

	if ("`wgtvar'" != "") local wgt "[aw=`wgtvar']"
	if ("`weight'" != "") local wgt "[`weight'`exp']"

	// we need this because each parallel instance is a new stata session
	set matsize 10000 

	tempname b coef
	qui foreach v of var `varlist' {
		mbound `v' (headstart = miv*) `wgt', miny(`miny') maxy(`maxy') mts(`mts') 

		matrix `b' = e(b)
		local x = subinstr("`: colfullnames e(b)'", ":", "_", .)
		matrix colnames `b' = `x'
		matrix coleq `b' = `v'
		
		capture matrix `coef' = `coef', `b'
		if (_rc) matrix `coef' = `b'
	}
	qui count if `touse'
	ereturn post `coef', esample(`touse') obs(`=r(N)')
	ereturn display
end
