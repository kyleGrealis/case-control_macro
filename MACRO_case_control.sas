
/*******************************************************************************
Author: Kyle Grealis
email: kylegrealis@icloud.com

Date: January 23, 2023
Revised: March 10, 2023

References:
1.  Kawabata, H., Tran, M., & Hines, P. (2004). Using SAS to match cases for case 
				control studies. [Poster presentation]. SAS users group international 29. 
				Bristol-Myers Squibb, Princeton, New Jersey.
2.	Mortensen, L.Q., Andresen, K., Burcharth, J., Pommergaard, H., & Rosenberg, J. 
				(2019). Matching cases and controls using SAS software. Frontiers in big 
				data 2:4. Doi: 10.3389/fdata.2019.00004.
3.	Rose, S., & Laan, M. J. (2009). Why match? Investigating matched case-control 
				study designs with causal effect estimation. The international journal of 
				biostatistics, 5(1), 1. https://doi.org/10.2202/1557-4679.1127

The macro program is available for matching by 2 or 3 selection criteria. The
	variable2 argument allows to pass a third variable for matching. Arguments for 
	variable1 and variable2 can either be numeric or categorical.

Do NOT use quotations around variable names!

INSTRUCTIONS:
-	Create a project folder.
-	Move your dataset into the new project folder.
-	Argument descriptions:
	a. 	folder_path: WITHOUT QUOTES like you would using PROC IMPORT, but only
			to the folder and not to a specific file.
			EXAMPLE ~/home/project
	b. 	DSN: The name of the dataset to be used.
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
	
-	Highlight and Run %case_control_match();



-	The program will search for best matches based on exact matching, then
		by age range, if the provided age range is greater than 0.
-	The Results window will display a sample of case-control matched dataset. 
		The program iterates 100 times and will find the dataset with the 
		maximum number of sufficient case-control observations.
-	A second dataset is created that lists all cases that have insufficient 
		matches. For example, if the number of matched cases to controls is less than
		the supplied ratio, the case ID will be output to this dataset. Also, any controls
		that were matched to that case, though not achieving the matching ratio,
		will also be output to that dataset. A sample of this insufficiently
		matched dataset will also be displayed in the Results window, directly
		below the matched dataset sample.
-	Two PDF files, two CSV files, and two datasets will be created in 
		the project folder.
		
		
		
EXAMPLE of how to use the macro with ONLY 2 age and 1 other matching variable:
%case_control_match(
		folder_path= ~/project,		/*-- be sure it matches to your folder with the dataset --*
		DSN= test_set,
		id= Participant_ID,
		case_control= Event,
		num_var= Age,
		num_range= 3,								/*-- age +/- 3 years --*
		variable1= Gender,
		variable2= Ethnicity,				/*-- OPTIONAL VARIABLE 	--*
		ratio= 2										/*-- 1:2 cases to controls --*
	);

*******************************************************************************/


%macro declare_global_macros();
	%global today;
	%global best_iter;
	%global output_insuff;
	%global best_iter;
	%global best_obs;
	%global nf_best_iter;
	%global nf_best_obs;
	
	%let best_obs=;
	%let best_iter=;
	%let nf_best_obs=;
	%let nf_best_iter=;
%mend declare_global_macros;


%macro create_path_datasets();
	*******************************************************************************
	Create a library to the project folder
	*******************************************************************************;
	libname project "&folder_path";
	
	*******************************************************************************
	Get dataset names that are currently in the WORK library. These will be saved,
	but all datasets created to the WORK library from this macro will be erased
	at the end of execution.
	*******************************************************************************;
	proc sql noprint;
		select memname into :working_names separated by " "
		from dictionary.tables 
		where libname="WORK";
	
	*******************************************************************************
	Create a dataset to use for the macro without overwriting original dataset
	*******************************************************************************;
	data working_set;
		set project.&DSN;
	run;
	
	*******************************************************************************
	Split the dataset into two datasets: case and control.
	*******************************************************************************;
	data case control;
		set working_set;
		random_num=uniform(0);
		if &case_control=1 then output case;
			else output control;
	run;
%mend create_path_datasets;


