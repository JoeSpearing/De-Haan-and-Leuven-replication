capture program drop grcompare
program grcompare
syntax anything, keep(string) [if(string) scale(real 1)] *
preserve
local i 0
qui foreach estimate in `anything' {
		est use _res/`estimate'
		drop _all
		matrix b = e(ci90_im) \ e(ci95_im)
		local more = "`c(more)'"
		if ("`more'" == "on") set more off
		svmat b, n(eqcol)
		set more `more'
		g i =_n
		local outvars : coleq b
		local outvars : list uniq outvars
		reshape long `outvars', i(i) j(j) string
		reshape long y_, i(i j) j(x)
		replace y_ = - y_ 
		reshape wide y_ , i(j x) j(i)
		keep if j=="_2_1"
		rename (y_3 y_4 y_5) (y_UB y_CI90 y_CI95)
		label var y_CI95 "95% CI"
		label var y_CI90 "90% CI"
		label var y_UB "UB"
		keep x y_`keep'*
		g estimate = `++i'
		tempfile f`i'
		save `f`i''
}
qui forvalues j = `=`i'-1'(-1)1 {
		append using `f`j''
}
qui reshape wide y*, i(x) j(estimate)
forvalues j = 1/`i' {
	label var y_`keep'`j' "`: word `j' of `anything''"
}
qui replace x = x / `scale'

twoway conn y_* x `if', yline(0, lpat(solid) lcol(black)) legend(row(1)) `options'
restore
end
