/* Assign library */
LIBNAME epi207 "/home/u64409551/EPI207_temp";
LIBNAME chis "/home/u64409551/CHIS2025";

%INCLUDE "/home/u64409551/CHIS2025/ADULT_PROC_FORMAT.SAS";

/* Load CHIS 2025 data onto WORK library &Copy the pre-formatted dataset */
DATA all;
    SET epi207.adult25;
    %INCLUDE "/home/u64409551/CHIS2025/ADULT_LABEL.SAS";
    %INCLUDE "/home/u64409551/CHIS2025/ADULT_FORMAT.SAS";
RUN;
/*WORK.ALL has 22036 observations and 886 variables.*/

PROC CONTENTS data=all;
RUN;

/*Variables used for the study:
1. Exposure
VISITED DOCTOR IN PAST 12 MOS (DOCT_YR)

2. Outcome
ER VISIT WITHIN THE PAST YEAR (ER)

3. Covarites
Age (SRAGE_P1)
General  health condition (AB1)
Insurance status (INSANY)
FPL level (POVLL)
General health condition (AB1)
Any chronic risk factor (asthma, diabetes, heart disease) (RISK3)

4. Effect modifiers
REASON WENT TO ER: MEDICAL/MENTAL HEALTH EMERGENCY (AH153_1)
REASON WENT TO ER: DIFFICULTY GETTING APPT WITH HEALTH PRO (AH153_2)
REASON WENT TO ER: ONLY OPTION FOR TREATMENT (AH153_3)
*/

/*Table 1: Weighted means, N(%)*/
PROC SURVEYFREQ DATA=all
    VARMETHOD=JACKKNIFE;
    WEIGHT RAKEDW0;
    REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;
    TABLES ER SRAGE_P1 INSANY POVLL AB1 RISK3 DOCT_YR
       / NOSTD ROW; 
RUN;

/*Table 1 - stratified by doctor's visit - Weighted means, N(%)*/
PROC SURVEYFREQ DATA=all
    VARMETHOD=JACKKNIFE;
    WEIGHT RAKEDW0;
    REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;
    TABLES DOCT_YR * (ER SRAGE_P1 INSANY POVLL AB1 RISK3)
       / NOSTD ROW;   
RUN;


/* TABLE 2: Logistic regression*/

/*Crude OR*/                         
PROC SURVEYLOGISTIC DATA = all
     VARMETHOD=JACKKNIFE;  
     WEIGHT RAKEDW0;                                      
     REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;   
     CLASS DOCT_YR (REF=LAST) / PARAM=REF;   /*ref: not visited doctor (2=No)*/            
     MODEL ER (EVENT=FIRST) = DOCT_YR ;
RUN;

/* TABLE 2: Stratified Logistic regression by reasons of ER visit*/
PROC FREQ data=all;
TABLES AH153_1 AH153_2 AH153_3;
RUN;

DATA all_2;
    SET all;
    IF AH153_1 = -1 THEN AH153_1 = .;
    IF AH153_2 = -1 THEN AH153_2 = .;
    IF AH153_3 = -1 THEN AH153_3 = .;
RUN;

PROC FREQ DATA=all_2;
    TABLES AH153_1 * ER * DOCT_YR
           AH153_2 * ER * DOCT_YR
           AH153_3 * ER * DOCT_YR
    / LIST MISSING;
RUN;

/* This code below is invalid and generates the following error:
"ERROR: All observations have the same response.  No statistics are computed."
It appears that ER visit reason (AHR153_1 - AHR153_3) was collected only among those who visited ER 
(i.e those who had outcome). Therefore, when we restrict to the subgroup who reported ER visit reason (by using DOMAIN statement), 
, there are 0 non-ER visitors (ER = 2) to serve as a comparison group, making the odds of ER visit unestimable.*/


/*PROC SURVEYLOGISTIC DATA = all_2
     VARMETHOD=JACKKNIFE;  
     WEIGHT RAKEDW0; 
     DOMAIN AH153_1;
     REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;
     CLASS DOCT_YR (REF=LAST) / PARAM=REF;               
     MODEL ER (EVENT=FIRST) = DOCT_YR ;
RUN;*/

/*c.f. This is what we think Group 1 did. They used the reason for ER visit (AH153_1 - AH153_3) as the outcome,
instead of ER visit, which is different from the original study purpose*/
PROC SURVEYLOGISTIC DATA = all_2
     VARMETHOD=JACKKNIFE;  
     WEIGHT RAKEDW0;                                      
     REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;
     DOMAIN ER;
     CLASS DOCT_YR (REF=LAST) / PARAM=REF;   /*ref: not visited doctor (2=No)*/            
     MODEL AH153_1 (EVENT=FIRST) = DOCT_YR ;
RUN;

              
/* Adjusted OR*/

/* Adjusted for age, insurance, gen health, pov level, chronic risk factors*/
PROC SURVEYLOGISTIC DATA = all
     VARMETHOD=JACKKNIFE;  
     WEIGHT RAKEDW0;                                      
     REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;   
     CLASS DOCT_YR (REF=LAST) / PARAM=REF;                  
     MODEL ER (EVENT='1') = DOCT_YR SRAGE_P1 INSANY AB1 POVLL RISK3 ;
RUN;

/*For the same reason described above, codes below for stratified & adjusted OR cannot be performed*/
/*PROC SURVEYLOGISTIC DATA = all
     VARMETHOD=JACKKNIFE;  
     WEIGHT RAKEDW0;                                      
     REPWEIGHTS RAKEDW1-RAKEDW80 / JKCOEFS=1;   
     DOMAIN AH153_1;
     CLASS DOCT_YR (REF=LAST) / PARAM=REF;                  
     MODEL ER (EVENT='1') = DOCT_YR SRAGE_P1 INSANY AB1 POVLL RISK3 ;
RUN;*/


/*End of Code*/



