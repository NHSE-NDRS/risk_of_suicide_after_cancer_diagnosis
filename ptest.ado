*Postestimation Commands - v7.5 - 01.08.2013

capture program drop ptest
program define ptest
        version 11, missing
        syntax varlist(fv min=1), [NOshow NOView]

	cap drop ifs
	cap drop com
	cap drop splitat
	cap drop esplit
		
**NULL MODEL**
	
	/*save estimates current model*/
	local xmdline  `e(cmdline)'
	if "`xmdline'" == "" {
	di as err "Null model required for postestimation command."
	di in ye "r(100);"
	exit
	}
	
	/*display mechanic*/
	di in g as smcl "{hline}"
	
	if "`noview'" == "" {
	di in gr %-20s "Test variable(s): " in ye "`varlist'"
	}
	
	gen ifs = regexm("`xmdline'", "if")
	gen com = regexm("`xmdline'", ",")
	
	if ifs == 1 & com == 0 {
	local cmdline "`xmdline' & e(sample)"
	qui `cmdline'
	}
	if ifs == 0 & com == 0 {
	local cmdline "`xmdline' if e(sample)"
	qui `cmdline'
	} 
	if ifs == 0 & com == 1 {
	gen esplit = strpos("`xmdline'", ",")
	qui sum esplit
	local esplt = r(mean)
	local null1 = substr("`xmdline'", 1 , `esplt'-1)
	local null2 = substr("`xmdline'", `esplt', .)
	local cmdline "`null1' if e(sample)`null2'"
	qui `cmdline'
	drop esplit
	}
	if ifs == 1 & com == 1 {
	gen esplit = strpos("`xmdline'", ",")
	qui sum esplit
	local esplt = r(mean)
	local null1 = substr("`xmdline'", 1 , `esplt'-1)
	local null2 = substr("`xmdline'", `esplt', .)
	local cmdline "`null1' & e(sample)`null2'"
	qui `cmdline'
	drop esplit
	}
	qui: est store nullmodel   
	drop ifs
	gen ifs = regexm("`cmdline'", "if")
	*di in gr  "`cmdline'"

	if "`noshow'" == "" {
	di in gr %-20s "Null model: " in ye "`xmdline'"
	}
	
**HETEROGENEITY TEST**
	
	if ifs == 1 & com == 0 {
	generate splitat = strpos("`cmdline'" , "if")
	qui sum splitat
	local splt = r(mean)
	local new = substr("`cmdline'", 1 , `splt'-1)
	local opt = substr("`cmdline'", `splt', .)
	/*save estimates nested model*/
	local xmd:  list new - varlist
	local cmd `xmd' `opt'
	if "`noshow'" == "" {
	di in gr %-20s "Nested model: " in ye "`cmd'"
	}
	}
	
	if ifs == 1 & com == 1 {
	generate splitat = strpos("`cmdline'" , "if")
	qui sum splitat
	local splt = r(mean)
	local new = substr("`cmdline'", 1 , `splt'-1)
	local opt = substr("`cmdline'", `splt', .)
	/*save estimates nested model*/
	local xmd:  list new - varlist
	local cmd `xmd' `opt'
	if "`noshow'" == "" {
	di in gr %-20s "Nested model: " in ye "`cmd'"
	}
	}
	
	if com == 1  & ifs == 0 {
	generate splitat = strpos("`cmdline'" , ",")
	qui sum splitat
	local splt = r(mean)
	local new = substr("`cmdline'", 1 , `splt'-1)
	local opt = substr("`cmdline'", `splt', .)
	/*save estimates nested model*/
	local xmd:  list new - varlist
	local cmd `xmd'`opt'
	if "`noshow'" == "" {
	di in gr %-20s "Nested model: " in ye "`cmd'"
	}
	}
	
	if ifs == 0 & com == 0 {
	local xmd: list cmdline - varlist
	local cmd `xmd'
	if "`noshow'" == "" {
	di in gr %-20s "Nested model: " in ye "`cmd'"
	}
	}
	qui: `cmd' 
		
	/*LRT test P-Heterogeneity*/
	cap qui: lrtest  nullmodel 
	
	qui:local phet: display %9.3f  r(p) 
	cap estadd scalar phet =  r(p):nullmodel //save in p-value in scalar for later use
	
**LINEARITY TEST**
	
	marksample touse    
			
	if `touse'{
	 qui: `cmd'
	}
	qui: est store nullmodel0 
	
	//save estimates to model with linear variates
	local x = subinstr("`varlist'", "i." , "",.)
	if ifs == 1 {
	local cmdl  `"`xmd' `x' `opt'"'
	}
	if com == 1 {
	local cmdl `"`xmd' `x' `opt'"'
	}
	if ifs == 0 & com == 0 {
	local cmdl `"`cmd' `x'"'
	}
	if "`noshow'" == "" {
	di in gr %-20s "Linear model: " in ye "`cmdl'"
	}
	
	if `touse'{
	qui: `cmdl' 
	}
	cap qui: lrtest  nullmodel0
	qui:local plin: display %9.3f  r(p) 
	cap estadd scalar plin =  r(p):nullmodel //save in p-value in scalar for later use
	
