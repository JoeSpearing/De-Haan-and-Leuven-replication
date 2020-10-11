program define _gwmean
	syntax newvarname =/exp [if] [in] [, BY(varlist)] Weight(varname)
	quietly {
		tempvar touse 
		gen byte `touse' = 1 `if' `in'
		sort `touse' `by'
		by `touse' `by': gen `typlist' `varlist' = sum((`weight') * (`exp')) / sum((`weight') * ((`exp') < .)) if `touse'==1
		by `touse' `by': replace `varlist' = `varlist'[_N]
	}
end
