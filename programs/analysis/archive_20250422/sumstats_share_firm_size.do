// Poaching Project
// Created by: Felipe Macedo Dias
// (fm469@cornell.edu; fem.dias@hotmail.com)
// Date created: April 2025

// Purpose: Summary Stats - Share of firms in each size band



* Using December of 2013 (647 month) as base

* Reading Primary contract dataset form RAIS monthly
use plant_id gender race educ earn_avg_month_nom num_hours_contracted using "${data}/rais_m/rais_m647.dta", clear

* Creating demographic indicators
gen male_count = (gender == 1)
gen poc_count = (race == 1 | race == 4 | race == 8)
gen white_asian_count = (race == 2 | race == 6)
gen undef_race = (race == 9)
gen employees = 1
gen college_count = (educ == 9)	
	

* Collapsing at firm level first to get firm-level statistics
collapse (sum) total_wages = earn_avg_month_nom total_hours = num_hours_contracted employees ///
         male_count poc_count white_asian_count undef_race college_count, by(plant_id)
 
* Calculating firm-level indicators
gen avg_wage = total_wages / employees
gen avg_hours = total_hours / employees
gen share_female = (1 - (male_count / employees) )* 100
gen share_nonwhite = (poc_count / (white_asian_count + poc_count)) * 100
gen share_college = (college_count / employees) * 100

* Creating firm size categories
gen size_cat = 1 if employees <= 5
replace size_cat = 2 if employees > 5 & employees <= 10
replace size_cat = 3 if employees > 10 & employees <= 20
replace size_cat = 4 if employees > 20 & employees <= 50
replace size_cat = 5 if employees > 50 & !missing(employees)
label define size_lbl 1 "1-5" 2 "6-10" 3 "11-20" 4 "21-50" 5 "50+"
label values size_cat size_lbl


******** Share of firms by firm size (number of employees)

* Generating firm size indicators
gen firm_over20 = (employees > 20)
gen firm_over50 = (employees > 50)

* Calculating share of firms over 20 and 50 employees
sum firm_over20 
local share_over20 = r(mean) * 100
sum  firm_over50
local share_over50 = r(mean) * 100

display "Share of firms with 20+ employees: `share_over20'%" // 8.56%
display "Share of firms with 50+ employees: `share_over50'%" // 3.29%



* Calculating percentage distribution by size category
preserve
	gen firm = 1
	* Counting firms in each category and calculate percentages
	bysort size_cat: gen n_in_cat = _N
	egen total_firms = total(n_in_cat)
	gen pct_firms = (n_in_cat/total_firms)*100

	* Collapsing to get one row per size category
	collapse (sum) firm, by(size_cat)

	* Calculating total number of firms
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

		
	
	
****************************************************************************************************************************************

* Average number of firms with +50 (or 20) employees in any given year between 2003-2017 *	

tempfile companies_summary

* Looping over years
forvalues y = 2003/2017 {
    
	display "Starting year `y'"

	* Reading RAIS of year y
	use plant_id emp_on_dec31 using "$RAIS_Clean//RAIS_Clean_`y'.dta", clear

	* Dropping if the obsertion is emp_on_dec31 == 0 (unemployed in the end of the year)
	drop if emp_on_dec31 == 0
	drop emp_on_dec31
	
	* Employees by company
	gen employees = 1
	collapse (sum) employees, by(plant_id)

	* Counting total number of companies
	local total_count = _N

	* Counting companies with more than 50 employees
	count if employees >= 50
	local count_50plus = r(N)

	* Counting companies with more than 20 employees
	count if employees >= 20
	local count_20plus = r(N)

	* Creating a single observation with these counts
	clear
	set obs 1
	gen year = `y'
	gen companies_50plus = `count_50plus'
	gen companies_20plus = `count_20plus'
	gen total_companies = `total_count'

	* Saving or appending to the combined data
	if `y' == 2003 {
		* Save the first year's data
		save `companies_summary'
	} 
	else {
		* Appending subsequent years
		append using `companies_summary'
		save `companies_summary', replace
	}
}
	
* Sorting by year for better presentation
use `companies_summary', clear
sort year

* Displaying the results
list year total_companies companies_20plus companies_50plus, clean noobs

* Saving the final results
save "${data}/company_counts_by_year.dta", replace	
	
	
	
	
	
	
****************************************************************************************************************************************

* Average number (and %) of people moving between +50 firms in between 2 months 

* Initialize results dataset
clear
set obs 0
gen month_from = .
gen month_to = .
gen total_employees = .
gen firm_movers = .
gen movement_rate = .
tempfile results
save `results', emptyok replace

* Processing each pair of consecutive months
local previous_month = 647 // dez-13

