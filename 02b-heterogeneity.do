**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Trend and heterogeniety tests
**********************************************************************

*--- Pre run settings
set more off

*This script uses the modelling approach to calculate trend and heterogeneity tests of SMRs and AERs
*/ 
Method for Heterogeneity- conduct a likelihood ratio test of 
 - model with dependent variable added as a categorical variable
 - model with no dependent variable

Method for trend - conduct a likelihood ratio test of 
 - model with dependent variable added as a continuous variable
 - model with no dependent variable
*/

*------------------------------------------------------------------------------------
*Modelling approach to calculating heterogeneity and trends (TABLE 2 AND 3, ETABLE 5)
*By sex, cancer group, ethnicity, deprivation, follow-up and attained age (all cancers combined)
*------------------------------------------------------------------------------------
	
	use "$data/x-stset-aa-1899-dep.dta"  , clear
		
	foreach v in cancergroup2 sex ethnicitygroup deprivation fu ageband2 {
		
		preserve
	
		bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N 
		replace pyrs =(_t-_t0)
		replace E_suicide=(_t-_t0) * (poprate / 100000) 
		
		gen y=pyrs / 10000
		collapse (sum) _dsuicide E_suicide pyrs y, by(`v')
		gen erate = E_suicide / y
				
		*SMR heterogeneity test
		glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) eform 
		est store a
		glm _dsuicide, lnoffset(E_suicide) fam(poisson) eform 
		est store b
		noisily di "SMR het test"
		lrtest a b
		
		putexcel set "$results\allcancers-smr_het", sheet("`v'") modify 
		putexcel a2= ("`i'") b2= ("`v'") c2= ("SMR het")
		putexcel d1= ("p Value") d2= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e2= matrix (r(df))
		putexcel f1=("LR test statistic") 	f2 = matrix (r(chi2))
				
		
		*SMR trend test
		glm _dsuicide `v' , lnoffset(E_suicide) fam(poisson) eform 
		est store a
		glm _dsuicide, lnoffset(E_suicide) fam(poisson)  eform 
		est store b
		noi di "SMR trend test"
		lrtest a b

		putexcel set "$results\allcancers-smr_het", sheet("`v'") modify  
		putexcel a3= ("`i'") b3= ("`v'") c3= ("SMR trend")
		putexcel d1= ("p Value") d3= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e3= matrix (r(df))
		putexcel f1=("LR test statistic") 	f3 = matrix (r(chi2))
		
		
		*AER heterogeneity test
		glm _dsuicide i.`v' if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store a
		glm _dsuicide if E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store b
		noi di "AER het test"
		lrtest a b
		
		putexcel set "$results\allcancers-smr_het", sheet("`v'") modify   
		putexcel a4= ("`i'") b4= ("`v'") c4= ("AER het")
		putexcel d1= ("p Value") d4= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e4= matrix (r(df))
		putexcel f1=("LR test statistic") 	f4 = matrix (r(chi2))
		
		*AER trend test
		glm _dsuicide `v' if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store a
		glm _dsuicide if E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store b
		noi di "AER trend test"
		lrtest a b
	
		putexcel set "$results\allcancers-smr_het", sheet("`v'") modify 
		putexcel a5= ("`i'") b5= ("`v'") c5= ("AER trend")
		putexcel d1= ("p Value") d5= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e5= matrix (r(df))
		putexcel f1=("LR test statistic") 	f5 = matrix (r(chi2))
		
		restore
	}



	
	
*------------------------------------------------------------------------------------
*Modelling approach to calculating heterogeneity and trends (TABLE 4, ETABLE3 AND ETABLE 6)
*For each cancer site by attained age, follow-up and sex
*------------------------------------------------------------------------------------	

foreach i in 3 4 6 7 19 21 22 25 28 32 {

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 25=Oesophagus, 28=Pancreas, 32=stomach */

		use "$data/x-stset-aa-1899-dep-`i'", clear	
		
	foreach v in sex fu ageband2 {
	
		preserve

			if "`v'" == "ageband2" {
				replace ageband2 = 50 if ageband2 == 30
				replace ageband2 = 50 if ageband2 == 18
				replace ageband2 = 70 if ageband2 == 80
			}
			else if "`v'" == "fu" {
			
			*0-5 months, 6-11 months, 1+ year	
				replace fu = 2 if fu == 3
				replace fu = 2 if fu == 4
				replace fu = 2 if fu == 5
				replace fu = 2 if fu == 10
			
			}
			else {
				noi di "continue"
			} 
			
		
		capture gen y=pyrs / 10000
		collapse (sum) _dsuicide E_suicide pyrs y, by(`v')
		gen erate = E_suicide / y
				
		*SMR heterogeneity test
		glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) eform 
		est store a
		glm _dsuicide, lnoffset(E_suicide) fam(poisson) eform 
		est store b
		noisily di "SMR het test"
		lrtest a b
		
		putexcel set "$results\cancertype-smr-het-broad-dep", sheet("`v' - `i'") modify  
		putexcel a2= ("`i'") b2= ("`v'") c2= ("SMR het")
		putexcel d1= ("p Value") d2= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e2= matrix (r(df))
		putexcel f1=("LR test statistic") 	f2 = matrix (r(chi2))
				
		
		*SMR trend test
		glm _dsuicide `v', lnoffset(E_suicide) fam(poisson) eform 
		est store a
		glm _dsuicide, lnoffset(E_suicide) fam(poisson) eform 
		est store b
		noi di "SMR trend test"
		lrtest a b

		putexcel set "$results\cancertype-smr-het-broad-dep", sheet("`v' - `i'") modify   
		putexcel a3= ("`i'") b3= ("`v'") c3= ("SMR trend")
		putexcel d1= ("p Value") d3= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e3= matrix (r(df))
		putexcel f1=("LR test statistic") 	f3 = matrix (r(chi2))
		
		
		*AER heterogeneity test
		glm _dsuicide i.`v' if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store a
		glm _dsuicide if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store b
		noi di "AER het test"
		lrtest a b
		
		putexcel set "$results\cancertype-smr-het-broad-dep", sheet("`v' - `i'") modify   
		putexcel a4= ("`i'") b4= ("`v'") c4= ("AER het")
		putexcel d1= ("p Value") d4= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e4= matrix (r(df))
		putexcel f1=("LR test statistic") 	f4 = matrix (r(chi2))
		
		*AER trend test
		glm _dsuicide `v' if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store a
		glm _dsuicide if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store b
		noi di "AER trend test"
		lrtest a b
	
		putexcel set "$results\cancertype-smr-het-broad-dep", sheet("`v' - `i'") modify  
		putexcel a5= ("`i'") b5= ("`v'") c5= ("AER trend")
		putexcel d1= ("p Value") d5= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e5= matrix (r(df))
		putexcel f1=("LR test statistic") 	f5 = matrix (r(chi2))
		
		restore
		}
		}
		
		

*------------------------------------------------------------------------------------
*Modelling approach to calculating heterogeneity and trends (Not used in published paper) 
*For each cancer site by attained age, follow-up and sex
*------------------------------------------------------------------------------------	

*these cancers have enough events to run the tests on the full groups
foreach i in 1 3 4 6 7 18 19 21 22 25 28 32{

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 25=Oesophagus, 28=Pancreas, 32=stomach */

		use "$data/x-stset-aa-1899-dep-`i'", clear	
		
	foreach v in sex fu ageband2 {
	
		preserve
		* group agebands if required
		if "`v'" == "ageband2" {
				replace ageband2 = 30 if ageband2 == 18
			}
			else {
				noi di "continue"
			} 
			
			if `i' == 4 {
			* CNS
				replace ageband2 = 70 if ageband2 == 80
			}
			else if `i' == 21 {
			* mesothelioma
				replace ageband2 = 50 if ageband2 == 30
				replace fu = 1 if fu == 2
				replace fu = 1 if fu == 3
				replace fu = 1 if fu == 4
				replace fu = 1 if fu == 5
				replace fu = 1 if fu == 10
			}
			else if `i' == 3 | `i' == 18 {
			* CUP and liver
				replace fu = 4 if fu == 10
				replace fu = 4 if fu == 5
			}
			else if `i' == 22 | `i' == 28  | `i' == 19  | `i' == 25   {
			* multiple myeloma and pancreas and lung and oesophagus
				replace fu = 5 if fu == 10
			}
			else {
				noi di "continue"
			}
			
		
		capture gen y=pyrs / 10000
		collapse (sum) _dsuicide E_suicide pyrs y, by(`v')
		gen erate = E_suicide / y
				
		*SMR heterogeneity test
		glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) eform 
		est store a
		glm _dsuicide, lnoffset(E_suicide) fam(poisson) eform 
		est store b
		noisily di "SMR het test"
		lrtest a b
		
		putexcel set "$results\cancertype-smr-het", sheet("`v' - `i'") modify  
		putexcel a2= ("`i'") b2= ("`v'") c2= ("SMR het")
		putexcel d1= ("p Value") d2= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e2= matrix (r(df))
		putexcel f1=("LR test statistic") 	f2 = matrix (r(chi2))
				
		
		*SMR trend test
		glm _dsuicide `v', lnoffset(E_suicide) fam(poisson) eform 
		est store a
		glm _dsuicide, lnoffset(E_suicide) fam(poisson) eform 
		est store b
		noi di "SMR trend test"
		lrtest a b

		putexcel set "$results\cancertype-smr-het", sheet("`v' - `i'") modify   
		putexcel a3= ("`i'") b3= ("`v'") c3= ("SMR trend")
		putexcel d1= ("p Value") d3= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e3= matrix (r(df))
		putexcel f1=("LR test statistic") 	f3 = matrix (r(chi2))
		
		
		*AER heterogeneity test
		glm _dsuicide i.`v' if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store a
		glm _dsuicide if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store b
		noi di "AER het test"
		lrtest a b
		
		putexcel set "$results\cancertype-smr-het", sheet("`v' - `i'") modify   
		putexcel a4= ("`i'") b4= ("`v'") c4= ("AER het")
		putexcel d1= ("p Value") d4= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e4= matrix (r(df))
		putexcel f1=("LR test statistic") 	f4 = matrix (r(chi2))
		
		*AER trend test
		glm _dsuicide `v' if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store a
		glm _dsuicide if  E_suicide!=0 , fam(pois) offset(erate) link(rsadd y) 
		est store b
		noi di "AER trend test"
		lrtest a b
	
		putexcel set "$results\cancertype-smr-het", sheet("`v' - `i'") modify  
		putexcel a5= ("`i'") b5= ("`v'") c5= ("AER trend")
		putexcel d1= ("p Value") d5= matrix (r(p))
		putexcel e1= ("Degrees of freedom") e5= matrix (r(df))
		putexcel f1=("LR test statistic") 	f5 = matrix (r(chi2))
		
		restore
		}
		}
		