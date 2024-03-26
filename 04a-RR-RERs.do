**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Rate ratios, Relative Excess Risks and adjusted heterogeneity tests
**********************************************************************

*--- Pre run settings
set more off

*-----------------------------------------------------------------------------------
*-----Rate ratios for SMR and AER by factors
*-----------------------------------------------------------------------------------

*-- read in the data		
	use "$data/x-stset-aa-1899-dep.dta"  , clear

*--- ensure patient only exits the study at failure event	
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N

*--- generate person years
	replace pyrs =(_t-_t0)

*--- generate expected rate
	replace E_suicide=(_t-_t0) * (poprate / 100000) 

*--- generate person-year per 10,000 persons
	gen y=pyrs / 10000

*--- tabulations to check everything looks as it should	
	tab ethnicitygroup, nolab
	tab decdx, nolab
	tab fu, nolab

*--- calculate RR and RER by attained age or follow-up (plus sex, deprivation ethnicity cancer group, decade of diagnosis and age at diagnosis)
*--- cannot have a model with both follow-up and attained age as they are correlated	
	foreach v of varlist fu ageband2 {
		preserve
		
		*set the baseline level for follow-up and attained age		
		if "`v'" == "fu" {
			local i = 0
		}
		else {
			local i = 60
		}
		
		*sum the data by all factor variables
		collapse (sum) _dsuicide E_suicide pyrs y, by(sex deprivation ethnicitygroup `v' cancergroup2 cage decdx)
		
		*generate expeted rate by 10,000 person-years
		gen erate = E_suicide / y
		
		*model to calculate Relative Risks (Ratio of SMRs)
		xi, noomit: glm _dsuicide ib1.sex ib1.deprivation ib1.ethnicitygroup ib`i'.`v' ib6.cancergroup2 ib60.cage ib2000.decdx if E_suicide!=0, fam(pois) eform lnoffset(E_suicide)	
		
		*export the results
		if "`v'" == "fu" {
			outreg2 using "$results\rr-1899-overall-all.doc", replace ctitle(SMRs `v') eform stats(coef ci) dec(2)
		}
		else {
			outreg2 using "$results\rr-1899-overall-all.doc", append ctitle(SMRs `v') eform stats(coef ci) dec(2)
		}
		
		*model to calculate Relative Excess Risks (ratio of AERs)
		xi, noomit: glm _dsuicide ib1.sex ib1.deprivation ib1.ethnicitygroup ib`i'.`v' ib6.cancergroup2 ib60.cage ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		*export the results
		outreg2 using "$results\rr-1899-overall-all.doc", append ctitle(AERs `v') eform stats(coef ci) dec(2)
		
		

*--- calculate adjusted heterogeneity tests for SMRs (RRs)
/* Likelihood ratio of model adjusted for all variables (as categorical variables) and model omitting 1 categorical variable*/

		*Model with all variables 
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store a

		*Omit sex
		xi, noomit: glm _dsuicide ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store b

		*Omit cancer group
		xi, noomit: glm _dsuicide ib1.sex ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store c

		*Omit ethnicity
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store d

		*Omit deprivation		
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib`i'.`v' ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store e

		*Omit Follow-up/attained age
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib60.cage ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store f

		*Omit age at diagnosis
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib2000.decdx, fam(pois) eform lnoffset(E_suicide)	
		est store g

		*Omit decade of cancer diagnosis
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage, fam(pois) eform lnoffset(E_suicide)	
		est store h	
			
		*sex test
		lrtest a b
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a2= ("Sex") b2= ("SMR het")
		putexcel c1= ("p Value") c2= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d2= matrix (r(df))
		putexcel e1=("LR test statistic") 	e2 = matrix (r(chi2))
		
		*cancer type test
		lrtest a c
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a3= ("Cancer") b3= ("SMR het")
		putexcel c1= ("p Value") c3= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d3= matrix (r(df))
		putexcel e1=("LR test statistic") 	e3 = matrix (r(chi2))
		
		*ethnicity test
		lrtest a d
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a4= ("Ethnicity") b4= ("SMR het")
		putexcel c1= ("p Value") c4= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d4= matrix (r(df))
		putexcel e1=("LR test statistic") 	e4 = matrix (r(chi2))
		
		* deprivation test
		lrtest a e
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a5= ("Deprivation") b5= ("SMR het")
		putexcel c1= ("p Value") c5= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d5= matrix (r(df))
		putexcel e1=("LR test statistic") 	e5 = matrix (r(chi2))
		
		* follow-up / attained age test
		lrtest a f
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a6= ("`v'") b6= ("SMR het")
		putexcel c1= ("p Value") c6= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d6= matrix (r(df))
		putexcel e1=("LR test statistic") 	e6 = matrix (r(chi2))
		
		*age at diagnosis test
		lrtest a g
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a7= ("Age diagnosis") b7= ("SMR het")
		putexcel c1= ("p Value") c7= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d7= matrix (r(df))
		putexcel e1=("LR test statistic") 	e7 = matrix (r(chi2))
		
		*decade of diagnosis
		lrtest a h
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a8= ("Decade diagnosis") b8= ("SMR het")
		putexcel c1= ("p Value") c8= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d8= matrix (r(df))
		putexcel e1=("LR test statistic") 	e8 = matrix (r(chi2))
		

*--- calculate adjusted heterogeneity tests for AERs (RERs)
/* Likelihood ratio of model adjusted for all variables (as categorical variables) and model omitting 1 categorical variable*/

		*Model with all variables 
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=. , fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store a

		*Omit sex 
		xi, noomit: glm _dsuicide ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store b

		*Omit cancer group 
		xi, noomit: glm _dsuicide ib1.sex ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store c

		*Omit ethnicity 
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.deprivation ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store d

		*Omit deprivation
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib`i'.`v' ib60.cage ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store e

		*Omit Follow-up/attained age
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib60.cage ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store f

		*Omit decade of diagnosis
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib2000.decdx if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store g

		*Omit age at diagnosis 
		xi, noomit: glm _dsuicide ib1.sex ib6.cancergroup2 ib1.ethnicitygroup ib1.deprivation ib`i'.`v' ib60.cage if  E_suicide!=. ,  fam(pois) link(rs E_suicide) eform lnoffset(y)
		est store h	
			
		*sex test
		lrtest a b
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a9= ("Sex") b9= ("AER het")
		putexcel c1= ("p Value") c9= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d9= matrix (r(df))
		putexcel e1=("LR test statistic") 	e9 = matrix (r(chi2))
		
		*cancer type test
		lrtest a c
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a10= ("Cancer") b10= ("AER het")
		putexcel c1= ("p Value") c10= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d10= matrix (r(df))
		putexcel e1=("LR test statistic") 	e10 = matrix (r(chi2))
		
		*ethnicity test
		lrtest a d
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a11= ("Ethnicity") b11= ("AER het")
		putexcel c1= ("p Value") c11= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d11= matrix (r(df))
		putexcel e1=("LR test statistic") 	e11 = matrix (r(chi2))
		
		* deprivation test
		lrtest a e
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a12= ("Deprivation") b12= ("AER het")
		putexcel c1= ("p Value") c12= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d12= matrix (r(df))
		putexcel e1=("LR test statistic") 	e12 = matrix (r(chi2))
		
		* follow-up / attained age test
		lrtest a f
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a13= ("`v'") b13= ("AER het")
		putexcel c1= ("p Value") c13= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d13= matrix (r(df))
		putexcel e1=("LR test statistic") 	e13 = matrix (r(chi2))
		
		*age at diagnosis test
		lrtest a g
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a14= ("Age diagnosis") b14= ("AER het")
		putexcel c1= ("p Value") c14= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d14= matrix (r(df))
		putexcel e1=("LR test statistic") 	e14 = matrix (r(chi2))
		
		*decade of diagnosis
		lrtest a h
		
		putexcel set "$results\rr-all-het", sheet("`v'-rr") modify   
		putexcel a15= ("Decade diagnosis") b15= ("AER het")
		putexcel c1= ("p Value") c15= matrix (r(p))
		putexcel d1= ("Degrees of freedom") d15= matrix (r(df))
		putexcel e1=("LR test statistic") 	e15 = matrix (r(chi2))

		restore
	
	}
	
	
	
		}	
