**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Cumulative risks of suicide calculations
**********************************************************************

	
*------------------------------------------------------------------------------------
*Create one dataset per cancersite
*------------------------------------------------------------------------------------	

	use "$data/x-suicide-e3-1899" , clear	
	foreach i in 3 4 6 7 19 21 22 25 28 32 {	
		preserve

		keep if cancergroup2==`i'
		
		local j1 = "bladder" 
		local j3 = "cup" 
		local j4 = "cns"
		local j6 = "colorectal" 
		local j7 = "headneck"
		local j15 "kidney"
		local j18 "liver"
		local j19 "lung"
		local j21 "mesothelioma"
		local j22 "myeloma"
		local j24 "nhl"
		local j25 "oesophagus"
		local j28 "pancreas"
		local j32 "stomach"
		
		save "$data/x-suicide-st-j`i'", replace
		restore
	}
	
	
*------------------------------------------------------------------------------------
*Calculate expected numbers of deaths by attained age
*------------------------------------------------------------------------------------	

	foreach j in 3 4 6 7 19 21 22 25 28 32 {	
		
		global i = `j'
		
		use "$data/x-suicide-st-j$i", clear
		
	* Stset by attained age:	
		stset dox , fail(suicide==1) origin(dob) enter(doe) scale(365.25) id(id) exit(suicide==1 time d(30Aug2017))
		drop if _st==0
		
	* stsplit -- want to group by age and calendar year groups

		stsplit ageband, at(0 (5)90 130) after(time=dob)

		stsplit yeargrp, after(time=d(1/1/1995)) at(0(1)22)
		replace yeargrp = yeargrp + 1995	

		sort sex ageband yeargrp

	* Merge with external reference rates

		merge m:1 sex ageband yeargrp using "$genpop/x-suicide-poprate" , assert(2 3) keep(3)
		assert _merge!=1
		drop if _merge!=3
		drop _merge
		
	* Calculate expected numbers of deaths using population rates

		gen E_suicide = (_t-_t0) * (poprate / 100000)	
		gen stpoprate = poprate / 100000
		
	* This updates the variable based on the stsplit -- overall have a lot more observations as have split the data 	
		qui bysort id (_t):  gen _dsuicide =  _d==1 & suicide==1 & _n==_N
		lab val _dsuicide yn
		gen pyrs = (_t-_t0)
		
		
	* Subdivide expected deaths by age at cancer diagnosis	
		
		stexpect conditional, ratevar(stpoprate) out($data\x-expcuminc-aa-$i, replace) at(0(1)100) method(2) npoints(100)

		use "$data\x-expcuminc-aa-$i", clear
		gen suicide_exp = (1 - conditional) * 100

	*	twoway line suicide_exp t_exp
		
		*rena t_exp _t

		save "$data\x-expcuminc-aa-$i", replace
		
*------------------------------------------------------------------------------------
*Calculate observed number of deaths by attained age and graph of observed versus expected overall without competing risks
*------------------------------------------------------------------------------------	

	use "$data/x-suicide-st-j$i", clear
		
	*Sort out Cause of Death as per WHO rules - 1 patient listed as suicide but this is incorrect
	replace suicide=0 if patientid == pseudo32515
		
	* Create a variable for outcome	(1 = death by suicide, 2 = other cause of death)
		cap drop competcod
		gen competcod = 0 
		replace competcod = 2 if (dead == 1 & dod < d(30Aug2017))
		replace competcod = 1 if (dead == 1 & suicide == 1 & dod < d(30Aug2017)) 
		
	* Stset the data by attained age
		stset dox , fail(competcod==1) origin(time dob) enter(time doe) scale(365.25) id(id) exit(time d(30Aug2017))
		*drop if _st!=1		
		
	*generate cumulative survival using sts package
		sts gen surv2 = s lower = lb upper = ub
		cap drop cuminc
		gen cuminc = (1-surv2) * 100 if competcod == 1
		gen cuminclower = (1- lower) * 100 if competcod == 1
		gen cumincupper = (1- upper) * 100 if competcod == 1
		sum cuminc cuminclower cumincupper
		ren cuminc CI
		ren cuminclower CIub
		ren cumincupper CIlb

		*local i = 1
	* join in the expected cumulative survial calculated above
		append using "$data\x-expcuminc-aa-$i"

	* replace competing cause of death as suicide if not missing expected suicide 
		replace competcod=1 if suicide_exp!=.
		replace t_exp = _t if competcod==1 & t_exp==.
		
		keep CI CIlb CIub t_exp competcod suicide_exp
		
		
		*rena CI CI$i
		*rena CIlb CIlb$i
		*rena CIub CIub$i
		*rena suicide_exp suicide_exp$i
		
		
		local j1 = "bladder" 
		local j3 = "cup" 
		local j4 = "cns"
		local j6 = "colorectal" 
		local j7 = "headneck"
		local j15 "kidney"
		local j18 "liver"
		local j19 "lung"
		local j21 "mesothelioma"
		local j22 "myeloma"
		local j24 "nhl"
		local j25 "oesophagus"
		local j28 "pancreas"
		local j32 "stomach"
		
		gen cancertype = "`j$i'"
		
		keep if competcod==1
		
	*	twoway line suicide_exp CI CIlb CIub t_exp, sort
		
		save "$data\cr-graph-$i", replace
	
	}
