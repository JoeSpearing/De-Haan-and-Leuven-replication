program grcdf
syntax, [xscale(real 1) acol(string)] *
preserve
quietly {
	drop _all
	matrix b = e(b)
	svmat b, n(eqcol)
	g i =_n
	local outvars : coleq b
	local outvars : list uniq outvars
	reshape long `outvars', i(i) j(j) string
	reshape long y_, i(i j) j(x)
	reshape wide y_ , i(x) j(j) string
	replace x = x * `xscale'
}
if ("`acol'" == "") local acol gs12 gs6

myplot y_UB_1 y_LB_1 y_UB_2 y_LB_2 x, `options' col(gs12 gs6) //col("178 24 43" "33 102 172")
	
restore
end
