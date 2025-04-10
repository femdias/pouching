// Poaching Project
// Created by: Felipe Macedo Dias
// (fm469@cornell.edu; fem.dias@hotmail.com)
// Date created: April 2025

// Purpose: Summary Stats - Share of firms in each size band



* Using 2013 as base

local y 2013

display "Starting year `y'"

* Reading RAIS of year y
use plant_id emp_on_dec31 gender race educ earn_avg_month_nom num_hours_contracted using "$RAIS_Clean/RAIS_Clean_2013.dta", clear

* Dropping if the obsertion is emp_on_dec31 == 0 (unemployed in the end of the year)
drop if emp_on_dec31 == 0
drop emp_on_dec31

* Creating demographic indicators
gen male_count = (gender == 1)
gen poc_count = (race == 1 | race == 4 | race == 8)
gen white_asian_count = (race == 2 | race == 6)
gen undef_race = (race == 9)
gen employees = 1
gen college_count = (educ == 9)	
	

* Collapse at plant level first to get plant-level statistics
collapse (sum) total_wages = earn_avg_month_nom total_hours = num_hours_contracted employees ///
         male_count poc_count white_asian_count undef_race college_count, by(plant_id)
 
* Calculate firm-level indicators
gen avg_wage = total_wages / employees
gen avg_hours = total_hours / employees
gen share_female = (1 - (male_count / employees) )* 100
gen share_nonwhite = (poc_count / (white_asian_count + poc_count)) * 100
gen share_college = (college_count / employees) * 100

* Create firm size categories
gen size_cat = 1 if employees <= 5
replace size_cat = 2 if employees > 5 & employees <= 10
replace size_cat = 3 if employees > 10 & employees <= 20
replace size_cat = 4 if employees > 20 & employees <= 50
replace size_cat = 5 if employees > 50 & !missing(employees)
label define size_lbl 1 "1-5" 2 "6-10" 3 "11-20" 4 "21-50" 5 "50+"
label values size_cat size_lbl


******** Share of firms by firm size (number of employees)

* Generate firm size indicators
gen firm_over20 = (employees > 20)
gen firm_over50 = (employees > 50)

* Calculate share of firms over 20 and 50 employees
sum firm_over20 
local share_over20 = r(mean) * 100
sum  firm_over50
local share_over50 = r(mean) * 100

display "Share of firms with 20+ employees: `share_over20'%" // 8.56%
display "Share of firms with 50+ employees: `share_over50'%" // 3.29%



* Calculate percentage distribution by size category
preserve
	gen firm = 1
	* Count firms in each category and calculate percentages
	bysort size_cat: gen n_in_cat = _N
	egen total_firms = total(n_in_cat)
	gen pct_firms = (n_in_cat/total_firms)*100

	* Collapse to get one row per size category
	collapse (sum) firm, by(size_cat)


	* Calculate total number of firms
	egen total_firms = sum(firm)

	* Calculate percentage of firms in each category
	gen firm_pct = (firm / total_firms) * 100

	* Format for display
	format firm_pct %9.1f

	* List results
	list size_cat firm firm_pct, clean
	/*
		size_cat      firm   firm_pct  
	  1.        1-5   2302821       68.5  
	  2.       6-10    483989       14.4  
	  3.      11-20    288295        8.6  
	  4.      21-50    177459        5.3  
	  5.        50+    110527        3.3  
	*/
restore


* total firms and employees by firm size
bysort size_cat: egen total_employees = sum(employees)
bysort size_cat: egen total_firms = count(plant_id)


* Variables to be used
global mean_vars total_employees total_firms avg_wage avg_hours share_female share_nonwhite share_college  

eststo means_by_size1: estpost summarize $mean_vars  if size_cat == 1
eststo means_by_size2: estpost summarize $mean_vars  if size_cat == 2
eststo means_by_size3: estpost summarize $mean_vars  if size_cat == 3
eststo means_by_size4: estpost summarize $mean_vars  if size_cat == 4
eststo means_by_size5: estpost summarize $mean_vars  if size_cat == 5
	
	
	
****** In 2 parts for formating the number of decimal cases properly
esttab means_by_size1 means_by_size2 means_by_size3 means_by_size4 means_by_size5 ///
		using "${results}/sumstats_firm_size.tex", replace /// saving as .tex
		keep(total_employees total_firms) ///
		compress /// 
		booktabs /// for cleaner latex text
		cell("mean(fmt(%15.0fc))") /// which statistics to display 
		mtitle("1-5" "6-10" "11-20" "21-50" "50+") /// columns titles
		nogaps /// suppress the extra vertical spacing between rows
		nonumbers  /// removing the number of models (in the top of the table) 
		nolines /// removing automatic lines separating parts of the table
		collabels(none) /// removing label the columns within models 
		posthead(\midrule) /// adding horizontal line after header 
		noobs ///
		fragment ///
		varlabels(total_employees "Number of Employees" total_firms "Number of Firms" ) /// Labelling variables in the table
		starlevels(* .10 ** .05 *** .01) // choosing significance level of starts

