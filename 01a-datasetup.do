**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Format the data for analysis
**********************************************************************
	
*--- Read in CSV lookup files and save as DTA files to call later

*Cancer group lookup - this contains ICD 10 3 digit codes and associated cancer group
insheet using "CancerGroupLookup.csv", c clear n
save "$data/cancerlookup", replace

*Cause of Death errors -- this contains patient identifier and error in cause of death information
insheet using "COD_ERROR_LOOKUP.csv", c clear n
save "$data/coderrorlookup", replace
	
	
*--- Read in CSV of raw data and save as DTA files to call later
import delimited Suicide_Final_220318.csv
save  "$data/x-suicide-rawdata_e3" , replace


*--- Read in the data	
use  "$data/x-suicide-rawdata_e3" , clear
	
capture drop __000001
	
*--- check for duplicates
	codebook tumourid //tumour identifier
	codebook patientid //patient identifier
	
*--- Rename the extracted suicide variables and tabulate to check numbers are as expected
	rename suicide_2 suicide	
	rename suicide_cause_2 suicide_cause
	
	tabulate suicide
	tabulate suicide_cause
	
	tabulate new_vitalstatus if suicide==1
	tabulate new_vital_desc if suicide==1
	
*--- Keep if suicide CoD is underlying to match ONS suicide publications
*--- but first lets have a look in more detail at the causes of suicide

	tab suicide_cause suicide
	br if suicide_cause=="2"
	br tumourid patientid if suicide_cause=="2"
	
/*	Suicide must be in both cause 2 and the underlying - it can't be in cause 2 alone 
	If it's mentioned in the text but the codes are contradictory then still take it 
	
	A number of the patients are missing an 'E' at the beginning of the code for the underlying
	ONS confirmed that they should have an E	
*/
	replace suicide=0 if patientid == ##### 
	tab suicide_cause suicide	
	

	
*--- Merge in the cancer groupings 

	gen tumour_icd = upper(tumour_site)
*	replace tumour_icd = subinstr(tumour_icd," ",.)
	merge m:m tumour_icd using "$data/cancerlookup"
	tab tumour_icd if _merge!=3
	* a few of observations have come through who have E85, O01, Q85 -- drop these
	* 18 cancer sites in the lookup don't have data rows -- D codes -- they are not cancers
	drop if _merge!=3
	drop _merge

*--- Create cancer groupings as factor variables

	rename cancergroup cancergroupstr
	
	gen cancergroup2	=1 if cancergroupstr == "Bladder"
	recode cancergroup2 .=2 if cancergroupstr == "Breast"
	recode cancergroup2 .=3 if cancergroupstr == "Cancer of Unknown Primary"
	recode cancergroup2 .=4 if cancergroupstr == "Central Nervous System (incl brain) malignant"
	recode cancergroup2 .=5 if cancergroupstr == "Cervix"
	recode cancergroup2 .=6 if cancergroupstr == "Colorectal"
	recode cancergroup2 .=7 if  strmatch(lower(cancergroupstr), "*head and neck*") 
*	recode cancergroup2 .=7 if cancergroupstr == "Head and neck – Larynx" | cancergroupstr == "Head and Neck - non specific" | cancergroupstr == "Head and neck - Other (excl. oral cavity, oropharynx, larynx & thyroid)" 	| cancergroupstr == "Head and neck - Oral cavity" 	| cancergroupstr == "Head and neck - Oropharynx" 	| cancergroupstr == "Head and neck - Other (excl. oral cavity, oropharynx, larynx & thyroid)" | cancergroupstr == "Head and neck – Thyroid"
*	recode cancergroup .=7 if cancergroupstr == "Head and neck - Larynx"
*	recode cancergroup .=8 if cancergroupstr == "Head and Neck - non specific" | cancergroupstr == "Head and neck - Other (excl. oral cavity, oropharynx, larynx & thyroid)"
*	recode cancergroup .=9 if cancergroupstr == "Head and neck - Oral cavity"
*	recode cancergroup .=10 if cancergroupstr == "Head and neck - Oropharynx"
*	recode cancergroup .=8 if cancergroupstr == "Head and neck - Other (excl. oral cavity, oropharynx, larynx & thyroid)"
*	recode cancergroup .=12 if cancergroupstr == "Head and neck - Thyroid"
	recode cancergroup2 .=13 if cancergroupstr == "Hodgkin lymphoma"
	recode cancergroup2 .=14 if cancergroupstr == "In situ neoplasms"
	recode cancergroup2 .=15 if cancergroupstr == "Kidney and unspecified urinary organs"
	recode cancergroup2 .=16 if cancergroupstr == "Leukaemia: acute myeloid" | cancergroupstr == "Leukaemia: other (all excluding AML and CLL)"
