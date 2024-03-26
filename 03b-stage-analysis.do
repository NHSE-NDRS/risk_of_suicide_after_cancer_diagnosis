**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** SMRs and AERs by stage at diagnosis - etable 7
**********************************************************************

*--- Pre run settings
set more off


*------------------------------------------------------------------------------------
*Create dataset
*------------------------------------------------------------------------------------	

*--- read in the data stset by attained age
	use "$data/x-stset-aa-1899", clear	

*--- Only keep where date of entry is after 01/01/2012 due to data quality of stage at diagnosis
	drop if doe < date("20120101","YMD")

*--- replace flag for death by suicide in last row per patient
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N

*--- generate person-years and expected suicide rate based on general population estimates
	replace pyrs =(_t-_t0)
	replace E_suicide=(_t-_t0) * (poprate / 100000) 

*--- generate stage variable and diagnosis year of entry	
	gen stagestr = substr(stage_best,1,1)
	gen diagyear = year(doe)
	tab diagyear stagestr, miss
	
	gen stage =1 if stagestr == "1"
	recode stage .=2 if stagestr == "2"
	recode stage .=3 if stagestr == "3"
	recode stage .=4 if stagestr == "4"
	recode stage .=5 if stagestr == "0" | stagestr == "6" | stagestr == "?" | stagestr == "U" | stagestr == ""

	label define stage 1 "Stage 1" 2 "Stage 2" 3 "Stage 3" 4 "Stage 4" 5 "Unknown stage"
	label values stage stage
	
	save "$data/x-stset-aa-stage-1899", replace

*------------------------------------------------------------------------------------
*SMR and AER estimates by factors, e.g. sex, age etc using direct calculation
*------------------------------------------------------------------------------------		

	use "$data/x-stset-aa-stage-1899", clear

*--- ensure patient only exits the study at failure event	
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N

*--- generate person years
	replace pyrs =(_t-_t0)

*--- generate expected suicide rate
	replace E_suicide=(_t-_t0) * (poprate / 100000) 
			
*----------------------------------------------------------------------			
*Direct calculation of SMRs and AERs for ETABLE7
*By stage at diagnosis and for all stages combined (all cancers combined)
*----------------------------------------------------------------------		

foreach v of varlist overall stage {
		preserve
		
* Overall SMR and AER estimates:
		bysort `v': replace pyrs = sum(pyrs)/10000
		bysort `v': replace  _dsuicide = sum(_dsuicide)
		bysort `v': replace  E_suicide = sum(E_suicide)
		bysort `v': keep if _n==_N  
			
*--OBSERVED NO
		gen obstr = string(_dsuicide) + " / " + string(E_suicide , "%9.0f")
		
		gen smr		= (_dsuicide/E_suicide)
		gen smrll		= ((invgammap( _dsuicide,     (0.05)/2))/E_suicide) 
		gen smrul 		= ((invgammap((_dsuicide+ 1), (1.95)/2))/E_suicide) 
		gen str smrstr = string(smr , "%9.2f") + " (" + string(smrll , "%9.2f") + " to " + string(smrul , "%9.2f") + ")" 

		gen aer		= cond(((_dsuicide- E_suicide)/pyrs)>0 , ((_dsuicide- E_suicide)/pyrs) , 0)
		gen aerll		= aer - (1.96*(sqrt(_dsuicide)/pyrs))
		gen aerul		= aer + (1.96*(sqrt(_dsuicide)/pyrs))
		gen str aerstr = string(aer , "%9.2f") + " (" + string(aerll , "%9.2f") + " to " + string(aerul , "%9.2f") + ")"  
					
		sort `v'
		decode `v', gen(strdiag)
		
		gen str8 factor=""
		replace factor = "`v'"
			
		keep factor strdiag smrstr* obstr* aerstr*  
		save "$results/result-stage-smr-1899-`v'", replace
		restore	
	}

*--Append all factors together	
		
		use "$results/result-stage-smr-1899-overall", clear
		append using "$results/result-stage-smr-1899-stage"
		
		save "$results/result-stage-smr-1899", replace
		
		