**NON-LINEARITY TEST**
	
	qui: `cmdline'
	qui: est store nullmodel 
	
	//save estimates to model with linear variates
	local x = subinstr("`varlist'", "i." , "",.)
	if ifs == 1 {
	local cmdl  `"`xmd' `x' `opt'"'
	}
	if com == 1 {
	local cmdl `"`xmd' `x' `opt'"'
	}
	if ifs == 0 & com == 0 {
	local cmdl `"`cmd' `x'"'
	}
	
	qui: `cmdl' 
	cap qui: lrtest  nullmodel
	qui:local pnlin: display %9.3f  r(p) 
	cap estadd scalar pnlin =  r(p):nullmodel //save in p-value in scalar for later use

**POLYNOMIAL-O(2) TEST**
	
	qui: `cmdline'
	qui: est store nullmodel 
	
	//save estimates to model with linear variates
	local x = subinstr("`varlist'", "i." , "",.)
	cap drop `x'2
	qui: g `x'2 = `x' * `x'
	if ifs == 1 {
	local cmdl  `"`xmd' `x' `x'2 `opt'"'
	}
	if com == 1 {
	local cmdl `"`xmd' `x' `x'2 `opt'"'
	}
	if ifs == 0 & com == 0 {
	local cmdl `"`cmd' `x' `x'2"'
	}
	
	qui: `cmdl' 
	cap qui: lrtest  nullmodel
	qui:local po2lin: display %9.3f  r(p) 
	cap estadd scalar po2lin =  r(p):nullmodel //save in p-value in scalar for later use	
		qui cap drop `x'2

**POLYNOMIAL-O(3) TEST**
	
	qui: `cmdline'
	qui: est store nullmodel 
	
	//save estimates to model with linear variates
	local x = subinstr("`varlist'", "i." , "",.)
	cap drop `x'2
	qui: g `x'2 = `x' * `x'
	cap drop `x'3
	qui: g `x'3 = `x' * `x' * `x'
	if ifs == 1 {
	local cmdl  `"`xmd' `x' `x'2 `x'3 `opt'"'
	}
	if com == 1 {
	local cmdl `"`xmd' `x' `x'2 `x'3 `opt'"'
	}
	if ifs == 0 & com == 0 {
	local cmdl `"`cmd' `x' `x'2 `x'3"'
	}
	
	qui: `cmdl' 
	cap qui: lrtest  nullmodel
	qui:local po3lin: display %9.3f  r(p) 
	cap estadd scalar po2lin =  r(p):nullmodel //save in p-value in scalar for later use	
		qui cap drop `x'3
	
**RESULT**
	
	di as text %-30s "LRT P-Heterogeneity: " as result "`phet'"
	di as text %-30s "LRT P-Linearity: " as result "`plin'"
	di as text %-30s "LRT P-NonLinearity: " as result "`pnlin'"
	di as text %-30s "LRT P-Polynomial(Order-2): " as result "`po2lin'"
	di as text %-30s "LRT P-Polynomial(Order-3): " as result "`po3lin'"
	
	cap drop splitat
	cap drop ifs
	cap drop com
	
	di in g as smcl "{hline}"
	
	//run initial model 
	qui: `xmdline'

end