*	recode cancergroup .=16 if cancergroupstr == "Leukaemia: other (all excluding AML and CLL)"
	recode cancergroup2 .=18 if cancergroupstr == "Liver"
	recode cancergroup2 .=19 if cancergroupstr == "Lung"
	recode cancergroup2 .=20 if cancergroupstr == "Melanoma"
	recode cancergroup2 .=21 if cancergroupstr == "Mesothelioma"
	recode cancergroup2 .=22 if cancergroupstr == "Multiple myeloma"
	recode cancergroup2 .=23 if cancergroupstr == "Non melanoma skin cancer"
	recode cancergroup2 .=24 if cancergroupstr == "Non-Hodgkin lymphoma"
	recode cancergroup2 .=25 if cancergroupstr == "Oesophagus"
	recode cancergroup2 .=26 if cancergroupstr == "Other malignant neoplasms"
	recode cancergroup2 .=27 if cancergroupstr == "Ovary"
	recode cancergroup2 .=28 if cancergroupstr == "Pancreas"
	recode cancergroup2 .=29 if cancergroupstr == "Prostate"
	recode cancergroup2 .=30 if cancergroupstr == "Sarcoma: connective and soft tissue" | cancergroupstr == "Sarcoma: other"
*	recode cancergroup .=30 if cancergroupstr == "Sarcoma: other"
	recode cancergroup2 .=32 if cancergroupstr == "Stomach"
	recode cancergroup2 .=33 if cancergroupstr == "Testis"
	recode cancergroup2 .=34 if cancergroupstr == "Uterus"
	recode cancergroup2 .=35 if cancergroupstr == "Vulva"
	
	tab cancergroupstr if cancergroup2==. 
			
	label define cancerlab4 1 "Bladder" 2 "Breast" 3 "Cancer of Unknown Primary" 4 "Central Nervous System (incl brain) malignant" 5 "Cervix" 6 "Colorectal" 7 "Head and neck " 13 "Hodgkin lymphoma" 14 "In situ neoplasms" 15 "Kidney and unspecified urinary organs" 16 "Leukaemia" 18 "Liver" 19 "Lung" 20 "Melanoma" 21 "Mesothelioma" 22 "Multiple myeloma" 23 "Non melanoma skin cancer" 24 "Non-Hodgkin lymphoma" 25 "Oesophagus" 26 "Other malignant neoplasms" 27 "Ovary" 28 "Pancreas" 29 "Prostate" 30 "Sarcoma" 32 "Stomach" 33 "Testis" 34 "Uterus" 35 "Vulva"
	label values cancergroup2 cancerlab4
	
*--- Create a factor variable for deprivation
* use the deprivation_quintile variable as it combines the specific quintiles by diagnosis year

	tab deprivation_quintile, miss
	* Missing person is diagnosed in 2009, so use 2010 deprivation ID
	* However, 2010 deprivation is also missing, so use 2015
	replace deprivation_quintile = quintile2015 if deprivation_quintile==""

	gen deprivation=1 if deprivation_quintile =="1 - least deprived"
	recode deprivation .=2 if deprivation_quintile =="2"
	recode deprivation .=3 if deprivation_quintile =="3"
	recode deprivation .=4 if deprivation_quintile =="4"
	recode deprivation .=5 if deprivation_quintile =="5 - most deprived"
	label define deprivation 1 "1 - least deprived" 2 "2" 3 "3" 4 "4" 5 "5 - most deprived" 
	label values deprivation deprivation
	
	tab deprivation, miss
	br if deprivation==.
	
*--- Format date variables 

* diagnosisdate: doe
	gen doe1 = subinstr(diagnosisdatebest,"JAN","01",.)
	gen doe2 = subinstr(doe1,"FEB","02",.)
	gen doe3 = subinstr(doe2,"MAR","03",.)
	gen doe4 = subinstr(doe3,"APR","04",.)
	gen doe5 = subinstr(doe4,"MAY","05",.)
	gen doe6 = subinstr(doe5,"JUN","06",.)
	gen doe7 = subinstr(doe6,"JUL","07",.)
	gen doe8 = subinstr(doe7,"AUG","08",.)
	gen doe9 = subinstr(doe8,"SEP","09",.)
	gen doe10 = subinstr(doe9,"OCT","10",.)
	gen doe11 = subinstr(doe10,"NOV","11",.)
	gen doe12 = subinstr(doe11,"DEC","12",.)
	gen doe13 = subinstr(doe12,"-","",.)
	
	gen str2 doemo = substr(doe13,3,4)
	gen str4 doeyr = substr(doe13,5,8)
	gen str2 doeda = substr(doe13,1,2)
	destring doemo, replace
	destring doeda, replace
	destring doeyr, replace
	
	tab doemo
	tab doeda
	tab doeyr

	gen doe = mdy(doemo, doeda, doeyr)
	format doe %td

