/*

For the data analysis project in the SAS environment, I chose the dataset 
*Jobs and Salaries in Data Science*, available on the Kaggle platform: 
https://www.kaggle.com/datasets/saladyong/genshin-impact-banner-revenue

Justification for choosing the dataset:
This dataset contains detailed information on salaries, job titles, 
professional experience, and the location of both employees and companies. 
These data allow for a broad analysis of factors influencing salary levels 
in the Data Science sector, which aligns with my professional interests.

The dataset includes, among others, the following variables:
- work_year – the year the data was recorded,
- job_title – the job title (e.g., Data Scientist, Data Engineer),
- job_category – the job category (e.g., Data Analysis, Machine Learning),
- salary_currency – the currency in which the salary is paid,
- salary – the annual gross salary in the local currency,
- salary_in_usd – the annual gross salary converted to USD,
- employee_residence – the country of residence of the employee,
- experience_level – the level of professional experience,
- employment_type – the type of employment (e.g., full-time, part-time, contract),
- work_setting – the work arrangement (e.g., remote, on-site, hybrid),
- company_location – the location of the company,
- company_size – the size of the company (small, medium, large).

Planned analyses:
Based on the dataset, the following analyses are conducted:

1. Demographic and Structural Insights
- Frequency distributions for employment type, experience level,
work setting, company size, and job category.
- Mosaic plots and bar charts to explore relationships between experience
level and company size, and between work setting and job category.

2. General Salary Trends
- Summary statistics of salary (in USD) by year to explore annual changes.
- Identification of the global average salary.

3. Salary Distributions by Categories
- Average salaries by job category and job title.
- Salary trends across job categories over time.

4. Geographic Salary Patterns
- Average salaries by company location (country).
- Top countries by number of employees and companies.

*/

/* ==================================================================== */
/* PART 1: DATA IMPORT                                                  */
/* ==================================================================== */

/* 1.1 Define library and file paths */
libname dsalary "/home/u64169742/sasuser.v94/Programowanie_SAS/projekt1";

/* 1.2 Import data */
filename reffile 
	'/home/u64169742/sasuser.v94/Programowanie_SAS/projekt1/jobs_in_data.csv';

proc import datafile=reffile dbms=csv out=dsalary.salaries0 replace;
	getnames=yes;
    guessingrows=max; /* make SAS look at all rows to determine 
						 correct lengths for all the variables */
run;

/* ==================================================================== */
/* PART 2: DATA CLEANING & EXPLORATORY DATA ANALYSIS                    */
/* ==================================================================== */

/* 2.1 Labels and Formatting */
proc contents data=dsalary.salaries0 varnum; /* varnum for the order of the variables */
run; 

data dsalary.salaries;
	length employment_type $19.; /* ensure "Fixed-term Contract" will not be shorten */
	set dsalary.salaries0(rename=(employment_type=old_type));
	
	if old_type="Contract" then 
		employment_type="Fixed-term Contract";
	else 
		employment_type=old_type; /* change the value for future title improvement */
	
	label work_year="Year of Salary Data" /* set labels */
	    job_title="Job Title" job_category="Job Category" 
		salary_currency="Currency of Salary" salary="Original Salary Amount" 
		salary_in_usd="Salary in USD" 
		employee_residence="Employee's Country of Residence" 
		experience_level="Experience Level" employment_type="Employment Type" 
		work_setting="Work Setting (Remote/Hybrid/On-site)" 
		company_location="Company's Country Location" 
		company_size="Company Size (S/M/L)";
	format salary salary_in_usd dollar12.2; /* format as currency with 2 decimal places
										       and thousand comma separator */
	format work_year 4.;
run;

proc contents data=dsalary.salaries varnum; /* check the formatting, labels and length */
run;

proc print data=dsalary.salaries(obs=10) label; /* print the sample data */
run;


/* 2.2 Missing Data Analysi */
proc format;
	value $missfmt ' '='Missing' other='Not Missing';
	value missfmt  .='Missing' other='Not Missing';
run;

proc freq data=dsalary.salaries noprint;
	format _character_ $missfmt. _numeric_ missfmt.;
	tables _all_ / missing nocum nopercent;
run;
/* No missing values were found */


/* 2.3 Means and Frequency Distribution  */
/* 2.3.1 Salary statistics */
title "Salary Distribution by Year: Basic Statistics";
proc means data=dsalary.salaries N Mean Std Min Max;
	class work_year;
	var salary_in_usd;

	/* other variables are mostly categorical,
	hence only salary_in_usd is considered */
run;

title "Salary Distribution by Year: Box Plot Visualization";
proc sgplot data=dsalary.salaries;
	vbox salary_in_usd / category=work_year grouporder=ascending;

	/* N Obs is for all the observations and
	N in only for non-missing ones */
	yaxis grid;
