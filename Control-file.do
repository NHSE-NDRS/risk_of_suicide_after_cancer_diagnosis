**********************************************************************
** Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
** Control script - all scripts are run from this file
**********************************************************************

*--Prior to running this file extract the data using SQL script 'Data_extraction_from_CAS.sql'

*--- Pre run settings
set more off

*--- set up globals for file locations
global data "Filelocation\Data"
global scripts "Filelocation\FinalScripts"
global genpop "Filelocation\PopRate"
global results "Filelocation\ResultsNov"

*--- set the working directory to call script files
cd "$scripts"

*--- install required packages
* ssc install estout, replace
* ssc install smrby, replace

*--- Data setup
do 01a-datasetup
 
*--- Table 1 - Patient characteristics
do 01b-patientcharacteristics

*--- For text - cohort descriptions of follow up
do 01c-cohortFUdesc

*--- Table 2 - 5: SMRs and AERs by factors and O / E values 
* Stset data, and calculate SMRs
do 02a-SMRAER
*Calculate heterogeneity and trend tests
do 02b-heteogeneity

*--- Adjusted rate ratios and EMRs for Tables 2 and 3
do 04a-RR-RERs

*---  Efigure - cumulative risk of suicide by attained age
do 02c-cumrisk

*--- Figure 1 - visualisation of SMR and AER trend
do 03d-figure1

*--- Supplementary table 5 - SMRs and AERs by stage for 2012+
do 03b-stage-analysis //still to annotate