esttab means_by_size1 means_by_size2 means_by_size3 means_by_size4 means_by_size5 ///
		using "${results}/sumstats_firm_size.tex", append /// saving as .tex
		keep(avg_wage avg_hours share_female share_nonwhite share_college) ///
		compress /// saving as .tex
		booktabs /// for cleaner latex text
		cell("mean(fmt(%15.2fc))") /// which statistics to display 
		nomtitles /// no columns titles (because of append)
		nogaps nonumbers  nolines collabels(none) /// 
		prefoot(\midrule) /// adding horizontal line pre foot
		noobs ///
		fragment ///
		varlabels(avg_wage "Avg Wage" avg_hours "Average Hours" share_female "Share Female (\%)" share_nonwhite "Share Non-white (\%)" share_college "Share of college educated workers (\%)") /// Labelling variables in the table
		starlevels(* .10 ** .05 *** .01) // choosing significance level of starts

		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/*

* With HR
esttab without_HR_means /// selecting models 
    using "results/tables/summary_stats_`i'_without_HR.tex", replace /// saving as .tex
    booktabs /// for cleaner latex text
    cell("min(fmt(2)) max(fmt(2)) p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2)) sd(fmt(2))") /// which statistics to display 
    nogaps /// suppress the extra vertical spacing between rows
    nonumbers  /// removing the number of models (in the top of the table) 
    nolines /// removing automatic lines separating parts of the table
    prefoot(\midrule) /// adding horizontal line pre foot
    posthead(\midrule) /// adding horizontal line after header 
    mtitle("Min" "Max" "10th Percentile" "25th Percentile" "Median" "75th Percentile" "90th Percentile" "Standard Deviation") /// 
    collabels(none) /// removing label the columns within models 
    varlabels(real_avg_wage "Avg Real Wage (R\\$ 2010)" avg_hours "Average Hours" share_female "Share Female" share_nonwhite "Share Nonwhite" share_college "Share of college educated workers" year "Avg First Year in RAIS" employees "Employees" HR_employees "HR Employees" number_estab "Number of establishments" open_year "Year of incorporation" firm_age "Firm age" years_until_hr_intro "Years until HR introduction") /// Labelling variables in the table
    starlevels(* .10 ** .05 *** .01) /// choosing significance level of starts
    stats(N, fmt(%15.0fc) labels("Observations")) /// choosing which statistics to display in the bottom of the table
    postfoot("\bottomrule \\ \end{tabular}}")

















* Summary stats by firm size
preserve
* Calculate stats for each size category
collapse (sum) total_employees=employees num_firms=1 ///
         (mean) avg_wage avg_hours share_female share_nonwhite share_college, by(size_cat)

* Add all firms row
tempfile size_stats
save `size_stats'
restore

* Calculate stats for all firms
collapse (sum) total_employees=employees num_firms=1 ///
         (mean) avg_wage avg_hours share_female share_nonwhite share_college
gen size_cat = 0
label define size_lbl 0 "All firms", add
append using `size_stats'
sort size_cat

* Format and display table
format total_employees %15.0fc
format num_firms %15.0fc
format avg_wage avg_hours share_female share_nonwhite share_college %9.2f

* Display table
list size_cat total_employees num_firms avg_wage avg_hours share_female share_nonwhite share_college, clean


* Calculate percentage of firms in each category
gen pct_firms = (num_firms / num_firms[1]) * 100
gen pct_empl = (total_employees / total_employees[1]) * 100
format pct_firms pct_empl %9.1f

* Display distribution
list size_cat num_firms pct_firms total_employees pct_empl, clean	
	
	
	
	
	
	
	
	
	
	
	
	
		* Collapsing
	collapse (mean) real_avg_wage avg_hours share_female share_nonwhite employees HR_employees number_estab open_year firm_age ///
		(first) year years_until_hr_intro (max) ever_hr always_hr introduced_hr, by(cnpj_root) 

	* Just for not getting an error in the difference part, replacing missings with 0
	*replace years_until_hr_intro = 0 if years_until_hr_intro == .
		
	* Variables to be used
	global balance_vars real_avg_wage avg_hours number_estab employees HR_employees share_female share_nonwhite year  years_until_hr_intro 

	* Using estout: creating separately for with, without HR and the difference
	eststo without_HR_means: estpost summarize $balance_vars if ever_hr == 0, detail
	eststo with_HR_means: estpost summarize $balance_vars if ever_hr == 1, detail
	eststo always_hr_means: estpost summarize $balance_vars if always_hr == 1, detail
	eststo introduced_hr_means: estpost summarize $balance_vars if introduced_hr == 1, detail
	*eststo differences:  estpost ttest $balance_vars, by(ever_hr) unequal

	***** Saving in LaTeX tabel with percentils, std, max, min
	
	* With HR
	esttab without_HR_means /// selecting models 
	    using "results/tables/summary_stats_`i'_without_HR.tex", replace /// saving as .tex
	    booktabs /// for cleaner latex text
	    cell("min(fmt(2)) max(fmt(2)) p10(fmt(2)) p25(fmt(2)) p50(fmt(2)) p75(fmt(2)) p90(fmt(2)) sd(fmt(2))") /// which statistics to display 
	    nogaps /// suppress the extra vertical spacing between rows
	    nonumbers  /// removing the number of models (in the top of the table) 
	    nolines /// removing automatic lines separating parts of the table
	    prefoot(\midrule) /// adding horizontal line pre foot
	    posthead(\midrule) /// adding horizontal line after header 
	    mtitle("Min" "Max" "10th Percentile" "25th Percentile" "Median" "75th Percentile" "90th Percentile" "Standard Deviation") /// 
	    collabels(none) /// removing label the columns within models 
	    varlabels(real_avg_wage "Avg Real Wage (R\\$ 2010)" avg_hours "Average Hours" share_female "Share Female" share_nonwhite "Share Nonwhite" share_college "Share of college educated workers" year "Avg First Year in RAIS" employees "Employees" HR_employees "HR Employees" number_estab "Number of establishments" open_year "Year of incorporation" firm_age "Firm age" years_until_hr_intro "Years until HR introduction") /// Labelling variables in the table
	    starlevels(* .10 ** .05 *** .01) /// choosing significance level of starts
	    stats(N, fmt(%15.0fc) labels("Observations")) /// choosing which statistics to display in the bottom of the table
	    postfoot("\bottomrule \\ \end{tabular}}")