run;

/* 2.3.2 Frequency of categorical variables */
title "Employee Contract Type Distribution";
proc freq data=dsalary.salaries order=freq;
	tables employment_type /  out=empl_type_freq;
run;
proc gchart data=empl_type_freq;
	/* Pie chart */
	pie employment_type / sumvar=COUNT percent=inside value=inside 
		slice=outside /* locate the slices' names outside */
		noheading;
	run;


title "Experience Level Distribution Across Company Sizes";
proc freq data=dsalary.salaries;
	tables experience_level*company_size / plots=mosaicplot;
run;
/* from this plot we can see that L sized companies have more entry- and mid-level employees */

/* work_year & job_category frequencies */
title "Job Category Trends Over Time";
proc freq data=dsalary.salaries;
	tables work_year*job_category / out=freq_year_cat;
run;

proc sgplot data=freq_year_cat;
	vbar work_year / response=count group=job_category 
		groupdisplay=cluster /* arrange the grouped bars side-by-side */
		categoryorder=respasc;

	/* sort in ascending order */
	title "Job Category Distribution by Year: Clustered Bar Chart";
	xaxis label="Year";
	yaxis label="Number of Job Offers";
	yaxis grid;
run;

/* work_setting & job_category frequencies */
title "Work Setting Distribution Across Job Categories";
proc freq data=dsalary.salaries order=freq;
	tables work_setting*job_category / out=freq_sett_cat;
run;

proc sgplot data=freq_sett_cat;
	hbarparm category=job_category response=count / group=work_setting seglabel 
		seglabelfitpolicy=thin seglabelattrs=(weight=bold);
	keylegend / opaque across=1 position=bottomright location=inside;
	title "Work Setting Distribution by Job Category: Bar Chart";
	xaxis grid;
	yaxis labelpos=top;
run;

/* Handle high-cardinality variables (top N analysis) */
proc freq data=dsalary.salaries order=freq noprint;
	tables job_category / out=job_category_freq;
run;

proc freq data=dsalary.salaries order=freq noprint;
	tables job_title / out=job_title_freq;
run;

proc freq data=dsalary.salaries order=freq noprint;
	tables employee_residence / out=employee_residence_freq;
run;

proc freq data=dsalary.salaries order=freq noprint;
	tables company_location / out=company_location_freq;
run;

/* Display top N data */
proc print data=job_category_freq;
	title "Top Job Categories by Frequency";
run;

/* Table */
proc gchart data=job_category_freq;
	/* Pie chart */
	pie job_category / sumvar=COUNT percent=inside value=inside 
		slice=outside /* locate the slices' names outside */
		noheading;
	run;

proc print data=job_title_freq(obs=15);
	title "Top Job Titles by Frequency";
run;

/* Table */
proc gchart data=job_title_freq;
	/* Pie chart */
	pie job_title / sumvar=COUNT percent=inside value=inside slice=outside 
		noheading;
	format percent 5.1;
	run;
quit;

ods pdf file="/home/u64169742/sasuser.v94/Programowanie_SAS/projekt/two_tables.pdf" columns=2; /* rtf dziala */
proc print data=employee_residence_freq(obs=10);
	title "Top 10 Employee Residences by Frequency";
run;
proc print data=company_location_freq(obs=10);
	title "Top 10 Company Residences by Frequency";
run;
ods pdf close;

title; /* clear all the titles */


/* PART 3: 	AVERAGE SALARY ANALYSIS */

/* 3.1 Bar Chart: Average Salary by Job Category Over the Time  */
proc means data=dsalary.salaries; /* calculate average salaries for each year by job category */
	class work_year job_category;
	var salary_in_usd;
	output out=avg_salary_per_year_cat (drop=_type_ _freq_) mean=avg_salary_in_usd;
run;

proc sgplot data=avg_salary_per_year_cat;
	/* chart previously computated data */
	vbar work_year / response=avg_salary_in_usd group=job_category
	datalabel 
	datalabelpos=data
	DATALABELFITPOLICY=rotate
	groupdisplay=cluster /* arrange the grouped bars side-by-side */
	categoryorder=respasc;	/* sort in ascending order */
	title "Average Salary by Year and Job Category";
	xaxis label="Year";
	yaxis label="Average Salary (USD)";
	yaxis labelpos=top;
	yaxis grid;
run;
quit;



/* 3.2 Table: Average Salary by Job Category and Job Title      */
proc summary data=dsalary.salaries nway;
	class job_category job_title;
	var salary_in_usd;
	output out=avg_sal_cat_title0 mean=average_salary_in_usd;
run;

data avg_sal_cat_title;
	set avg_sal_cat_title0;
	average_salary_in_usd=round(average_salary_in_usd, 0.01); /* round to two decimal places */
	format average_salary_in_usd dollar12.2; /* add USD formating */
	drop _TYPE_ _FREQ_;
