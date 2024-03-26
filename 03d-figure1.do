**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Produce graph of the trend with follow-up period (Figure 1)
**********************************************************************
	
*------------------------------------------------------------------------------------
*Import data - created manually using output from 02a-smraer.do
*------------------------------------------------------------------------------------	

insheet using "$results\SMR_FU_forFigure_27Apr18.csv", c clear n
/* This file contains 8 columns with:	
 - Time (integer 1 to 7)
 - Time label (0-5 months, 6-11 months, 12-23 months, 23-35 months, 3-4 years, 5-9 years, 10+ years)
 - SMR estimate
 - SMR lower confidence interval
 - SMR upper confidence interval
 - AER estimate
 - AER lower confidence interval
 - AER upper confidence interval
*/


*------------------------------------------------------------------------------------
*Create connected line plots of SMRs and AERs and combine the graphs
*------------------------------------------------------------------------------------			

*--- generate time variable with label
	gen times =1 if time == 1
	recode times .=2 if time == 2
	recode times .=3 if time == 3
	recode times .=4 if time == 4
	recode times .=5 if time == 5
	recode times .=6 if time == 6
	recode times .=7 if time == 7

	label define times 1 "0-5 months" 2 "6-11 months" 3 "1- years" 4 "2- years" 5 "3-4 years" 6 "5-9 years" 7 "10+ years" 
	label values times times

*--- connected line plot of SMRs
	twoway connected smrest times, clc(blue) clp(l) || line smrli smrui times, clp(dot dot) clc(blue blue) legend(off) ylab(0(0.5)3) ytitle("SMR for death by suicide with confidence interval") xtitle("Follow-up period") xlabel(1 `" "0-5" "months" "' 2 `" "6-11" "months" "' 3 `" "12-23" "months" "' 4 `" "24-35" "months" "' 5 `" "3-4" "years" "' 6 `" "5-9" "years" "' 7 `" "10+" "years" "', labsize(small)) graphregion(color(white)) bgcolor(white) saving($results\smrfu, replace)

*--- connected line plot of AERs	
	twoway connected aerest times, clc(green) clp(l) || line aerli aerui times, clp(dot dot) clc(green green) legend(off) ylab(-1(0.5)2) ytitle("AER per 10,000 for death by suicide with confidence interval") xtitle("Follow-up period") xlabel(1 `" "0-5" "months" "' 2 `" "6-11" "months" "' 3 `" "12-23" "months" "' 4 `" "24-35" "months" "' 5 `" "3-4" "years" "' 6 `" "5-9" "years" "' 7 `" "10+" "years" "', labsize(small)) graphregion(color(white)) bgcolor(white) saving($results\aerfu, replace)

* combine the two plots into one		
	graph combine $results\smrfu.gph  $results\aerfu.gph, graphregion(color(white)) t1("Variation in risk of death by suicide by follow-up period")  

*export the plots	
	graph export "$results\FUvariation_31May18.tif", as(tif) replace width(4000) 
	
	graph export "$results\FUvariation_12Jul18.eps", as(eps) replace logo(off) fontface("Calibri")


	
	
	
	
	
	