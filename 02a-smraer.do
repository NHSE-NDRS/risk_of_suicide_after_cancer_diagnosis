**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Calculate SMRs and AERs
**********************************************************************

*--- Pre run settings
set more off

*------------------------------------------------------------------------------------
* new update to deprivation data since original extact - need to format and add this to current data
*------------------------------------------------------------------------------------

*--- read in deprivation data
	insheet using "$data\Deprivation fix.csv", c clear n
	
*--- check for duplicates
	codebook patientid
	codebook tumourid
	tab rank
	drop rank

*--- save the deprivation data	
	save "$data\x-suicide-deprivation", replace 
	
*------------------------------------------------------------------------------------
*Link to new deprivation data before stset
*------------------------------------------------------------------------------------	

*--- read in formatted data	
	use "$data/x-suicide-e3-1899" , clear
	capture drop __000001

*--- check number of tumours	
	codebook tumourid

*--- rename old deprivation variables prior to merging to new deprivation variables	
	rena quintile2015 quintile2015_old
	rena quintile2010 quintile2010_old
	rena quintile2007 quintile2007_old
	rena quintile2004 quintile2004_old
	rena deprivation_quintile deprivation_quintile_old

*--- merge in new deprivation variables	
	merge 1:1 tumourid patientid using "$data/x-suicide-deprivation" /*, assert(2 3) keep(3)*/
	tab _merge //tabulate the match results
	assert _merge!=1 //ensure we don't have rows with just the master data

*--- some deprivation records missing, take from old deprivation
	tab deprivation_quintile, miss
	replace deprivation_quintile = deprivation_quintile_old if mi(deprivation_quintile)
	replace quintile2015 = quintile2015_old if mi(quintile2015)
	replace quintile2010 = quintile2010_old if mi(quintile2010)
	replace quintile2007 = quintile2007_old if mi(quintile2007)
	replace quintile2004 = quintile2004_old if mi(quintile2004)
	drop _merge

*--- create numerical version of deprivation	
gen deprivation=1 if deprivation_quintile =="1 - least deprived"
	recode deprivation .=2 if deprivation_quintile =="2"
	recode deprivation .=3 if deprivation_quintile =="3"
	recode deprivation .=4 if deprivation_quintile =="4"
	recode deprivation .=5 if deprivation_quintile =="5 - most deprived"
*	label define deprivation 1 "1 - least deprived" 2 "2" 3 "3" 4 "4" 5 "5 - most deprived" 
	label values deprivation deprivation

*--- save the data	
	save "$data/x-suicide-e3-1899-dep", replace
	
*------------------------------------------------------------------------------------
*Read in and format population rates
*------------------------------------------------------------------------------------

*--- read in population data
	insheet using "$genpop\suicidepoprate2016.csv", c clear n
	
*--- Age-specific rate per 100,000	
	rena newrate poprate
	rena age ageband
	drop agegrp

*--- save the data
	save "$genpop\x-suicide-poprate", replace 
		
*------------------------------------------------------------------------------------
*STSET by attained age
*------------------------------------------------------------------------------------	
		
*--- read in formatted data with new deprivation
	use "$data/x-suicide-e3-1899-dep" , clear
	capture drop __000001
	
*--- what is the maximum date of exit, i.e. follow-up time
	codebook dox
	
*--- Stset by attained age:	
	stset dox , fail(suicide==1) origin(dob) enter(doe) scale(365.25) id(id) exit(suicide==1 time d(31Aug2017))
	drop if _st==0
	
*--- stsplit -- want to group by age and calendar year groups

	stsplit ageband, at(0 (5)90 130) after(time=dob)

	stsplit yeargrp, after(time=d(1/1/1995)) at(0(1)22)
	replace yeargrp = yeargrp + 1995	
	
	sort sex ageband yeargrp

*--- Merge with external reference rates

	* external reference rates go up until 2016, and so assume that the rate in 2017 is the same as in 2016

	merge m:1 sex ageband yeargrp using "$genpop/x-suicide-poprate" , assert(2 3) keep(3)
	assert _merge!=1
	drop if _merge!=3
	drop _merge
	
*--- Calculate expected numbers of deaths using population rates

	gen E_suicide = (_t-_t0) * (poprate / 100000)	
	
*--- This updates the variable based on the stsplit -- overall have a lot more observations as have split the data 	
	qui bysort id (_t):  gen _dsuicide =  _d==1 & suicide==1 & _n==_N
	lab val _dsuicide yn
	gen pyrs = (_t-_t0)
	