run;

/* Create a sorted dataset with average salary info */
proc sql;
    create table avg_sal_catt0 as
    select job_category, job_title, 
               average_salary_in_usd, 
               avg(average_salary_in_usd) as aver
        from avg_sal_cat_title
        group by job_category
    	order by aver desc;
quit;

data avg_sal_catt;
	set avg_sal_catt0;
	label aver="Category Average Salary";
	format aver dollar12.2;
run;

/* sort salaries */
proc sort data=avg_sal_catt; 
	by descending aver descending average_salary_in_usd;
run;

title height=14pt color=navy font='Arial/bold' "Average Salaries by Category & Title";
proc report data=avg_sal_catt nowd;
    columns job_category job_title aver average_salary_in_usd;

    define job_category / display;
    define job_title / display;
    define aver / display
    	style(column)=[backgroundcolor=salarycolor.];
    compute aver;
        if aver >= 150000 then
            call define(_col_, "style", "style={backgroundcolor=cx006400}"); /* dark green */
        else if aver >= 120000 then
            call define(_col_, "style", "style={backgroundcolor=cx32CD32}"); /* lime green */
        else if aver >= 60000 then
            call define(_col_, "style", "style={backgroundcolor=cxADFF2F}"); /* green yellow */
        else
            call define(_col_, "style", "style={backgroundcolor=white}"); /* pale */
    endcomp;
    define average_salary_in_usd / display
        style(column)=[backgroundcolor=salarycolor.];
    compute average_salary_in_usd;
        if average_salary_in_usd >= 150000 then
            call define(_col_, "style", "style={backgroundcolor=cx006400}"); /* dark green */
        else if average_salary_in_usd >= 120000 then
            call define(_col_, "style", "style={backgroundcolor=cx32CD32}"); /* lime green */
        else if average_salary_in_usd >= 60000 then
            call define(_col_, "style", "style={backgroundcolor=cxADFF2F}"); /* green yellow */
        else
            call define(_col_, "style", "style={backgroundcolor=white}"); /* pale */
    endcomp;
run;
title;


/* 3.3 Table: By Country */
proc summary data=dsalary.salaries nway;
	class company_location experience_level;
	var salary_in_usd;
	output out=avg_sal_ct0 mean=average_salary_in_usd;
run;

data avg_sal_ct;
	set avg_sal_ct0;
	average_salary_in_usd=round(average_salary_in_usd, 0.01); /* round to two decimal places */
	format average_salary_in_usd dollar12.2; /* add USD formating */
	drop _TYPE_ _FREQ_;
run;

proc sort data=avg_sal_ct; /* sort salaries */
	by descending company_location experience_level average_salary_in_usd;
run;

/* Create a sorted dataset with average salary info */
proc sql;
    create table salary_color_data0 as
    select company_location, experience_level, 
               average_salary_in_usd, 
               avg(average_salary_in_usd) as aver
        from avg_sal_ct
        group by company_location
    	order by aver desc;
quit;

data salary_color_data;
	set salary_color_data0;
	label aver="Country Average Salary";
	format aver dollar12.2;
run;

title1 height=14pt color=navy font='Arial/bold' "Average Salaries by Country";
title2 height=12pt color=gray font='Arial' "Global Average: " color=green 
	"150,299.50 USD";

/* Use PROC REPORT with dynamic coloring */
proc report data=salary_color_data nowd;
    columns company_location experience_level aver average_salary_in_usd;

    define company_location / display;
    define experience_level / display;
    define aver / display
    	style(column)=[backgroundcolor=salarycolor.];
    compute aver;
        if aver >= 150000 then
            call define(_col_, "style", "style={backgroundcolor=cx006400}"); /* dark green */
        else if aver >= 120000 then
            call define(_col_, "style", "style={backgroundcolor=cx32CD32}"); /* lime green */
        else if aver >= 60000 then
            call define(_col_, "style", "style={backgroundcolor=cxADFF2F}"); /* green yellow */
        else
            call define(_col_, "style", "style={backgroundcolor=white}"); /* pale */
    endcomp;
    define average_salary_in_usd / display
        style(column)=[backgroundcolor=salarycolor.];
    compute average_salary_in_usd;
        if average_salary_in_usd >= 150000 then
            call define(_col_, "style", "style={backgroundcolor=cx006400}"); /* dark green */
        else if average_salary_in_usd >= 120000 then
            call define(_col_, "style", "style={backgroundcolor=cx32CD32}"); /* lime green */
        else if average_salary_in_usd >= 60000 then
            call define(_col_, "style", "style={backgroundcolor=cxADFF2F}"); /* green yellow */
        else
            call define(_col_, "style", "style={backgroundcolor=white}"); /* pale */
    endcomp;
run;

title;