* date of death : dod

	rena doexit dodeath
	gen dod1 = subinstr(dodeath,"JAN","01",.)
	gen dod2 = subinstr(dod1,"FEB","02",.)
	gen dod3 = subinstr(dod2,"MAR","03",.)
	gen dod4 = subinstr(dod3,"APR","04",.)
	gen dod5 = subinstr(dod4,"MAY","05",.)
	gen dod6 = subinstr(dod5,"JUN","06",.)
	gen dod7 = subinstr(dod6,"JUL","07",.)
	gen dod8 = subinstr(dod7,"AUG","08",.)
	gen dod9 = subinstr(dod8,"SEP","09",.)
	gen dod10 = subinstr(dod9,"OCT","10",.)
	gen dod11 = subinstr(dod10,"NOV","11",.)
	gen dod12 = subinstr(dod11,"DEC","12",.)
	gen dod13 = subinstr(dod12,"-","",.)
	
	
	gen str2 dodmo = substr(dod13,3,4)
	gen str4 dodyr = substr(dod13,5,8)
	gen str2 dodda = substr(dod13,1,2)
	destring dodmo, replace
	destring dodda, replace
	destring dodyr, replace
	
	gen dod = mdy(dodmo, dodda, dodyr)
	format dod %td

	
* date of birth: dob	
	
	gen dob1 = subinstr(birthdatebest,"JAN","01",.)
	gen dob2 = subinstr(dob1,"FEB","02",.)
	gen dob3 = subinstr(dob2,"MAR","03",.)
	gen dob4 = subinstr(dob3,"APR","04",.)
	gen dob5 = subinstr(dob4,"MAY","05",.)
	gen dob6 = subinstr(dob5,"JUN","06",.)
	gen dob7 = subinstr(dob6,"JUL","07",.)
	gen dob8 = subinstr(dob7,"AUG","08",.)
	gen dob9 = subinstr(dob8,"SEP","09",.)
	gen dob10 = subinstr(dob9,"OCT","10",.)
	gen dob11 = subinstr(dob10,"NOV","11",.)
	gen dob12 = subinstr(dob11,"DEC","12",.)
	gen dob13 = subinstr(dob12,"-","",.)
		
	gen str2 dobmo = substr(dob13,3,4)
	gen str4 dobyr = substr(dob13,5,8)
	gen str2 dobda = substr(dob13,1,2)
	destring dobmo, replace
	destring dobda, replace
	destring dobyr, replace
	
	gen dob = mdy(dobmo, dobda, dobyr)
	format dob %td
	
* date of vital status 	
	gen dovs1 = subinstr(new_vitalstatusdate,"JAN","01",.)
	gen dovs2 = subinstr(dovs1,"FEB","02",.)
	gen dovs3 = subinstr(dovs2,"MAR","03",.)
	gen dovs4 = subinstr(dovs3,"APR","04",.)
	gen dovs5 = subinstr(dovs4,"MAY","05",.)
	gen dovs6 = subinstr(dovs5,"JUN","06",.)
	gen dovs7 = subinstr(dovs6,"JUL","07",.)
	gen dovs8 = subinstr(dovs7,"AUG","08",.)
	gen dovs9 = subinstr(dovs8,"SEP","09",.)
	gen dovs10 = subinstr(dovs9,"OCT","10",.)
	gen dovs11 = subinstr(dovs10,"NOV","11",.)
	gen dovs12 = subinstr(dovs11,"DEC","12",.)
	gen dovs13 = subinstr(dovs12,"-","",.)
	
	gen str2 dovsmo = substr(dovs13,3,4)
	gen str4 dovsyr = substr(dovs13,5,8)
	gen str2 dovsda = substr(dovs13,1,2)
	destring dovsmo, replace
	destring dovsda, replace
	destring dovsyr, replace
	
	gen dovs = mdy(dovsmo, dovsda, dovsyr)
	format dovs %td


	drop doe1 doe2 doe3 doe4 doe5 doe6 doe7 doe8 doe9 doe10 doe11 doe12 doe13 doemo doeyr doeda
	drop dob1 dob2 dob3 dob4 dob5 dob6 dob7 dob8 dob9 dob10 dob11 dob12 dob13 dobmo dobyr dobda
	drop dod1 dod2 dod3 dod4 dod5 dod6 dod7 dod8 dod9 dod10 dod11 dod12 dod13 dodmo dodyr dodda
	drop dovs1 dovs2 dovs3 dovs4 dovs5 dovs6 dovs7 dovs8 dovs9 dovs10 dovs11 dovs12 dovs13 dovsmo dovsyr dovsda
	
	