*----------------------------------------------------------------------			
*Modelling approach to calculating SMRs and AERs for ETABLE7
*By stage at diagnosis and for all stages combined (all cancers combined)
*----------------------------------------------------------------------				
		
	use "$data/x-stset-aa-stage-1899", clear
	
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N
	replace pyrs =(_t-_t0)
	replace E_suicide=(_t-_t0) * (poprate / 100000) 
	gen y=pyrs / 10000
	
	foreach v of varlist stage {
		preserve
		
		collapse (sum) _dsuicide E_suicide pyrs y, by(`v')
		gen erate = E_suicide / y

		xi, noomit: glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) noconstant eform 
		outreg2 using "$results\smraer-stage-1899-overall.doc", replace ctitle(SMRs) eform stats(coef ci) dec(2)
		
		xi, noomit: glm _dsuicide i.`v' if  E_suicide!=. , fam(pois) offset(erate) link(rsadd y) noconstant
		outreg2 using "$results\smraer-stage-1899-overall.doc", append ctitle(AERs) stats(coef ci) dec(2)
	
	restore
	}
	
	
*------------------------------------------------------------------------------------
*SMR and AER heterogeneity tests
*------------------------------------------------------------------------------------	

	use "$data/x-stset-aa-stage-1899", clear
	
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N 
	replace pyrs =(_t-_t0)
	replace E_suicide=(_t-_t0) * (poprate / 100000) 
		
	gen y=pyrs / 10000
	collapse (sum) _dsuicide E_suicide pyrs y, by(stage)
	gen erate = E_suicide / y
				
*SMR het test
	glm _dsuicide i.stage , lnoffset(E_suicide) fam(poisson) eform 
	est store a
	glm _dsuicide, lnoffset(E_suicide) fam(poisson) eform 
	est store b
	noisily di "SMR het test"
	lrtest a b
		
	putexcel set "$results\stage-smr2012-het", sheet("stage") modify 
	putexcel a2= ("`i'") b2= ("`v'") c2= ("SMR het")
	putexcel d1= ("p Value") d2= matrix (r(p))
	putexcel e1= ("Degrees of freedom") e2= matrix (r(df))
	putexcel f1=("LR test statistic") 	f2 = matrix (r(chi2))
				
*AER het test
	glm _dsuicide i.stage if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
	est store a
	glm _dsuicide if E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
	est store b
	noi di "AER het test"
	lrtest a b
		
	putexcel set "$results\stage-smr2012-het", sheet("stage") modify   
	putexcel a4= ("`i'") b4= ("`v'") c4= ("AER het")
	putexcel d1= ("p Value") d4= matrix (r(p))
	putexcel e1= ("Degrees of freedom") e4= matrix (r(df))
	putexcel f1=("LR test statistic") 	f4 = matrix (r(chi2))
		

*-----------------------------------------------------------------------------------
*-----Rate ratios for SMR and AER for stage
*-----------------------------------------------------------------------------------
		
*--- All variables including age and decade at diagnosis 
		
	use "$data/x-stset-aa-stage-1899", clear
	
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N
	replace pyrs =(_t-_t0)
	replace E_suicide=(_t-_t0) * (poprate / 100000) 
	gen y=pyrs / 10000
	
	foreach v of varlist fu ageband2 {
		preserve
				
		if "`v'" == "fu" {
			local i = 5
		}
		else {
			local i = 60
		}
		
		collapse (sum) _dsuicide E_suicide pyrs y, by(stage sex deprivation ethnicitygroup `v' cancergroup2 cage decdx)
		gen erate = E_suicide / y
		
	*--- SMR RR heterogeneity tests
	*-- stage 1 is the baseline

		xi, noomit: glm _dsuicide ib1.stage ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store a

		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store b

		*Stage test
		lrtest a b
		
		putexcel set "$results\rr-all-het", sheet("stage-`v'-rr") modify   
		putexcel a2= ("Stage") b2= ("SMR het")
		putexcel c1= ("p Value") c2= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d2= matrix (r(df))
		putexcel e1=("LR test statistic") 	e2 = matrix (r(chi2))
		
	**AER RR heterogeneity tests

		xi, noomit: glm _dsuicide ib1.stage ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=., fam(pois) offset(erate) link(rsadd y)  eform
		est store a

		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=. , fam(pois) offset(erate) link(rsadd y)  eform
		est store b

		*Stage test
		lrtest a b
		
		putexcel set "$results\rr-all-het", sheet("stage-`v'-rr") modify   
		putexcel a3= ("Stage") b3= ("AER het")
		putexcel c1= ("p Value") c3= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d3= matrix (r(df))
		putexcel e1=("LR test statistic") 	e3 = matrix (r(chi2))
		
		restore
	
	}	
	