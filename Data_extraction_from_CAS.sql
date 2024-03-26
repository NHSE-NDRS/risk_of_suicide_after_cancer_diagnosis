----------------------------------------------------------------------
-- Risk of Suicide After Cancer Diagnosis in England - JAMA Psychiatry
-- Data extraction from the National Disease Registration Dataset
----------------------------------------------------------------------

SELECT *
FROM 
    (SELECT DISTINCT 
      avt.patientid                                                 -- patient identifier
    , avt.tumourid                                                  -- tumour identifier
    , avt.site_icd10_o2_3char AS tumour_site                        -- ICD10 code 3 digits
    , D.dodeath AS doexit                                           -- date of death
    , avt.diagnosisdatebest                                         -- date of tumour diagnosis
    , avt.stage_best                                                -- stage at diagnosis
    , rtd.final_route                                               -- route of tumour diagnosis 
    , avt.birthdatebest                                             -- birth date of patient
    , avt.sex                                                       -- patient defined gender at diagnosis
    , avt.ethnicity                                                 -- ethnicity of patient
    , P.bigtumourcount                                              -- total number of tumours per patient
    , avt.gor_code                                                  -- government office region code
    , avt.gor_name                                                  -- government office region name
    , dep2.quintile_2015 AS quintile2015                            -- index of multiple deprivation using 2015 indices
    , dep.quintile2010                                              -- index of multiple deprivation using 2010 indices
    , dep.quintile2007                                              -- index of multiple deprivation using 2007 indices
    , dep.quintile2004                                              -- index of multiple deprivation using 2004 indices
    ,CASE WHEN avt.diagnosisyear >2009 THEN dep2.quintile_2015
    WHEN avt.diagnosisyear BETWEEN 2007 AND 2009 THEN dep.quintile2010
    WHEN avt.diagnosisyear BETWEEN 2003 AND 2006 THEN dep.quintile2007
    WHEN avt.diagnosisyear BETWEEN 1992 AND 2002 THEN dep.quintile2004
    ELSE 'Error'
    END AS deprivation_quintile                                     -- index of multiple deprivation according to year of diagnosis
    ,P.vitalstatus                                                  -- vital status of patient
    ,P.vitalstatusdate                                              -- vital status date of patient
    
    -- combine all cause of death on the death certificate into one variable
    ,CONCAT(CONCAT(D.underlyingcause,CONCAT(D.line1a,D.line1b)),CONCAT(D.line1c,D.line2)) AS cod    
    
    -- generate a variable to define where on death certificate the suicide is listed (line 1a, 1b, 1c, 2 or underlying cause of death)
    ,CASE WHEN substr(D.line1a,1,4) IN ('Y339') THEN 'Error'
    WHEN substr(D.line1a,1,5) IN ('E9888') THEN 'Error'
    WHEN substr(D.line1a,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	
    'X81',	'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	
    'Y33',	'Y34', 'E98') THEN '1A'
    WHEN substr(D.line1a,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1A'
    
    WHEN substr(D.line1b,1,4) IN ('Y339') THEN 'Error'
    WHEN substr(D.line1b,1,5) IN ('E9888') THEN 'Error'
    WHEN substr(D.line1b,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	'X81',
    'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	'Y33',	
    'Y34') THEN '1B'
    WHEN substr(D.line1b,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1B'
    
    WHEN substr(D.line1c,1,4) IN ('Y339') THEN 'Error'
    WHEN substr(D.line1c,1,5) IN ('E9888') THEN 'Error'
    WHEN substr(D.line1c,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	'X81',
    'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	'Y33',	
    'Y34') THEN '1C'
    WHEN substr(D.line1c,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1C'
    
    WHEN substr(D.line2,1,4) IN ('Y339') THEN 'Error'
    WHEN substr(D.line2,1,5) IN ('E9888') THEN 'Error'
    WHEN substr(D.line2,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	'X81',	
    'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	'Y33',	
    'Y34') THEN '2'
    WHEN substr(D.line2,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '2'
    
    WHEN substr(D.underlyingcause,1,4) IN ('Y339') THEN 'Error'
    WHEN substr(D.underlyingcause,1,5) IN ('E9888') THEN 'Error'
    WHEN substr(D.underlyingcause,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	
    'X81',	'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	
    'Y33',	'Y34') THEN 'Underlying'
    WHEN substr(D.underlyingcause,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN 'Underlying'
    
    
    ELSE 'Error'
    END AS suicide_cause_2
    
    -- generate flag to determine if person has suicide on death certificate
    , CASE WHEN substr(D.line1a,1,4) IN ('Y339') THEN '0'
    WHEN substr(D.line1a,1,5) IN ('E9888') THEN '0'
    WHEN substr(D.line1a,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	
    'X81',	'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	
    'Y33',	'Y34') THEN '1'
    WHEN substr(D.line1a,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1'
    
    WHEN substr(D.line1b,1,4) IN ('Y339') THEN '0'
    WHEN substr(D.line1b,1,5) IN ('E9888') THEN '0'
    WHEN substr(D.line1b,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	'X81',
    'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	'Y33',	
    'Y34') THEN '1'
    WHEN substr(D.line1b,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1'
    
    WHEN substr(D.line1c,1,4) IN ('Y339') THEN '0'
    WHEN substr(D.line1c,1,5) IN ('E9888') THEN '0'
    WHEN substr(D.line1c,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	'X81',
    'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	'Y33',	
    'Y34') THEN '1'
    WHEN substr(D.line1c,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1'
    
    WHEN substr(D.line2,1,4) IN ('Y339') THEN '0'
    WHEN substr(D.line2,1,5) IN ('E9888') THEN '0'
    WHEN substr(D.line2,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	'X81',	
    'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	'Y33',	
    'Y34') THEN '1'
    WHEN substr(D.line2,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1'
    
    WHEN substr(D.underlyingcause,1,4) IN ('Y339') THEN '0'
    WHEN substr(D.underlyingcause,1,5) IN ('E9888') THEN '0'
    WHEN substr(D.underlyingcause,1,3) IN ('X60',	'X61',	'X62',	'X63',	'X64',	'X65',	'X66',	'X67',	'X68',	'X69',	'X70',	'X71',	'X72',	'X73',	'X74',	'X75',	'X76',	'X77',	'X78',	'X79',	'X80',	
    'X81',	'X82',	'X83',	'X84', 'Y10',	'Y11',	'Y12',	'Y13',	'Y14',	'Y15',	'Y16',	'Y17',	'Y18',	'Y19',	'Y20',	'Y21',	'Y22',	'Y23',	'Y24',	'Y25',	'Y26',	'Y27',	'Y28',	'Y29',	'Y30',	'Y31',	'Y32',	
    'Y33',	'Y34') THEN '1'
    WHEN substr(D.underlyingcause,1,4) IN ('E950',	'E951',	'E952',	'E953',	'E954',	'E955',	'E956',	'E957',	'E958',	'E959','Y870','Y872') THEN '1'
    
    
    ELSE '0'
    END AS suicide_2
    
    -- generate a flag to tell you if the patient is alive, death with a cause of death or without cause of death
    ,CASE WHEN D.dodeath IS NULL THEN 'Alive'
    WHEN (D.dodeath IS NOT NULL AND CONCAT(CONCAT(D.underlyingcause,CONCAT(D.line1a,D.line1b)),CONCAT(D.line1c,D.line2)) IS NOT NULL) THEN 'Dead with Cause'
    WHEN (D.dodeath IS NOT NULL AND CONCAT(CONCAT(D.underlyingcause,CONCAT(D.line1a,D.line1b)),CONCAT(D.line1c,D.line2)) IS NULL) THEN 'Dead without Cause'
    ELSE 'Error'
    END AS death_cause_flag 
    
    -- For each patient generate a rank based on diagnosis date and tumourid (tumourid is added for the scenario where two or more tumours are diagnosed on the same day)
    ,RANK () OVER (PARTITION BY avt.patientid ORDER BY avt.diagnosisdatebest, avt.tumourid DESC ) AS RANK
    
    FROM av2015.av_tumour avt                                               -- table containting tumour characteristics
    INNER JOIN av2015.av_patient P ON avt.patientid = P.patientid           -- table containing patient characteristics
    LEFT JOIN av2015.cause_of_death D ON avt.patientid = D.patientid        -- table contain death certificate information
    LEFT JOIN imd.lsoa_income_quintiles dep ON avt.lsoa01_code = dep.lsoa   -- table containing deprivation quintiles
    LEFT JOIN id2015 dep2 ON avt.lsoa11_code = dep2.lsoa11_code             -- table containing 2015 deprivation quintiles
    LEFT JOIN av2014.rtd5_routes rtd ON avt.tumourid = rtd.tumourid         -- table containing routes to diagnosis for tumour
    
    --inclusion criteria
    WHERE 
    -- English resident
    avt.ctry_code ='E'
    -- Final registration 
    AND avt.statusofregistration ='F'
    -- Not duplicates
    AND avt.dedup_flag=1
    -- Sensible age
    AND avt.age BETWEEN 0 AND 200
    -- Known gender
    AND avt.sex IN (1,2)
    -- gender and site restrictions
    AND ((avt.sex = '2' AND avt.site_icd10_o2_3char NOT IN ('C60','C61','C62','C63'))
    OR (avt.sex = '1' AND  avt.site_icd10_o2_3char NOT IN ('C51','C52','C53','C54','C55','C56','C57','C58')))
    -- Invasive tumour which is not non-melanoma skin cancer
    AND substr(avt.site_icd10_o2,1,1)= 'C' AND avt.site_icd10_o2_3char <> 'C44'
    -- Years of interest
    AND (avt.diagnosisyear>1994
    AND avt.diagnosisyear<2016)
    -- not death certificate only
    AND avt.dco IN ('N')
    --and d.errorflag not in ('Multiple_CoD','No_CoD','No_match_NHS','No_match_NHS_ONS','Multiple_NHS_per_ONS')
    )

-- keep only the latest tumour per patient    
WHERE RANK=1

-- extract the table and saved as 'Suicide_Final_220318.csv'
;


