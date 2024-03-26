**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Table 1: Patient characteristics table
**********************************************************************	

*--- Read in the formatted data	
	*use  "$data\x-suicide-e3-1899", clear
	use  "$data\x-suicide-e3-1899-dep", clear //re-run with new dep field which was fixed in 02a-smraer
	
*--- Put the data into survival format

	* stset the data
	stset dox , fail(suicide==1) origin(time dob) enter(time doe) scale(365.25) id(id) exit(time d(31Aug2017))
	drop if _st!=1	
	
	* ensure patient only exits the study at failure event
	qui bysort id (_t):  gen _dsuicide =  _d==1 & suicide==1 & _n==_N
	lab val _dsuicide yn
	
	* generate person years
	gen pyrs = (_t-_t0)
	
	* split the data by follow-up time
	stsplit fu , at(0(0.5)1 2 3 5 10 100) after(time=doe)
	replace fu=4 if fu==3
	replace fu=3 if fu==2
	replace fu=2 if fu==1
	replace fu=1 if fu==0.5
	label define fu 0 "0-5 months" 1 "6-11 months" 2 "12-23 months" 3 "24-35 months" 4 "3-4 years" 5 "5-9 years" 10 "10+ years"
	label values fu fu

	* split the data by current age
	stsplit ageband, at(18 30 50(10)80 130) after(time=dob)
	label define ageband 18 "18-29 yrs" 30 "30-49 yrs" 50 "50-59 yrs" 60 "60-69 yrs" 70 "70-79 yrs" 80 "80+ yrs"
	label values ageband ageband2
	
	*  ensure patient only exits the study at failure event
	bysort id (_t):  replace _dsuicide =  _d==1 & _dsuicide==1 & _n==_N
	replace pyrs =(_t-_t0)
	sort id
	bysort id: keep if _n==_N
	
*--- Tables
	tab sex, miss
	tab cage, miss
	tab decdx, miss
	tab cancergroup2, miss
	tab gor_name, miss
	tab ethnicitygroup, miss
	tab primarytumours, miss
	tab fu, miss
	tab ageband, miss
	tab deprivation, miss
	
	tab sex dead, miss
	tab cage dead, miss
	tab decdx dead, miss
	tab cancergroup2 dead, miss
	tab gor_name dead, miss
	tab ethnicitygroup dead, miss
	tab primarytumours dead, miss
	tab fu dead, miss
	tab ageband dead, miss
	tab deprivation dead, miss
	
	tab sex _dsuicide, miss
	tab cage _dsuicide, miss
	tab decdx _dsuicide, miss
	tab cancergroup2 _dsuicide, miss
	tab gor_name _dsuicide, miss
	tab ethnicitygroup _dsuicide, miss
	tab primarytumours _dsuicide, miss
	tab fu _dsuicide, miss
	tab ageband _dsuicide, miss
	tab deprivation _dsuicide, miss