*--- Add in some additional variables for presentation of results	
*--- Create an overall variable to get the overall SMR and AER estimates	
	gen overall=1
	label define overall 1 "Overall"
	label values overall overall
	
	*stsplit to get follow-up period and attained age variables
	stsplit fu , at(0(0.5)1 2 3 5 10 100) after(time=doe)
	replace fu=4 if fu==3
	replace fu=3 if fu==2
	replace fu=2 if fu==1
	replace fu=1 if fu==0.5
	label define fu 0 "0-5 months" 1 "6-11 months" 2 "1- years" 3 "2- years" 4 "3-4 years" 5 "5-9 years" 10 "10+ years"
	label values fu fu

	stsplit ageband2, at(18 30 50(10)80 130) after(time=dob)
	label define ageband2 18 "18-29 yrs" 30 "30-49 yrs" 50 "50-59 yrs" 60 "60-69 yrs" 70 "70-79 yrs" 80 "80+ yrs"
	label values ageband2 ageband2

	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N
	replace pyrs =(_t-_t0)
	replace E_suicide=(_t-_t0) * (poprate / 100000) 	
	
*--- Save this dataset as the main SMR dataset to use
	capture drop v6 v7 v8 v9
	save "$data/x-stset-aa-1899-dep", replace
		
	tab _dsuicide
	
*------------------------------------------------------------------------------------
*STSET by attained age for each cancer site with a significant overall risk
*------------------------------------------------------------------------------------	
		
*--- read in formatted data with new deprivation	
	use "$data/x-suicide-e3-1899-dep" , clear
	capture drop __000001

