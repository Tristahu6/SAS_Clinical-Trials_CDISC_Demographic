/****************************************************************************/
/*         PROGRAM NAME: SAS Coding Mastery in Clinical Trials              */
/*                       - Demographic Data Analysis                        */
/*                                                                          */
/*          DESCRIPTION: This script is part of an exercise designed to     */
/*                       enhance proficiency in SAS programming within the  */
/*                       context of Clinical Trials, adhering to CDISC      */
/*                       standards. It focuses on applying best practices   */
/*                       in data handling, transformation, and analysis in  */
/*                       line with industry norms.                          */
/*                                                                          */
/*                       The tasks include importing, cleaning,             */
/*                       transforming, and structurally validating the      */
/*                       demographic data, ensuring it meets the quality    */
/*                       standards required for clinical trial analysis     */
/*                       and reporting.                                     */
/*                                                                          */
/*            Objective: By the end of this exercise, the expected outcome  */
/*                       is to achieve a refined understanding and          */
/*                       application of SAS coding techniques in a clinical */
/*                       trial context, with a particular emphasis on data  */
/*                       integrity, standardization, and compliance with    */
/*                       CDISC guidelines.                                  */
/*                                                                          */
/*                NOTES: Data Source and Authenticity:                      */
/*                       Due to the limited availability of actual          */
/*                       healthcare trial data, the dataset used in this    */
/*                       exercise was synthetically generated using ChatGPT.*/
/*                       The generation followed pre-established rules to   */
/*                       ensure realistic data structure while maintaining  */
/*                       the confidentiality and ethical standards by using */
/*                       entirely fictitious data.                          */
/*                                                                          */
/*               AUTHOR: Trista Hu                                          */
/*                                                                          */
/*                 DATE: Jan 6, 2024                                        */
/*                                                                          */
/****************************************************************************/

/* Begin SAS Script */
libname mydata '/home/u63651691/EPG1V2/data';
filename csvfile '/home/u63651691/EPG1V2/data/sample_dataset_raw.csv';
...

/* Rest of your SAS code */


/* Assign a library reference to a directory and import the csv raw file*/
libname mydata '/home/u63651691/EPG1V2/data';
filename csvfile '/home/u63651691/EPG1V2/data/sample_dataset_raw.csv';

proc import datafile=csvfile out=mydata.clinical_data dbms=csv replace;
	getnames=yes;
run;

/* Display the contents (metadata) of the dataset */
proc contents data=mydata.clinical_data;
run;


/* Create custom formats for SEX and RACE variables */
proc format;
	value $SEX 'Male'='M' 'Female'='F' 'f'='F' 'm'='M' '1'='M' '2'='F' 
		other='Others';
	value Race 1='White' 2='Asian' 3='Black or African American' 
		4='American Indian or Alaska Native' 
		5='Native Hawaiian or Other Pacific Islander' other='Others';
run;

/* Create or modify the DM dataset per SDTM standards. */
data mydata.DM(keep=STUDYID DOMAIN USUBJID SUBJID RFICDTC SITEID INVID INNAM 
		BRTHDTC AGE AGEU SEX RACE ETHNIC ACTARM COUNTRY DMDTC);
	set mydata.clinical_data;
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
	ACTARM='DRUGA';
	ETHNIC='NOT REPORTED';
	format sex $SEX. RACE Race.;
	label USUBJID='Unique Subject Identifier' STUDYID='Study Identifier' 
		DOMAIN='Domain Abbreviation' SUBJID='Subject Identifier' SEX='Sex' 
		RACE='Race' ARMCD='Treatment Arm Code' DMDTC='Date/Time of Collection' 
		DMDY='Study Day of Collection';
run;

/* Sort the DM dataset by Subject Identifier.*/
proc sort data=mydata.DM;
	by SUBJID;
run;



