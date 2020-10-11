program calc2, eclass
	syntax varlist [if] [fweight aweight iweight pweight /] , [saving(string) at(numlist) reps(integer 999) MEANonly ASSumption(string) svy(varlist) subpop(string) keep(varlist) miny(string) maxy(string) mts(string)]
	marksample touse


	preserve
	if ("`exp'" != "") {
		tempvar wgtvar
		g `wgtvar' = `exp'
		local wopt "w(`exp')"
	}
	keep if `touse'
	keep `varlist' `exp' `svy' `keep'
	tokenize `varlist'
	local outvar `1'
	
	if "`miny'"=="" local miny 0
	if "`maxy'"=="" local maxy 1
	if "`mts'"==""  local mts >

	if ("`meanonly'" == "") {	
		// create outcome variables
		if ("`at'" == "") {
			_pctile `outvar', n(50)
			forvalues i = 1/49 {
				local at `at' `=round(r(r`i'), 1)'
			}
			local at : list uniq at
		}
		qui foreach i of local at {
			gen byte y_`i' = (`outvar'<=`i') if `outvar'<.
			sum y_`i', mean
			if (r(mean)==float(0) | r(mean)==float(1)) drop y_`i' 
		}
		unab outvar : y_*
	}

	if ("`subpop'" != "") local subpop subpop(`subpop')
	if ("`saving'" != "") local saving saving(`saving')

	manyb`assumption' `outvar', `wopt' miny(`miny') maxy(`maxy') mts(`mts')

	if ("`svy'" == "") {
		parallel bs, `saving' reps(`reps') randtype(current): manyb`assumption' `outvar', `wopt' miny(`miny') maxy(`maxy') mts(`mts')
	}
	else {
		svy bootstrap _b, `subpop': manyb`assumption' `outvar', miny(`miny') maxy(`maxy') mts(`mts')
	}

	matrix bc = 2 * e(b) - e(b_bs)
	matrix V  = e(V)

	local outvars : coleq bc
	local outvars : list uniq outvars
	qui foreach y of var `outvars' {		
		foreach i in 1 2 2_1 {
			local  k       = colnumb(bc, "`y':UB_`i'")
			scalar ub`i'   = el(bc, 1, `k')
			scalar seub`i' = sqrt(el(V, `k', `k'))

			local  k       = colnumb(bc, "`y':LB_`i'")
			scalar lb`i'   = el(bc, 1, `k')
			scalar selb`i' = sqrt(el(V, `k', `k'))

			scalar alpha = (ub`i' - lb`i') / max(selb`i', seub`i')

			foreach l in 90 95 { // IMBENS MANSKI CONF INTERVALS
				if missing(alpha) scalar c = .
				else mata : st_numscalar("c", imconf("alpha", `= 1 - `l' / 100'))
				matrix ci = (lb`i' - c * selb`i' \ lb`i' \ ub`i' \ ub`i' + c * seub`i')
				matrix colname ci = _`i'
				matrix coleq ci   = `y'
				capture matrix ci`l'_im = ci`l'_im, ci
				if (_rc) matrix ci`l'_im = ci
			}
		}
	}
	matrix rowname ci90_im = LBci LB UB UBci
	matrix rowname ci95_im = LBci LB UB UBci
	
	ereturn matrix ci90_im = ci90_im
	ereturn matrix ci95_im = ci95_im
	ereturn local outvar   = "`outvar'"
	ereturn local outlvls  = "`p'"

end


mata:

void myeq(todo, p, alpha, siglevel, lnf, g, H)
{
	lnf = - (normal(p[1] + alpha) - normal(-p[1]) - (1 - siglevel))^2
}

real scalar imconf(string scalar nalpha, real scalar siglevel)
{
	S = optimize_init()
	optimize_init_evaluator(S, &myeq())
	optimize_init_params(S, invnormal(1 - siglevel))
	optimize_init_argument(S, 1, st_numscalar(nalpha))
	optimize_init_argument(S, 2, siglevel)
	p = optimize(S)
	return(p)
}

end




