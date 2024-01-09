/* Assign a library reference to a directory and import the csv raw file */
libname mydata '/home/u63651691/EPG1V2/data';
filename csvfile '/home/u63651691/EPG1V2/data/sample_dataset_raw.csv';

proc import datafile=csvfile out=mydata.clinical_data dbms=csv replace;
	getnames=yes;
run;

/* Display the metadata of the dataset */
proc contents data=mydata.clinical_data;
run;

/* Create custom formats for SEX and RACE variables */
proc format;
	value $SEX 'Male'='M' 'Female'='F' 'f'='F' 'm'='M' '1'='M' '2'='F' other='U';
	value Race 1='White' 2='Asian' 3='Black or African American' 
		4='American Indian or Alaska Native' 
		5='Native Hawaiian or Other Pacific Islander' other='Other';
	value arm 1='DRUGA' 2='DRUGB' 3='Placebo';
	value ARMCD 1='DA123' 2='DB123' 3='PLACEBO';
run;

/* Create or modify the DM dataset per SDTM standards. */
data mydata.DM(keep=STUDYID DOMAIN USUBJID SUBJID RFICDTC SITEID INVID INNAM 
		BRTHDTC AGE AGEU SEX RACE2 ETHNIC COUNTRY DMDTC);
	set mydata.clinical_data;
	length SUBJID $15;
	RACE2=put(RACE, Race.);
	STUDYID="STUDY20240001";
	DOMAIN="DM";
	SUBJID=strip(SUBJECT);
	SITEID=strip(SITE);
	BRTHDTC=put(BRTHDT, IS8601da.);
	USUBJID=catx('-', studyid, SITE, SUBJECT);
	COUNTRY='USA';
	INVID='BU7777';
	INNAM='TristaXX';
	DMDTC=put(datepart(ENTRYDATE), is8601da.);
	AGE=floor((datepart(ENTRYDATE) - BRTHDT) / 365.25);
	AGEU='Years';
	ETHNIC='NOT REPORTED';
	format sex $SEX.;
	label STUDYID='study identifier' DOMAIN='domain abbreviation' 
		USUBJID='unique subject identifier' SUBJID='subject identifier for the study' 
		RFSTDTC='subject reference startdae / time' 
		RFENDTC='subect reference enddate/time' 
		RFXSTDTC='Date/Time of first study treatment' 
		RFXENDTC='Date/Time of Last Study Treatment' 
		RFICDTC='Date/Time of Informed Consent Signed' 
		RFPENDTC='Date/Time of End of Participation' DTHDTC='Date/Time of Death' 
		DTHFL='Subject Death Flag' SITEID='Study Site Identifier' 
		BRTHDTC='Date/Time of Birth' AGE='Age' AGEU='Age Units' SEX='sex' RACE='race' 
		ARMCD='Planned Arm Code' ARM='Description of Planned Arm' 
		ACTARMCD='Actual Arm Code' ACTARM='Description of Actual Arm' 
		COUNTRY='country';
run;

/* Mock study treatment dataset */
data mydata.dosing;
	infile datalines;
	length subjId $15;
	input subjId $ trt $ trt_date : date9.;
	format trt_date : date9.;
	datalines;
Subject001 DRUGA 09APR2020
Subject001 DRUGB 11MAY2020
Subject001 DRUGB 17JUL2020
Subject003 DRUGA 12SEP2020
Subject003 DRUGB 10OCT2020
Subject005 Placebo 11AUG2020
Subject008 DRUGA 13JUL2020
Subject008 DRUGB 31JUL2020
Subject008 Placebo 07SEP2020
Subject010 DRUGB 16JUN2020
Subject010 DRUGA 15SEP2020
;
run;

proc sort data=mydata.dosing out=treatment_details;
	by subjId trt_date;
run;

data treatment_details_final;
	set work.treatment_details;
	retain RFSTDTC RFENDTC;
	by subjId;

	if first.subjId then
		RFSTDTC=trt_date;

	if last.subjId then
		RFENDTC=trt_date;

	if last.subjId;
	RFXSTDTC=RFSTDTC;
	RFXENDTC=RFENDTC;
	format RFSTDTC RFENDTC RFXSTDTC RFXENDTC IS8601DA.;
run;

/* Mock Registration Dataset */
data icf_details;
	infile datalines dlm=",";
	length subjId $15;
	input subjId $
        term $:15. icfdate : date9.
        icftime : time8.;
	RFICDTC=dhms(icfdate, hour(icftime), minute(icftime), second(icftime));
	format icfdate : date9. icftime : time8. RFICDTC IS8601DT.;
	datalines;
    Subject001,ICF SIGNED,09APR2020,10:01:12
    Subject003,ICF SIGNED,12SEP2020,10:10:13
    Subject005,ICF SIGNED,11AUG2020,13:30:00
    Subject008,ICF SIGNED,13JUL2020,14:11:46
    Subject010,ICF SIGNED,16JUN2020,16:15:40
;
run;

/* Intergrate DM Treatment and ICF data */
proc sql;
	create table demographic_trt as select * from mydata.DM a left join 
		treatment_details_final b on a.SUBJID=b.subjId left join icf_details as c on 
		a.SUBJID=c.subjId order by 2;
quit;

/* Final clean up to create demographic domain per SDTM standards */
data demographic_final (drop=icfdate icftime trt_date);
	set demographic_trt;
	RFPENDTC=RFXENDTC+7;

	/* Assuming 1 week of follow up after the final dose RFPENDTC = RFXENDTC + 7 */
	format RFPENDTC IS8601DA.;
	DTHDTC='';

	if DTHDTC='' THEN
		DTHFL='N';
	rename Race2=RACE;
	rename trt=ACTARM;

	if trt='DRUGA' then
		ARMCD='DA123';
	else if trt='DRUGB' then
		ARMCD='DB123';
	else if trt='Placebo' then
		ARMCD='PLACEBO';
run;

proc sort data=demographic_final;
	by SUBJID USUBJID;
run;