*--- Run a loop around each cancer group to create a file with survival type data for each cancer group

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 15=Kidney and unspecified urinary organs, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 24=Non-hodgkin lymphoma, 25=Oesophagus, 28=Pancreas, 32=stomach */
	
	foreach i in 1 3 4 6 7 15 18 19 21 22 24 25 28 32 {	
*foreach i in 1 3 4{	
*foreach i in 6 7 15 18 19 21 22 24 25 28 32 {	
	preserve
	
*Select the cancer type in the loop
	keep if cancergroup2 == `i'
	
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
	
* This updates the variable based on the stsplit -- overall have a lot more observations as have split the data 	
	qui bysort id (_t):  gen _dsuicide =  _d==1 & suicide==1 & _n==_N
	lab val _dsuicide yn
	gen pyrs = (_t-_t0)
	
* Add in some additional variables for presentation of results	
* Create an overall variable to get the overall SMR and AER estimates	
	gen overall=1
	label define overall 1 "Overall"
	label values overall overall
		
*stsplit to get follow-up period and attained age variables
	stsplit fu , at(0(0.5)1 2 3 5 10 100) after(time=doe)
	replace fu=4 if fu==3
	replace fu=3 if fu==2
	replace fu=2 if fu==1
	replace fu=1 if fu==0.5
	label define fu 0 "0-5 months" 1 "6-11 months" 2 "1- years" 3 "2- years" 4 "3-4 years" 5 "5-9 years" 10 "10+ years"
	label values fu fu
		
*broader attained age groups:
	stsplit ageband2, at(18 30 50(10)80 130) after(time=dob)
	label define ageband2 18 "18-29 yrs" 30 "30-49 yrs" 50 "50-59 yrs" 60 "60-69 yrs" 70 "70-79 yrs" 80 "80+ yrs"
	label values ageband2 ageband2
	
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N
	replace pyrs =(_t-_t0)
	replace E_suicide=(_t-_t0) * (poprate / 100000) 	
	
* Save this dataset as the main SMR dataset to use
	capture drop v6 v7 v8 v9
	save "$data/x-stset-aa-1899-dep-`i'", replace
	restore
}		

*------------------------------------------------------------------------------------
*------------------------------------------------------------------------------------
*SMR AND AER ANALYSIS STARTS HERE
*------------------------------------------------------------------------------------	
*------------------------------------------------------------------------------------


*------------------------------------------------------------------------------------
*Direct calculation of SMRs and AERs for TABLE 2, TABLE 3, ETABLE 5
*By sex, cancer group, ethnicity, deprivation and age band (all cancers combined)
*------------------------------------------------------------------------------------		

*--- read in stset data	
	use "$data/x-stset-aa-1899-dep.dta"  , clear
	
*--- ensure patient only exits the study at failure event
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N

*--- generate person years	
	replace pyrs =(_t-_t0)

*--- generate risk of suicide	
	replace E_suicide=(_t-_t0) * (poprate / 100000) 
	

foreach v of varlist overall sex cancergroup2 ethnicitygroup deprivation fu ageband2 {
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
		save "$results/result-overallsmr-1899-dep-`v'", replace
		restore	
	}

*--Append all factors together	
		
		use "$results/result-overallsmr-1899-dep-overall", clear
		append using "$results/result-overallsmr-1899-dep-sex"
		append using "$results/result-overallsmr-1899-dep-cancergroup2"
		append using "$results/result-overallsmr-1899-dep-ethnicitygroup"
		append using "$results/result-overallsmr-1899-dep-deprivation"
	*	append using "$results/result-overallsmr-1899-dep-cage"
		append using "$results/result-overallsmr-1899-dep-fu"
		append using "$results/result-overallsmr-1899-dep-ageband2"
	*	append using "$results/result-overallsmr-1899-dep-decdx"

*--- save the results			
		save "$results/Appended-result-overallsmr-overall-1899-dep", replace
		
		
*------------------------------------------------------------------------------------
*Modelling approach to calculating SMRs and AERs for TABLE 2, TABLE 3, ETABLE 5
*By sex, cancer group, ethnicity, deprivation and age band (all cancers combined)
*------------------------------------------------------------------------------------			

*--- background information		
	*https://www.princeton.edu/~otorres/Outreg2.pdf
	*http://repec.org/bocode/o/outreg2.html

*--- read in stset data		
	use "$data/x-stset-aa-1899-dep.dta"  , clear

*--- generate person years per 10,000 persons
	gen y=pyrs / 10000
	
	foreach v of varlist sex cancergroup2 ethnicitygroup deprivation fu ageband2 {
		preserve
		
		collapse (sum) _dsuicide E_suicide pyrs y, by(`v')
		gen erate = E_suicide / y
		
	*	eststo, title("Sex"): glm _dsuicide i.sex , lnoffset(E_suicide) fam(poisson) noconstant eform
	*	estout using "$results/smr-sex.rtf", cells(b(fmt(%9.1f)) ci(par fmt(%9.1f))) label eform replace
	*	eststo clear
		
		xi, noomit: glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) noconstant eform 
		
		if "`v'" == "sex" {
			outreg2 using "$results\smraer-1899-overall-dep.doc", replace ctitle(SMRs) eform stats(coef ci) dec(2)
		}
		else {
			outreg2 using "$results\smraer-1899-overall-dep.doc", append ctitle(SMRs) eform stats(coef ci) dec(2)
		}

		xi, noomit: glm _dsuicide i.`v' if  E_suicide!=. , fam(pois) offset(erate) link(rsadd y) noconstant
		outreg2 using "$results\smraer-1899-overall-dep.doc", append ctitle(AERs) stats(coef ci) dec(2)
	
	restore
	}
	
	

*------------------------------------------------------------------------------------
*Direct calculation of SMRs and AERs for TABLE 4, ETABLE3, ETABLE 4 AND ETABLE 6
*For each cancer site, produce SMRs and AERs by follow-up, attained age and sex
*------------------------------------------------------------------------------------
foreach i in 1 3 4 6 7 18 19 21 22 25 28 32 {

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 25=Oesophagus, 28=Pancreas, 32=stomach */

		use "$data/x-stset-aa-1899-dep-`i'", clear	

*Start variabl loop
		foreach v of varlist sex fu ageband2 {
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
			gen str smrstr = string(smr , "%9.1f") + " (" + string(smrll , "%9.1f") + "," + string(smrul , "%9.1f") + ")" 
			
			gen aer		= cond(((_dsuicide- E_suicide)/pyrs)>0 , ((_dsuicide- E_suicide)/pyrs) , 0)
			gen aerll		= aer - (1.96*(sqrt(_dsuicide)/pyrs))
			gen aerul		= aer + (1.96*(sqrt(_dsuicide)/pyrs))
			gen str aerstr = string(aer , "%9.1f") + " (" + string(aerll , "%9.1f") + "," + string(aerul , "%9.1f") + ")"  
									
			sort `v'
			decode `v', gen(strdiag)
			
			gen str8 factor=""
			replace factor = "`v'"
				
			keep cancergroup2 factor strdiag smrstr* obstr* aerstr*   
			save "$resultjuly\result-overallsmr-broad-1899-dep-`v'-`i'", replace
			restore	
	}
	}
	

**Append all factors together for each cancer type


	foreach i in 1 3 4 6 7 18 19 21 22 25 28 32 {
		use "$resultjuly\result-overallsmr-broad-1899-dep-fu-`i'", clear
		append using "$resultjuly\result-overallsmr-broad-1899-dep-ageband2-`i'"
		append using "$resultjuly\result-overallsmr-broad-1899-dep-sex-`i'"	
		save "$resultjuly\Appended result-overallsmr-broad-1899-dep-`i'", replace
	}
	
	use "$resultjuly\Appended result-overallsmr-broad-1899-dep-1", clear
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-3"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-4"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-6"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-7"
*	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-15"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-18"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-19"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-21"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-22"
*	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-24"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-25"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-28"
	append using "$resultjuly\Appended result-overallsmr-broad-1899-dep-32"

	save "$resultjuly\Appended result-overallsmr-broad-1899-dep-cancers", replace

	
*------------------------------------------------------------------------------------
*Modelling approach to calculating SMRs and AERs for TABLE 4, ETABLE3, ETABLE 4 AND ETABLE 6
*For each cancer site, produce SMRs and AERs by follow-up, attained age and sex
*------------------------------------------------------------------------------------

*--This is what is used in the manuscript /*TABLE 4, ETABLE3, ETABLE 4 AND ETABLE 6*/

	foreach i in 1 3 4 6 7 18 19 21 22 25 28 32 {	

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 25=Oesophagus, 28=Pancreas, 32=stomach */
		
		use "$data/x-stset-aa-1899-dep-`i'.dta"  , clear
		gen y=pyrs / 10000
		
		foreach v of varlist sex fu ageband2 {
		*fu ageband2
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
			
			collapse (sum) _dsuicide E_suicide pyrs y, by(`v') fast
			gen erate = E_suicide / y
			
			xi, noomit: glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) noconstant eform 
			
			if "`v'" == "sex" {
				outreg2 using "$resultjuly\smraer-broad-1899-dep-`i'.doc", replace ctitle(SMRs) eform stats(coef ci) dec(2)
			}
			else {
				outreg2 using "$resultjuly\smraer-broad-1899-dep-`i'.doc", append ctitle(SMRs) eform stats(coef ci) dec(2)
			}

			xi, noomit: glm _dsuicide i.`v' if  E_suicide!=. , fam(pois) offset(erate) link(rsadd y) noconstant
			outreg2 using "$resultjuly\smraer-broad-1899-dep-`i'.doc", append ctitle(AERs) stats(coef ci) dec(2)
		
		restore
		}	
	}





*------------------------------------------------------------------------------------
*The following SMR and AER estimates not used in publication
*------------------------------------------------------------------------------------
	


*--- Run a loop around each cancer group to ccalculate SMRs and AERs for each cancer type
	foreach i in 1 3 4 6 7 18 19 21 22 25 28 32 {	

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 25=Oesophagus, 28=Pancreas, 32=stomach */

*--- read in stset data			
		use "$data/x-stset-aa-1899-dep-`i'.dta"  , clear

*--- generate person years per 10,000 persons
		gen y=pyrs / 10000
		
		foreach v of varlist sex fu ageband2 {
		*fu ageband2
			preserve
			
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
			else if `i' == 22 | `i' == 28 {
			* multiple myeloma and pancreas
				replace fu = 5 if fu == 10
			}
			else {
				noi di "continue"
			}
			
			collapse (sum) _dsuicide E_suicide pyrs y, by(`v') fast
			gen erate = E_suicide / y
			
			xi, noomit: glm _dsuicide i.`v' , lnoffset(E_suicide) fam(poisson) noconstant eform 
			
			if "`v'" == "sex" {
				outreg2 using "$resultjuly\smraer-1899-dep-`i'.doc", replace ctitle(SMRs) eform stats(coef ci) dec(2)
			}
			else {
				outreg2 using "$resultjuly\smraer-1899-dep-`i'.doc", append ctitle(SMRs) eform stats(coef ci) dec(2)
			}

			xi, noomit: glm _dsuicide i.`v' if  E_suicide!=. , fam(pois) offset(erate) link(rsadd y) noconstant
			outreg2 using "$resultjuly\smraer-1899-dep-`i'.doc", append ctitle(AERs) stats(coef ci) dec(2)
		
		restore
		}	
	}

*------------------------------------------------------		
*--Looping through each factor within each cancer type
*------------------------------------------------------


/*Just look at cancer types with significant overall excess*/	
foreach i in 1 3 4 6 7 15 18 19 21 22 24 25 28 32 {

/* 1=bladder, 3=Cancer of unknown primary, 4=Central nervous system (incl brain) malignant, 6=Colorectal,
 7=Head and neck, 15=Kidney and unspecified urinary organs, 18=Liver, 19=Lung, 21=Mesothelioma, 
22=Multiple myeloma, 24=Non-hodgkin lymphoma, 25=Oesophagus, 28=Pancreas, 32=stomach */

		use "$data/x-stset-aa-1899-dep-`i'", clear	

*Start variable loop
	*	foreach v of varlist overall sex cancergroup2 ethnicitygroup deprivation cage decdx fu ageband2 {
		foreach v of varlist sex fu ageband2 {
		preserve
		
* Overall SMR and AER estimates:
			bysort `v': replace pyrs = sum(pyrs)/10000
			bysort `v': replace  _dsuicide = sum(_dsuicide)
			bysort `v': replace  E_suicide = sum(E_suicide)
			bysort `v': keep if _n==_N  
		
*--Person-years
			bysort `v': gen sumpyears = sum(pyrs) * 100
			bysort `v': replace sumpyears = sumpyears[_N]
			format sumpyears %9.0f
	
*--OBSERVED NO
			gen obstr = string(_dsuicide) + " / " + string(E_suicide , "%9.0f")
			
			gen smr		= (_dsuicide/E_suicide)
			gen smrll		= ((invgammap( _dsuicide,     (0.05)/2))/E_suicide) 
			gen smrul 		= ((invgammap((_dsuicide+ 1), (1.95)/2))/E_suicide) 
			gen str smrstr = string(smr , "%9.1f") + " (" + string(smrll , "%9.1f") + "," + string(smrul , "%9.1f") + ")" 
			
			gen aer		= cond(((_dsuicide- E_suicide)/pyrs)>0 , ((_dsuicide- E_suicide)/pyrs) , 0)
			gen aerll		= aer - (1.96*(sqrt(_dsuicide)/pyrs))
			gen aerul		= aer + (1.96*(sqrt(_dsuicide)/pyrs))
			gen str aerstr = string(aer , "%9.1f") + " (" + string(aerll , "%9.1f") + "," + string(aerul , "%9.1f") + ")"  
									
			sort `v'
			decode `v', gen(strdiag)
			
			gen str8 factor=""
			replace factor = "`v'"
				
			keep cancergroup2 factor strdiag smrstr* obstr* aerstr* sumpyears*  
			save "$resultjuly\result-overallsmr-1899-dep-`v'-`i'", replace
			restore	
	}
	}
	

**Append all factors together for each cancer type

	foreach i in 1 3 4 6 7 15 18 19 21 22 24 25 28 32 {
	*	use "$results\result-overallsmr-overall-1899-`i'", clear
	*	append using "$results\result-overallsmr-1899-sex-`i'"
	*	append using "$results\result-overallsmr-1899-cancergroup2-`i'"
	*	append using "$results\result-overallsmr-1899-ethnicitygroup-`i'"
	*	append using "$results\result-overallsmr-1899-deprivation-`i'"
	*	append using "$results\result-overallsmr-1899-cage-`i'"
	*	append using "$results\result-overallsmr-1899-decdx-`i'"
		use "$resultjuly\result-overallsmr-1899-dep-fu-`i'", clear
		append using "$resultjuly\result-overallsmr-1899-dep-sex-`i'"
	*	append using "$results\result-overallsmr-1899-fu-`i'"
		append using "$resultjuly\result-overallsmr-1899-dep-ageband2-`i'"	
		save "$resultjuly\Appended result-overallsmr-1899-dep-`i'", replace
	}
	
	use "$resultjuly\Appended result-overallsmr-1899-dep-1", clear
	append using "$resultjuly\Appended result-overallsmr-1899-dep-3"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-4"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-6"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-7"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-15"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-18"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-19"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-21"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-22"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-24"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-25"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-28"
	append using "$resultjuly\Appended result-overallsmr-1899-dep-32"

	save "$resultjuly\Appended result-overallsmr-1899-dep-cancers", replace
		