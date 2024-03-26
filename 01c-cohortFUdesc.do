**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Calculate the median follow-up time and attained age 
** Used in the cohort description text (not in a table)
**********************************************************************


*------------------------------------------------------------------------------------
*STSET the data by attained age
*------------------------------------------------------------------------------------	

*--- Read in the formatted data		
	use "$data/x-suicide-e3-1899" , clear
	capture drop __000001
	
*--- Stset by attained age:	
	stset dox , fail(suicide==1) origin(dob) enter(doe) scale(365.25) id(id) exit(suicide==1 time d(31Aug2017))
	drop if _st==0

*--- ensure patient only exits the study at failure event
	qui bysort id (_t):  gen _dsuicide =  _d==1 & suicide==1 & _n==_N
	lab val _dsuicide yn

*--- generate person years
	gen pyrs = (_t-_t0)

*--- summarise the data	
	summ _t, detail
	summ _t if _dsuicide==1, detail
		
*--- get the time at risk:
	stdes
	
*------------------------------------------------------------------------------------
*STSET by FU 
*------------------------------------------------------------------------------------	

*--- Read in the formatted data		
	use "$data/x-suicide-e3-1899" , clear
	capture drop __000001

*--- Stset by follow-up:
	stset dox , fail(suicide==1) origin(doe) enter(doe) scale(365.25) id(id) exit(suicide==1 time d(31Aug2017))
	drop if _st==0	

*--- ensure patient only exits the study at failure event
	qui bysort id (_t):  gen _dsuicide =  _d==1 & suicide==1 & _n==_N
	lab val _dsuicide yn

*--- generate person years
	gen pyrs = (_t-_t0)

*--- summarise the data		
	summ _t, detail
	summ _t if _dsuicide==1, detail

