*! version 1.0.6 --- 19sep2018 --- Edwin Leuven (e.leuven@gmail.com)
program mbound, eclass 

	_vce_parserun mbound, noothervce unparfirsteq equal unequalfirsteq : `0'
	
	if "`s(exit)'" != "" {
		syntax anything [if] [in] [fweight aweight iweight pweight /], [im] *
		if ("`im'"!="") qui imconfint
		ereturn local cmdline `"mbound `0'"'
		exit
	}

	if replay() {
	di "2"
		if "`e(cmd)'" != "mbound" {
			error 301
		}
		ereturn display
		exit
	}

	mbound_estimate `0'

	local cmdline `"mbound `0'"'
	local cmdline : list retokenize cmdline
	ereturn local cmdline `"`cmdline'"'

end



program mbound_estimate, eclass
syntax anything [if] [in] [fweight aweight iweight pweight /], [im miny(string) maxy(string) mtr(string) mts(string) GRaph fast unstack eopt(string) ncells(integer -1) *]  

capture assert inlist("`mts'", "", ">", "<")
if (_rc) {
	di as error "`mts' is an invalid value for option MTS: Specify either > or <"
	exit 198
}

capture assert inlist("`mtr'", "", ">", "<")
if (_rc) {
	di as error "`mtr' is an invalid value for option MTR: Specify either > or <"
	exit 198
}

quietly {
	_iv_parse `anything'
	local y `s(lhs)'
	local d `s(endog)'
	local x `s(exog)'
	local miv `s(inst)'
	if ("`d'" == "`miv'") {
		local miv
	}
	if ("`d'" == "") {
		tokenize `x'
		local d `1'
		macro shift
		local x `*'
	}
	if ("`d'" == "") di as error "No endogenous variable specified."

	marksample touse
	markout `touse' `s(lhs)' `s(inst)' `s(exog)' `s(endog)'
	
	if ("`miny'"=="" | "`maxy'"=="") {
		qui sum `y' if `touse', mean
		if ("`miny'"=="") local miny = r(min)
		if ("`maxy'"=="") local maxy = r(max)
	} 

	preserve
	keep if `touse'
	if ("`x'"=="") {
		tempvar x
		g byte `x' = 1
	}

	tempvar wgt
	if ("`exp'" == "") {	
		g double `wgt' = 1
		local weight aweight
	}
	else {
		g double `wgt' = `exp'
	}
	
	// start bounds calculations
	tempvar lb ub my
	bys `x' `miv' `d' : egen `my' = wmean(`y'), w(`wgt')
	gen `lb' = .
	gen `ub' = .
	levelsof `d', local(dlevels)
	foreach j of local dlevels {
		tempvar myj y0lb xlb y0ub xub
		if ("`mts'"!="")  by `x' `miv' : egen `myj' = wmean(cond(`d' == `j', `y', .)), w(`wgt')

		gen `y0lb' = cond(`d' == `j', `my', `miny') // lower bound: Worst-case (no ass.)
		if ("`mtr'"!="") replace `y0lb' = `my'  if !(`d' `mtr' `j') & (`my'  > `y0lb')
		if ("`mts'"!="") replace `y0lb' = `myj' if  (`d' `mts' `j') & (`myj' > `y0lb')
		by `x' `miv' : egen `xlb' = wmean(`y0lb'), w(`wgt')
		replace `lb' = `xlb' if `d'==`j'

		gen `y0ub' = cond(`d' == `j', `my', `maxy') // upper bound: Best-case (no ass.)
		if ("`mtr'"!="") replace `y0ub' = `my'  if  (`d' `mtr' `j') & (`my'  < `y0ub')
		if ("`mts'"!="") replace `y0ub' = `myj' if !(`d' `mts' `j') & (`myj' < `y0ub')
		by `x' `miv' : egen `xub' = wmean(`y0ub'), w(`wgt')
		replace `ub' = `xub' if `d'==`j'

		capture drop `myj'
		capture drop `y0lb' `xlb' `y0ub' `xub'
	}

	tempname n 
	collapse `y' `lb' `ub' (rawsum) `n' = `wgt' [`weight' = `wgt'], by(`d' `x' `miv') fast

	if (`ncells' < 0) { // calculate nr of cells ourselves
		local ncells 1
		tempname nlevels
		foreach v in `d' `x' `miv' {
			mata : st_numscalar("`nlevels'", length(uniqrows(st_data(., "`v'"))))
			local ncells = `ncells' * `nlevels'
		}
	}

	capture assert _N == `ncells', fast
	if (_rc) {
		di as error "Cannot calculate bounds because of empty cells"
		exit 111
	}

	// repeat to take max/min for miv_1 < k & ... & miv_M < j
	local nrepeat `: word count `miv''
	forvalues repeat = 1 / `nrepeat' {  
		foreach miv0 in `miv' {
			local xmiv : list miv - miv0
			sort `d' `x' `xmiv' `miv0'
			by `d' `x' `xmiv' : replace `lb' = max(`lb', `lb'[_n - 1])
			gsort `d' `x' `xmiv' - `miv0'
			by `d' `x' `xmiv' : replace `ub' = min(`ub', `ub'[_n - 1])
		}
	}

	tempvar ny
	gen `ny' = `n'
	if ("`miv'"!="") {
		bysort `x' `miv' : replace `n' = sum(`n')
		bysort `x' `miv' : replace `n' = `n'[_N]
	}
	replace `y' = `y' * `ny'
	collapse  `lb' `ub' (rawsum) `y' `ny' [aw=`n'], by(`d') fast
	replace `y' = `y' / `ny'

	// collect results and return in a nice way
	if ("`graph'" != "") noi twoway (rcap `ub' `lb' `d') (sc `y' `d'), `options'

	tostring `d', gen(CF)
	gen ETS = `y'
	gen LB  = `lb'
	gen UB  = `ub'
	local ubmin = `maxy' - `miny'
	local lbmax = -`ubmin'
	forvalues i = 2 / `=_N' {
		set obs `=_N + 1'
		replace CF  = CF[`i'] + "_" + CF[`=`i' - 1'] in `=_N'
		replace LB  = max(`lbmax', `lb'[`i'] - `ub'[`=`i' - 1']) in `=_N'
		replace UB  = min(`ubmin', `ub'[`i'] - `lb'[`=`i' - 1']) in `=_N'
		replace ETS = `y'[`i'] - `y'[`=`i' - 1'] in `=_N'
	}
	tempname res b b0
	mkmat ETS LB UB, mat(`res') rownames(CF)
	foreach r in ETS LB UB {
		matrix `b0' = `res'[1..., "`r'"]'
		matrix coleq `b0' = `r'
		capture matrix `b' = `b', `b0'
		if (_rc) matrix `b' = `b0'
	}
	
	restore
	
	ereturn post `b', depname(`y') esample(`touse')
	ereturn scalar N_cells = `ncells'
}

if ("`unstack'"!="") estout, unstack  mlabels(, none) `eopt' ///	
	title("Outcome variable: `y'")