%macro match_2();
	*******************************************************************************
	Match on age and other matching variable
	*******************************************************************************;
	data control_range;
		set control;
		age_low=&num_var-&num_range;
		age_high=&num_var+&num_range;
	run;
	proc sql;
		create table grouping_matches as select
			one.&id as case_id,
			two.&id as control_id,
			one.&num_var as case_&num_var,
			two.&num_var as control_&num_var,
			one.&variable1 as case_&variable1,
			two.&variable1 as control_&variable1,
			one.random_num as random_num
		from case one, control_range two
		where ((one.&num_var between two.age_low and two.age_high) 
			and 
			one.&variable1=two.&variable1);
	quit;
%mend match_2;		


%macro match_3();
	*******************************************************************************
	Match on age and other matching variables
	*******************************************************************************;
	data control_range;
		set control;
		age_low=&num_var-&num_range;
		age_high=&num_var+&num_range;
	run;
	proc sql;
		create table grouping_matches as select
			one.&id as case_id,
			two.&id as control_id,
			one.&num_var as case_&num_var,
			two.&num_var as control_&num_var,
			one.&variable1 as case_&variable1,
			two.&variable1 as control_&variable1,
			one.&variable2 as case_&variable2,
			two.&variable2 as control_&variable2,
			one.random_num as random_num
		from case one, control_range two
		where ((one.&num_var between two.age_low and two.age_high) 
			and 
			one.&variable1=two.&variable1
			and
			one.&variable2=two.&variable2);
	quit;
%mend match_3;	


%macro count_and_first_match();
	*******************************************************************************
	Both versions use this section.
	
	Order the control subjects by the number of matches they have with the case 
	subjects. Then keep the matches for the low frequency control subjects first.
	*******************************************************************************;
	* count the number of control subjects for each case subject; 
	proc sort data=grouping_matches;
		by case_id;
	run;
	data cases_and_avail_matches (keep= case_id available_controls);
		set grouping_matches;
		by case_id;
		retain available_controls;
		if first.case_id then available_controls=1;
			else available_controls=available_controls+1;
		if last.case_id then output; 
	run;
		
	* now merge the counts back into the dataset; 
	data merged_grouping_avail;
		merge grouping_matches
		cases_and_avail_matches;
		by case_id;
	run;
%mend count_and_first_match;


%macro matching_iteration();
	*******************************************************************************
	Evaluate the matching process by repeating the matching algorithm. Keep the
	dataset with the maximum number of rows. This helps to eliminate bias by
	finding the dataset with the best matching attributes.
	*******************************************************************************;
	%do ii = 1 %to 100; 
		data random;
			set merged_grouping_avail;
			iteration=&ii; 
			random_num=uniform(&ii); 
		run;
		proc sort data=random;
			by control_id available_controls random_num; 
		run;
		data take_first_controls;
			set random;
			by control_id;
			if first.control_id; 
		run;
		proc sort data=take_first_controls; 
			by case_id random_num;
		run;
		data numbered_groups NF_MATCH_ITER_&ii; 
			set take_first_controls;
			by case_id;
			retain num;
			if first.case_id then num=1; 
			if num le &ratio then do;
				output numbered_groups;
				num=num+1;
			end;
			if last.case_id then do;
				if num le &ratio then output NF_MATCH_ITER_&ii; 
			end;
		run;
		data MATCH_ITER_&ii;
			merge numbered_groups NF_MATCH_ITER_&ii (in=b_); 
			by case_id;
			if b_ then delete;
		run;
		
		proc sql noprint;
			select count(*) into :match_obs from work.MATCH_ITER_&ii;
			select count(*) into :nf_match_obs from work.NF_MATCH_ITER_&ii;
		quit;

	*******************************************************************************
	Update which dataset has the most matches and its complementary set of
	nf = "not full" matches
	*******************************************************************************;
		%if %sysevalf( &match_obs > &best_obs ) %then %do; 
			%let best_iter = MATCH_ITER_&ii;
			%let best_obs = &match_obs;
			%let nf_best_iter = NF_MATCH_ITER_&ii;
			%let nf_best_obs = &nf_match_obs;
			
		%end;
		
	%end;
