

**Author**: Kyle Grealis kylegrealis@icloud.com

**Affiliation**: all work has been done independent of any academic affiliation. 
	All work is my own (unless cited) and all errors are my own.

**Date**: January 23, 2023

**Revised**: April 15, 2023

**References**:
1.  Kawabata, H., Tran, M., & Hines, P. (2004). Using SAS to match cases for case 
				control studies. [Poster presentation](https://support.sas.com/resources/papers/proceedings/proceedings/sugi29/173-29.pdf). SAS users group international 29. 
				Bristol-Myers Squibb, Princeton, New Jersey.
2.	Mortensen, L.Q., Andresen, K., Burcharth, J., Pommergaard, H., & Rosenberg, J. 
				(2019). Matching cases and controls using SAS software. Frontiers in big 
				data 2:4. [Doi: 10.3389/fdata.2019.00004](https://www.frontiersin.org/articles/10.3389/fdata.2019.00004/full).
3.	Rose, S., & Laan, M. J. (2009). Why match? Investigating matched case-control 
				study designs with causal effect estimation. The international journal of 
				biostatistics, 5(1), 1. https://doi.org/10.2202/1557-4679.1127

The macro program is available for matching by 2 or 3 selection criteria. The ```variable2``` argument allows to pass a third variable for matching. Arguments for ```variable1``` and ```variable2``` can either be numeric or categorical.


**Do NOT use quotations around variable names!**


**INSTRUCTIONS**
-	Create a project folder.
-	Move the ```test.sas7dbat``` dataset into the new project folder.
-	Run the %include with a proper direction to the folder holding the ```MACRO_case_control.sas``` file.
-	Argument descriptions:
	* 	folder_path: WITHOUT QUOTES like you would using ```PROC IMPORT```, but only to the folder and not to a specific file.
			EXAMPLE ```~/home/project```
	* 	```dataset```: The name of the dataset to be used.
	*	```id```: The variable that holds the participant ID
	*	```case_control```: The variable that will hold your case-control NUMERIC information. Be sure to code cases=1 and controls=0.
	*	```num_var```: Numeric variable name (e.g.--age)
	*	```num_range```: DEFAULT value is 1. Therefore, if case age is 35, controls aged 34-36 are eligible matches. If 0 is used, matching will be done on exact numeric matching only.
	*	```variable1```: Second matching variable (e.g.--gender)
	*	```variable2```: Optional variable to us three total matching criteria (e.g.--ethnicity)
	*	 ```ratio```: Select a case-control ratio. DEFAULT is 2, meaning one case to two controls.
	
-	Highlight and Run ```%case_control_match();```


**NOTES**
-	The algorithm will search for best matches based on exact matching, then by age range, if the provided age range is greater than 0.
-	The Results window will display a sample of case-control matched dataset. The algorithm iterates 100 times and will find the dataset with the maximum number of sufficient case-control observations.
-	A second dataset is created that lists all cases that have insufficient matches. For example, if the number of matched cases to controls is less than the supplied ratio, the case ID will be output to this dataset. Also, any controls that were matched to that case, though not achieving the matching ratio, will also be output to that dataset. A sample of this insufficiently matched dataset will also be displayed in the Results window, directly below the matched dataset sample.
-	Two PDF files, two CSV files, and two datasets will be created in the project folder.
		
		
		
Example of how to use the macro with ONLY 2 age and 1 other matching variable:

```
%case_control_match(
	folder_path= ~/project,
	DSN= test_set,
	id= Participant_ID,
	case_control= Event,
	num_var= Age,
	num_range= 2,
	variable1= Ethnicity,
	variable2=,
	ratio= 2
);
```

