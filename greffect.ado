program greffect
syntax, [amax(string) amin(string) xscale(real 1) xline(string) acol(string)] *
preserve
quietly {
	drop _all
	matrix b = e(ci90_im) \ e(ci95_im)
	svmat b, n(eqcol)
	g i =_n
	local outvars : coleq b
	local outvars : list uniq outvars
	reshape long `outvars', i(i) j(j) string
	reshape long y_, i(i j) j(x)
	replace x = x * `xscale'
	replace y_ = - y_  // so that we get lower bounds on the effect >=
	reshape wide y_, i(j x) j(i)

	label var y_8 "95% LB CI"
	label var y_4 "90% LB CI"
	label var y_3 "LB"
	if ("`amax'" == "") {
		sum y_3
		local amax = 1.1 * r(max) 
	}
	keep if j=="_2_1"
	g maxy = `amax'
	g lb   = y_3 // original lower bounds
	g miny = y_3 // line through lower bounds
	if ("`amin'" != "") {
		truncvar min `amin' y_4  x y_8 miny y_3
		truncvar min `amin' y_8  x y_4 miny y_3
		truncvar min `amin' miny x y_4 y_8 y_3
		replace y_3 = . if y_3 < float(`amin')   // don't plot bounds below amin
		replace y_3 = . if float(lb)!=float(y_3) // don't plot interpolated bounds
	}
}
if ("`xline'" != "") local xline xline(`xline')
collapse lb maxy miny y_3 y_4 y_8, by(x)
g y0 = 0

if ("`acol'" == "") local acol gs12

twoway ///
	(rarea maxy miny x, fc(`acol') lc(`acol')  cmiss(yes)) ///
	(sc y_3 x, mcol(black) msym(o) msize(small)) ///
	(line miny x, lpat(solid) lc(black) cmiss(yes)) ///
	(line y0 x, lc(black) lpat(solid) lw(vthin)) ///
	(line y_4 y_8 x, lpat(longdash shortdash) lcol(black ..)  cmiss(no ..) `xline') ///
	, yline(0, lpat(solid) lcol(black)) ylabel(,angle(0)) legend(row(1)) ///
	legend(order(2 "Lower Bound (LB)" 1 "[LB, ...)" 5 "90% CI LB"  6 "95% CI LB" )) plotregion(margin(tiny)) `options'

restore
end



program truncvar
args trunc at y x
macro shift 4
unab othervars : `*'

foreach v of var `othervars'{
	tempvar slope`v'
	g `slope`v'' = (`v'[_n + 1] - `v') / (`x'[_n + 1] - `x')

}
tempvar cross new slope
sort `x'
g `cross' = inrange(`at', `y', `y'[_n + 1]) | inrange(`at', `y'[_n + 1], `y')  if _n < _N & `y'[_n + 1]<. & `y'<.
expand `cross' + 1, gen(`new')
sort `x' `new'
g `slope' = (`y'[_n + 1] - `y') / (`x'[_n + 1] - `x')
replace `x' = `x' + (`at' - `y') / `slope'  if `new'
replace `y' = `at' if `new'
replace `y' = - `trunc'( - `at', - `y') if `y'<.
foreach v of var `othervars' {
	replace `v' = `v'[_n - 1] + `slope`v'' * (`x' - `x'[_n - 1]) if `new'
}

end