%mend matching_iteration;


%macro best_iter_on_2();
	*******************************************************************************
	Add descriptive labels for results.
	*******************************************************************************;
	data &best_iter;
		set &best_iter;
		label case_id="Case ID";
		label control_id="Control ID";
		label case_age="Case &num_var";
		label control_age="Control &num_var";
		label case_&variable1="&variable1";
		label control_&variable1="Control &variable1";
		label available_controls="Number of (*ESC*){unicode '000a'x} Available Controls";
		label num="Match Number";
	run;
	data &nf_best_iter;
		set &nf_best_iter;
		label case_id="Case ID";
		label control_id="Control ID";
		label case_age="Case &num_var";
		label control_age="Control &num_var";
		label case_&variable1="&variable1";
		label control_&variable1="Control &variable1";
		label available_controls="Number of (*ESC*){unicode '000a'x} Available Controls";
		label num="Match Number";
	run;
	
	*******************************************************************************
	Output sample results of best match checking algorithm to results section.
	*******************************************************************************;
	data sample_match;
		set &best_iter;
		if _n_<13 then output;
	run;
	
	proc print data=sample_match noobs label;
		title "Sample of Case-Control matches displayed by Case";
		footnote j=l color=red "A full PDF report and CSV file of this dataset were created in your PROJECT folder.";
		footnote3 j=l "You can also locate the SAS dataset of case-control matches in your WORK library.";
		by case_id;
		var control_id case_&num_var control_&num_var	case_&variable1 num;
	run; title;
	
	data sample_noMatch;
		set &nf_best_iter;
		if _n_<13 then output;
	run;
	
	proc print data=sample_noMatch noobs label;
		var case_id control_id case_&num_var control_&num_var case_&variable1;
		title "Sample of Cases with insufficiently matched Controls";
		footnote j=l "There are &nf_best_obs insufficiently matched Cases.";
	run; title; footnote; footnote3;
					
	*******************************************************************************
	Output datasets to PDF files in project folder.
	*******************************************************************************;
	ods pdf file="&folder_path./Case_Control_Matches_&sysdate9..PDF";
	proc print data=&best_iter noobs label;
		title "Case-Control matches displayed by Case";
		by case_id;
		var control_id case_&num_var control_&num_var 
				case_&variable1 control_&variable1 num;
	run; title;
	ods pdf close;
	
	ods pdf file="&folder_path./Insufficient_Matches_&sysdate9..PDF";
	proc print data=&nf_best_iter noobs label;
		title "Cases with insufficiently matched Controls";
		footnote j=l "There are &nf_best_obs insufficiently matched Cases.";
		var case_id control_id case_&num_var control_&num_var 
				case_&variable1 control_&variable1;
	run; title;
	ods pdf close;
%mend best_iter_on_2;


