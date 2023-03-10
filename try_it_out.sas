/*******************************************************************************
Author: Kyle Grealis
email: kylegrealis@icloud.com

Revised: February 24, 2023

INSTRUCTIONS:
-	Create a project folder.
-	Move the "test.sas7dbat” dataset into the new project folder.
-	Run the %include (line 65) with a proper direction to the folder holding
	the MACRO_case_control.sas file.
-	Argument descriptions:
	a. 	folder_path: WITHOUT QUOTES like you would using PROC IMPORT, but only
			to the folder and not to a specific file.
			EXAMPLE ~/home/project
	b. 	dataset: The name of the dataset to be used.
	c.	id: The variable that holds the participant ID
	d.	case_control: The variable that will hold your case-control NUMERIC 
			information. Be sure to code cases=1 and controls=0.
	e.	num_var: Numeric variable name (e.g.--age)
	f.	num_range: DEFAULT value is 1. Therefore, if case age is 35, controls 
			aged 34-36 are eligible matches. If 0 is used, matching will be done on 
			exact numeric matching only.
	g.	variable1: Second matching variable (e.g.--gender)
	h.	variable2: Optional variable to us three total matching 
			criteria (e.g.--ethnicity)
 	i. 	ratio: Select a case-control ratio. DEFAULT is 2, meaning one case to
 			two controls.
	
EXAMPLE of how to use the macro:

%case_control_match(
		folder_path= ~/project,		/*-- be sure it matches to your folder with the dataset --*
		dataset= test_set,
		id= Participant_ID,
		case_control= Event,
		num_var= Age,
		num_range= 3,								/*-- age +/- 3 years --*
		variable1= Gender,
		variable2= Ethnicity,				/*-- OPTIONAL VARIABLE 	--*
		ratio= 2										/*-- 1:2 cases to controls --*
	);


More details are included in the MACRO_case_control.sas file. Check it out! :)

*******************************************************************************
LINE 51 will run the macro file for you. Just set the correct path to
the location of MACRO_case_control.sas and the arguments (lines 53-63).
*******************************************************************************/
%include "~/macro/MACRO_case_control.sas";

%case_control_match(
		folder_path= ~/project,		/*-- be sure it matches to your folder with the dataset --*/
		dataset= test_set,
		id= Participant_ID,
		case_control= Event,
		num_var= Age,
		num_range= 3,								/*-- age +/- 3 years --*/
		variable1= Gender,
		variable2= Ethnicity,				/*-- OPTIONAL VARIABLE 	--*/
		ratio= 2										/*-- 1:2 cases to controls --*/
	);



	