else ereturn display

if ("`mts'" != "") di as txt "MTS: " as res "`mts'"
if ("`mtr'" != "") di as txt "MTR: " as res "`mtr'"
if ("`miv'" != "") di as txt "MIV: " as res "`miv'"

end



program imconfint, eclass

	// bias correction
	tempname bc ub lb seub selb c alpha ci
	matrix `bc' = 2 * e(b) - e(b_bs)

	local treat   : coln `bc'
	local treat   : list uniq treat
	foreach i in `treat' {
		local  k      = colnumb(`bc', "UB:`i'")
		scalar `ub'   = el(`bc', 1, `k')
		scalar `seub' = el(e(se), 1, `k')

		local  k      = colnumb(`bc', "LB:`i'")
		scalar `lb'   = el(`bc', 1, `k')
		scalar `selb' = el(e(se), 1, `k')

		scalar `alpha' = (`ub' - `lb') / max(`selb', `seub')

		foreach l in 90 95 { // IMBENS MANSKI CONF INTERVALS
			if missing(`alpha') scalar `c' = .
			else mata : st_numscalar("`c'", imconf("`alpha'", `= 1 - `l' / 100'))
			matrix `ci' = (`lb' - `c' * `selb' \ `lb' \ `ub' \ `ub' + `c' * `seub')
			matrix colname `ci' = _`i'
			matrix coleq `ci'   = `e(depvar)'
			capture matrix ci`l'_im = ci`l'_im, `ci'
			if (_rc) matrix ci`l'_im = `ci'
		}
	}

	matrix rowname ci90_im = LBci LB UB UBci
	matrix rowname ci95_im = LBci LB UB UBci
	
	ereturn matrix ci90_im = ci90_im
	ereturn matrix ci95_im = ci95_im

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