%macro best_iter_on_3();
	*******************************************************************************
	Add descriptive labels for results.
	*******************************************************************************;
	data &best_iter;
		set &best_iter;
		label case_id="Case ID";
		label control_id="Control ID";
		label case_age="Case &num_var";
		label control_age="Control &num_var";
		label case_&variable1="&variable1";
		label control_&variable1="Control &variable1";
		label case_&variable2="&variable2";
		label control_&variable2="Control &variable2";
		label available_controls="Number of (*ESC*){unicode '000a'x} Available Controls";
		label num="Match Number";
	run;
	data &nf_best_iter;
		set &nf_best_iter;
		label case_id="Case ID";
		label control_id="Control ID";
		label case_age="Case &num_var";
		label control_age="Control &num_var";
		label case_&variable1="&variable1";
		label control_&variable1="Control &variable1";
		label case_&variable2="&variable2";
		label control_&variable2="Control &variable2";
		label available_controls="Number of (*ESC*){unicode '000a'x} Available Controls";
		label num="Match Number";
	run;
	
	*******************************************************************************
	Output sample results of best match checking algorithm to results section.
	*******************************************************************************;
	data sample_match;
		set &best_iter;
		if _n_<13 then output;
	run;
	
	proc print data=sample_match noobs label;
		title "Sample of Case-Control matches displayed by Case";
		footnote j=l color=red "A full PDF report and CSV file of this dataset were created in your PROJECT folder.";
		footnote3 j=l "You can also locate the SAS dataset of case-control matches in your WORK library.";
		by case_id;
		var control_id case_&num_var control_&num_var	
				case_&variable1 case_&variable2 num;
	run; title;
	
	data sample_noMatch;
		set &nf_best_iter;
		if _n_<13 then output;
	run;
	
	proc print data=sample_noMatch noobs label;
		var case_id control_id case_&num_var control_&num_var 
				case_&variable1 case_&variable2;
		title "Sample of Cases with insufficiently matched Controls";
		footnote j=l "There are &nf_best_obs insufficiently matched Cases.";
	run; title; footnote; footnote3;
					
	*******************************************************************************
	Output datasets to PDF files in project folder.
	*******************************************************************************;
	ods pdf file="&folder_path./Case_Control_Matches_&sysdate9..PDF";
	proc print data=&best_iter noobs label;
		title "Case-Control matches displayed by Case";
		by case_id;
		var control_id case_&num_var control_&num_var 
				case_&variable1 case_&variable2 num;
	run; title;
	ods pdf close;
	
	ods pdf file="&folder_path./Insufficient_Matches_&sysdate9..PDF";
	proc print data=&nf_best_iter noobs label;
		title "Cases with insufficiently matched Controls";
		footnote j=l "There are &nf_best_obs insufficiently matched Cases.";
		var case_id control_id case_&num_var control_&num_var 
				case_&variable1 case_&variable2;
	run; title;
	ods pdf close;
%mend best_iter_on_3;


%macro create_csv_and_datasets();
	*******************************************************************************
	BOTH VERSIONS -- output datasets as CSV files in project folder.
	*******************************************************************************;
	proc export data=&best_iter
    outfile="&folder_path./Case_Control_Matches_&sysdate9..csv"
    dbms=csv replace;
	run;
	
	proc export data=&nf_best_iter
    outfile="&folder_path./Insufficient_Matches_&sysdate9..csv"
    dbms=csv replace;
	run;
				
	*******************************************************************************
	Save the good matches and insufficient matches datasets in the PROJECT folder
	*******************************************************************************;
	data project.case_control_matches;
		set &best_iter;
	run;
	data project.insufficient_matches;
		set &nf_best_iter;
	run;
%mend create_csv_and_datasets;			


%macro library_clean();	
	*******************************************************************************
	It conducts a boolean check if the WORK library was empty at the start
	of the macro. If there were datasets, it keeps those datasets, but will
	erase all datasets generated by the macro that are in the WORK folder.
	*******************************************************************************;
	%if %sysevalf(%superq(working_names)=,boolean)=0 %then %do;
		proc datasets lib=work memtype=data noprint;
			save &working_names;
		run;
	%end;
	%else %do;
		proc datasets lib=work memtype=data kill noprint; run;
	%end;
%mend library_clean;		


%macro macro_var_clean();
	*******************************************************************************
	Reset global macro variables.
	*******************************************************************************;
	%let best_obs=;
	%let best_iter=;
	%let nf_best_obs=;
	%let nf_best_iter=;
%mend macro_var_clean;



*******************************************************************************
Full matching program
*******************************************************************************;
%macro case_control_match(
		folder_path=,
		DSN=,
		id=,
		case_control=,
		num_var=,
		num_range=1,
		variable1=,
		variable2=,
		ratio=2
	);

	%declare_global_macros();
	
	%create_path_datasets();
	
	*******************************************************************************
	Check if variable2 position is empty
	*******************************************************************************;
	%if %sysevalf(%superq(variable2)=,boolean)=1 %then %do;
		%match_2();
		%count_and_first_match();
		%matching_iteration();
		%best_iter_on_2();
	%end;
	%if %sysevalf(%superq(variable2)=,boolean)=0 %then %do;
		%match_3();
		%count_and_first_match();
		%matching_iteration();
		%best_iter_on_3();
	%end;

	%create_csv_and_datasets();
	
	%library_clean();
	%macro_var_clean();
	
%mend case_control_match;