*------------------------------------------------------------------------------------
*Combine all graphs
*------------------------------------------------------------------------------------			


	use "$data\cr-graph-3", clear
	foreach j in 4 6 7 19 21 22 25 28 32 {
		append using "$data\cr-graph-`j'"
		}
		
	gen id = 1 if cancertype == "bladder" 
	replace id = 3 if cancertype == "cup" 
	replace id = 4 if cancertype == "cns"
	replace id = 6 if cancertype == "colorectal" 
	replace id = 7 if cancertype == "headneck"
	replace id = 15 if cancertype == "kidney"
	replace id = 18 if cancertype == "liver"
	replace id = 19 if cancertype == "lung"
	replace id = 21 if cancertype == "mesothelioma"
	replace id = 22 if cancertype == "myeloma"
	replace id = 24 if cancertype == "nhl"
	replace id = 25 if cancertype == "oesophagus"
	replace id = 28 if cancertype == "pancreas"
	replace id = 32 if cancertype == "stomach"
	
	label define cancer 1 "Bladder" 3 "Cancer of Unknown Primary" 4 "Central Nervous System" 6 "Colorectal" 7 "Head & neck" 15 "Kidney" 18 "Liver" ///
	19 "Lung" 21 "Mesothelioma" 22 "Multiple Myeloma" 24 "NHL" 25 "Oesophagus" 28 "Pancreas" 32 "Stomach"
	label values id cancer

	
*	twoway line  suicide_exp1 suicide_exp2 suicide_exp3 suicide_exp4 suicide_exp5 CI1 CI2 CI3 CI4 CI5  t_exp if t_exp>20, ///
*	sort xlab(20(5)100) c(J J J J J) clp(l l l l l dash_dot dash longdash shortdash longdash_dot) clc(gs12 gs12 gs12 gs12 gs12 blue green red orange maroon)  ///
*	xtitle("Attained Age") ytitle("Cumulative Mortality of Suicide (%)") 	///
*	legend(order(1 "Exp: Bladder" 2 "Exp: Colorectal" 3 "Exp: Head and Neck" 4 "Exp: Lung" 5 "Exp: NHL" 6 "Obs: Bladder" 7 "Obs: Colorectal" 8 "Obs: Head and Neck" 9 "Obs: Lung" 10 "Obs: NHL") ///
*	size(vsmall) cols(5) ring(1) pos(6) region(lstyle(none)))  graphregion(color(white)) bgcolor(white)

* one graph with a legend
	local forlab: value label id
		
	foreach j in 3 {
		
		local label: label `forlab' `j'
		di "`label'"
		
		twoway line suicide_exp CIlb CI CIub t_exp if id == `j' & t_exp>40 & t_exp<81,sort xlab(40(10)80) ylab(0(2)8) clp (l dot longdash dot) clc(gs12 blue blue blue) ///
		graphregion(color(white)) bgcolor(white)  ///
		legend(order(1 "General population" 2 "Confidence interval" 3 "Cancer population") size(small) cols(3) ring(1) pos(6) region(lstyle(none))) ///
		subtitle("`label'")  ///
		xtitle("") ytitle("") ///
		saving($results\cummortality_`j', replace)
		
		
	}
	
	local forlab: value label id
		
	foreach j in 4 6 7 19 21 22 25 28 32 {
		
		local label: label `forlab' `j'
		di "`label'"
		
		twoway line suicide_exp CIlb CI CIub t_exp if id == `j' & t_exp>40 & t_exp<81,sort xlab(40(10)80) ylab(0(2)8) clp (l dot longdash dot) clc(gs12 blue blue blue) ///
		graphregion(color(white)) bgcolor(white) legend(off) subtitle("`label'")  ///
		xtitle("") ytitle("") ///
		saving($results\cummortality_`j', replace)
	}
	
	*Create a blank graph to put the squares of the graphs in good places
	twoway line suicide_exp CIlb CI CIub t_exp if id == 3 & t_exp>40 & t_exp<81,sort xlab(40(10)80) ylab(0(2)8) clp (l dot longdash dot) clc(white white white white) ///
		graphregion(color(white)) bgcolor(white) legend(off) xscale(lcolor(white)) yscale(lcolor(white)) ///
		xtitle("") ytitle("") ylabel("") xlabel("") ///
		saving($results\cummortality_blank, replace)
	
/*	graph combine $results\cummortality_3.gph  $results\cummortality_4.gph $results\cummortality_6.gph  ///
	$results\cummortality_7.gph $results\cummortality_15.gph /// 
	$results\cummortality_19.gph $results\cummortality_21.gph $results\cummortality_22.gph $results\cummortality_24.gph ///
	$results\cummortality_25.gph $results\cummortality_28.gph $results\cummortality_32.gph, cols(4) graphregion(color(white)) ///
	b1(Attained Age (years)) l1(Cumulative Mortality due to Suicide (%)) */
	
	grc1leg $results\cummortality_21.gph  $results\cummortality_28.gph $results\cummortality_19.gph  ///
	$results\cummortality_25.gph $results\cummortality_32.gph $results\cummortality_3.gph $results\cummortality_7.gph $results\cummortality_22.gph ///
	$results\cummortality_blank.gph $results\cummortality_4.gph $results\cummortality_6.gph $results\cummortality_blank.gph , cols(4) graphregion(color(white)) ///
	b1(Attained Age (years)) l1(Cumulative Mortality due to Suicide (%)) legendfrom($results\cummortality_3.gph)
	
	graph export "$results\CumulativeRisk_31May18.tif", as(tif) replace width(4000)
	
	