forvalues current_month = 648/660 {
	
	display "Processing movement from month `previous_month' to `current_month'"

	* Loading current month data
	use "${data}/rais_m/rais_m`current_month'.dta", clear

	* Generating employee count per firm in current month
	bysort plant_id: gen firm_size = _N

	* Keeping only 50+ employee firms
	keep if firm_size >= 50

	* Keeping essential variables
	keep cpf plant_id firm_size
	rename plant_id plant_id_current
	rename firm_size firm_size_current

	* Saving current month data
	tempfile current
	save `current'

	* Loading previous month data
	use "${data}/rais_m/rais_m`previous_month'.dta", clear

	* Generating employee count per firm in previous month
	bysort plant_id: gen firm_size = _N

	* Keeping essential variables
	keep cpf plant_id firm_size
	rename plant_id plant_id_previous
	rename firm_size firm_size_previous

	* Merging with current month data based on cpf
	merge 1:1 cpf using `current'

	* Keeping all people found in the first month
	drop if _merge == 2
	drop _merge
	
	* Counting people who changed between 50+ emp firms 
	gen changed_firm = (plant_id_previous != plant_id_current) & firm_size_current >= 50
	replace changed_firm = 0 if missing(plant_id_current)

	* Calculating total people who moved between 50+ firms
	count if changed_firm == 1
	local movers = r(N)

	* Calculating total people who stayed (or are not in the mext month dataset) in 50+ firms
	count if changed_firm == 0
	local stayers_or_not_in_RAIS = r(N)

	* Calculating total people in 50+ firms (for calculating the rate)
	local total = `movers' + `stayers_or_not_in_RAIS'

	* Returning to caller with results
	clear
	set obs 1
	gen month_from = `previous_month'
	gen month_to = `current_month'
	gen total_employees = `total'
	gen firm_movers = `movers'
	gen movement_rate = `movers'/`total'*100 // the variable that we care about

	display "Results: `movers' people moved between 50+ employee firms out of `total' total employees"
	display "Movement rate: " movement_rate[1] "%"


	* Appending results
	append using `results'
	save `results', replace

	* Updating previous month for next iteration
	local previous_month = `current_month'
}

* Load final results
use `results', clear

* Sorting by month
sort month_from month_to

* Displaying results
format movement_rate %5.2f
list month_from month_to total_employees firm_movers movement_rate, clean noobs

* Creating a string variable for month pairs
gen str month_pair = ""

* Manually assigning the month pair names in order (from month 647 to 660)
replace month_pair = "Dec/13-Jan/14" in 1
replace month_pair = "Jan/14-Feb/14" in 2
replace month_pair = "Feb/14-Mar/14" in 3
replace month_pair = "Mar/14-Apr/14" in 4
replace month_pair = "Apr/14-May/14" in 5
replace month_pair = "May/14-Jun/14" in 6
replace month_pair = "Jun/14-Jul/14" in 7
replace month_pair = "Jul/14-Aug/14" in 8
replace month_pair = "Aug/14-Sep/14" in 9
replace month_pair = "Sep/14-Oct/14" in 10
replace month_pair = "Oct/14-Nov/14" in 11
replace month_pair = "Nov/14-Dec/14" in 12
replace month_pair = "Dec/14-Jan/15" in 13


* Save the final results
save "${data}/monthly_movement_50plus_firms.dta", replace

* Creating graph of movement rates by months
gen order_index = _n

graph bar movement_rate, over(month_pair, sort(order_index) label(angle(45))) ///
    title("Monthly Movement Rate Between 50+ Employee Firms") ///
    ytitle("Movement Rate (%)")
graph export "${data}/movement_rate_graph.png", replace width(1000)


* Averages from dec-13 to Dec-14
drop if month_pair == "Dec/14-Jan/15"

summarize

/*
    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
  month_from |         12       652.5    3.605551        647        658
    month_to |         12       653.5    3.605551        648        659
total_empl~s |         12    4.73e+07    670102.7   4.60e+07   4.80e+07
 firm_movers |         12    251590.2    136772.3     158107     674733
movement_r~e |         12    .5340867    .2986197    .329094   1.457405
*/


****************************************************************************************************************************************

* Average number (and %) of people moving between +50 firms in between 12 months (Dec/13-Dec/14) 

* Processing each pair of consecutive months
local previous_month = 647 // Dec-13
local current_month = 659 // Dec-14

display "Processing movement from month `previous_month' to `current_month'"

* Loading current month data
use "${data}/rais_m/rais_m`current_month'.dta", clear

* Generating employee count per firm in current month
bysort plant_id: gen firm_size = _N

* Keeping essential variables
keep cpf plant_id firm_size
rename plant_id plant_id_current
rename firm_size firm_size_current

* Saving current month data
tempfile current
save `current'

* Loading previous month data
use "${data}/rais_m/rais_m`previous_month'.dta", clear

* Generating employee count per firm in previous month
bysort plant_id: gen firm_size = _N

* Keeping only 50+ employee firms
keep if firm_size >= 50

* Keeping essential variables
keep cpf plant_id firm_size
rename plant_id plant_id_previous
rename firm_size firm_size_previous

* Merging with current month data based on cpf
merge 1:1 cpf using `current'

* Keeping all people found in the first month
drop if _merge == 2
drop _merge

* Counting people who changed between 50+ emp firms 
gen changed_firm = (plant_id_previous != plant_id_current) & firm_size_current >= 50
replace changed_firm = 0 if missing(plant_id_current)

* Calculating total people who moved between 50+ firms
count if changed_firm == 1
local movers = r(N)

* Calculating total people who stayed (or are not in the mext month dataset) in 50+ firms
count if changed_firm == 0
local stayers_or_not_in_RAIS = r(N)

* Calculating total people in 50+ firms (for calculating the rate)
local total = `movers' + `stayers_or_not_in_RAIS'

* Returning to caller with results
clear
set obs 1
gen month_from = `previous_month'
gen month_to = `current_month'
gen total_employees = `total'
gen firm_movers = `movers'
gen movement_rate = `movers'/`total'*100 // the variable that we care about

display "Results: `movers' people moved between 50+ employee firms out of `total' total employees"
display "Movement rate: " movement_rate[1] "%"

/*
* Results: 2626530 people moved between 50+ employee firms out of 28258729 total employees
* Movement rate: 9.2945795%
*/






	