*--- Create a date of exit variable -- accounts for lost to follow-up, and end of follow-up if they haven't died 
	gen dox = dod if dod!=.
	replace dox = dovs if dox==.
	**manual adjustment to account for the fact that the vital status date follow-up is shorter than the date of death follow-up
	**this assumes that if a patient was alive in oct '16, then they wouldn't be lost to follow-up by august '17
	replace dox = d(31Aug2017) if dod==. & dovs >= d(30Sep2016)
	format dox %td
	
	*There are instances where the date of cancer diagnosis is just after their date of death.  
	*None of these are suicides
	
	gen test = doe - dox if doe>dox
	tab test 
	br test doe dox if doe>dox
	
	*If there are two weeks between then it is a data quality issue
	*and put their date of diagnosis as their date of death

	replace dox = doe + 1 if doe>dox & doe-dox>=0 & doe-dox<15
	
	
	*If there are more than two weeks between then drop 
	
	drop if doe>dox & doe-dox>=15 & doe-dox<42500
	
	
*--- Some people were diagnosed and died on the same day - add 1 day to their date of exit for survival purposes 
	
	replace dox = dox + 1 if dox==doe
	
	*if people exit on the first day of the study (1Jan1995) -- need to add a day onto these to allow the stsplit to work
	
	replace dox = dox + 1 if dox==d(01Jan1995)
	
	
*--- Calculate survival
	
	gen surv = round(((dox - doe)/365.24) , 0.01)
	assert surv>=0 & surv<.
	
*--- Create a variable which identifies if the patient has died

	gen byte dead = 1
	replace dead = 0 if dod==.
	lab var dead "Dead indicator variable"
	label define ynfmt 0 "No" 1 "Yes"
	label values dead ynfmt	

*--- Format ethnicity variable	

	tab ethnicity

	gen Ethnic=1 if ethnicity =="A"| ethnicity =="B" | ethnicity =="C" | ethnicity =="0"
	recode Ethnic .=2 if ethnicity =="D"| ethnicity =="E"| ethnicity =="F"| ethnicity =="G"
	recode Ethnic .=3 if ethnicity =="H"| ethnicity =="J"| ethnicity =="K"| ethnicity =="L"
	recode Ethnic .=4 if ethnicity =="M"| ethnicity =="N"| ethnicity =="P"
	recode Ethnic .=5 if ethnicity == "S" | ethnicity =="R" | ethnicity =="8"
	recode Ethnic .=6 if ethnicity == "Z"
	recode Ethnic .=7 if ethnicity == "" | ethnicity =="X" | ethnicity =="CA" | ethnicity =="CB"| ethnicity =="GF"
	rename Ethnic ethnicitygroup
	label define ethnic 1 "White" 2 "Mixed" 3 "Asian" 4 "Black" 5 "Other" 6 "Not Stated" 7 "Unknown"
	label values ethnicitygroup ethnic
	
*--- Create variable with number of primary malignant tumours
	tab tumour_site if bigtumourcount == 0
	gen primarytumours = .
	replace primarytumours = 0 if bigtumourcount == 0 
	*these are people with in situ tumours or C44
	replace primarytumours = 1 if bigtumourcount == 1
	replace primarytumours = 2 if bigtumourcount == 2 
	replace primarytumours = 3 if bigtumourcount > 2 

*--- Create and label the calendar year of diagnosis variable	
	
	gen decade = year(doe)
	egen decdx = cut(decade), at (1995, 2000, 2005, 2010, 2016)
	label define decdx 1995 "1995-1999" 2000 "2000-2004" 2005 "2005-2009" 2010 "2010-2015"
	label values decdx decdx
	
*--- Create and label the age at diagnosis variable 
	gen cagedx = (doe - dob)/365.25
	
*--- Drop children and over 100
	drop if cagedx < 18
	drop if cagedx > 99	

*--- Create age group variable
	egen cage = cut(cagedx), at(18, 30, 50, 60, 70, 80, 130)
	label define age_dxs 18 "18-29 yrs" 30 "30-49 yrs" 50 "50-59 yrs" 60 "60-69 yrs" 70 "70-79 yrs" 80 "80+ yrs" 
	label values cage age_dxs	
	
*--- Label the sex variable
	label define sex 1 "Male" 2 "Female" 
	label values sex sex 	
	
*--- remove vulva as a group - put in other malignant neoplasms
	replace cancergroup2 = 26 if cancergroup2 == 35
	
*--- Use a generic ID number for the analysis
	gen id = _n	
	
*--- Save the data
	save  "$data\x-suicide-e3-1899" , replace
	


	
