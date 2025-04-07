
// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: October 2024

// Purpose: Summary statistics

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

set seed 12345	

// spv --> spv
use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_spv == 1
save "${temp}/summary_stats_spv", replace

	
// dir --> spv
use "${data}/poach_ind_dir", clear
merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
keep if type_spv == 1
gen d_size_ln = ln(d_size)
gen pc_exp_ln = ln(pc_exp)
gen o_size_ln = ln(o_size)
gen team_cw_ln = ln(team_cw)
save "${temp}/summary_stats_dir", replace

// emp --> spv
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_spv == 1
save "${temp}/summary_stats_emp", replace

// emp --> emp (placebo)
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_emp == 1
save "${temp}/summary_stats_emp_placebo", replace

// subsample of placebo with 5775 obs. (same number as spv --> spv and dir --> spv)
sample 5775, count
save "${temp}/summary_stats_emp_placebo_sample", replace

// spv --> spv + dir --> spv
use "${temp}/summary_stats_spv", clear
append using "${temp}/summary_stats_dir"
save "${temp}/summary_stats_spv_dir", replace
		
	

// TABLE 1: Variables that exist at origin and dest.
	
	// poached mgr wage
		// a. at destination: pc_wage_d
		// b. at origin: pc_wage_o_l1 // (in t-1)
		
	// raided worker wage   
		// a. at destination: rd_coworker_wage_d 
		// b. at origin: rd_coworker_wage_o
		
	// firm FE  
		// a. at destination: fe_firm_d
		// b. at origin: fe_firm_o
		
	// firm size     
		// a. at destination: d_size
		// b. at origin: o_size
	
	// worker FE    
		// a. at destination: 
		// b. at origin:
		
		

use "${temp}/summary_stats_spv", clear

* Drop tiny firms
drop if o_size <=45
/*
* Drop masive firms?
drop if o_size>10000 // 34 dropped
drop if d_size>10000 // 9 dropped
*/

keep  event_id pc_wage_o_l1 pc_wage_d fe_firm_o fe_firm_d o_size d_size rd_coworker_wage_o rd_coworker_wage_d pc_exp pc_age pc_fe

* Destination = 1, Origin = 2 
rename pc_exp pc_exp2
rename pc_age pc_age2
rename pc_fe pc_fe2
rename pc_wage_o_l1 pc_wage2
rename pc_wage_d pc_wage1
rename fe_firm_o fe_firm2
rename fe_firm_d fe_firm1
rename o_size size2
rename d_size size1
rename rd_coworker_wage_o rd_coworker_wage2
rename rd_coworker_wage_d rd_coworker_wage1

reshape long pc_wage fe_firm size rd_coworker_wage  pc_age pc_exp pc_fe, i(event_id) j(or_dest)


eststo clear
sort or_dest
eststo: estpost ttest pc_wage fe_firm size rd_coworker_wage, by(or_dest)

esttab using "${results}/summary_statistics_ttest.tex", replace ///
cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2)) t(fmt(2))") ///
collabels("Origin" "Destination" "Diff (D-O)" "T-stat") 


esttab using "${results}/summary_statistics_ttest.tex", replace,
cells("mu_1(fmt(2)) mu_2(fmt(2)) b(fmt(2)) t(fmt(2))") ///
collabels("Mean at origin" "Mean at dest." "Diff." "t-Statistic") 

///


// DANIELA'S VERSION OF TABLE 1:
/*

use "${temp}/summary_stats_spv", clear

* Drop tiny firms
drop if o_size <=45
/*
* Drop masive firms?
drop if o_size>10000 // 34 dropped
drop if d_size>10000 // 9 dropped
*/

keep  event_id pc_wage_o_l1 pc_wage_d fe_firm_o fe_firm_d o_size d_size rd_coworker_wage_o rd_coworker_wage_d pc_exp pc_age pc_fe

* Destination = 1, Origin = 2 
rename pc_exp pc_exp2
rename pc_age pc_age2
rename pc_fe pc_fe2
rename pc_wage_o_l1 pc_wage2
rename pc_wage_d pc_wage1
rename fe_firm_o fe_firm2
rename fe_firm_d fe_firm1
rename o_size size2
rename d_size size1
rename rd_coworker_wage_o rd_coworker_wage2
rename rd_coworker_wage_d rd_coworker_wage1

reshape long pc_wage fe_firm size rd_coworker_wage  pc_age pc_exp pc_fe, i(event_id) j(or_dest)

la var pc_wage "Wage"
la var pc_age "Age"
la var pc_exp "Experience"
la var pc_fe "Quality"
la var fe_firm "Wage premium"
la var size "Firm size (\# workers)"
la var rd_coworker_wage "Raided workers wage"

estpost su  fe_firm size rd_coworker_wage pc_wage pc_age pc_exp pc_fe if or_dest==2, d
est store sumO

estpost su  fe_firm size rd_coworker_wage pc_wage if or_dest==1, d
est store sumD 
				
* DISPLAY
esttab sumO sumD, label nonotes nonum ///
	cells("mean(fmt(2) label(Mean)) p10(fmt(2) label(10th pct)) p50(fmt(2) label(Median)) p90(fmt(2) label(90th pct))")

* EXPORT

esttab sumO sumD using "${results}/sumstats_simple.tex", booktabs replace ///
	label nonotes nonum ///
	mgroups("\textbf{Origin firm}" "\textbf{Destination firm}", pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	refcat(fe_firm "Firm variables" pc_wage "Manager variables" , nolabel) ///
	cells("mean(fmt(2) label(Mean)) p10(fmt(2) label(10th pct)) p50(fmt(2) label(Median)) p90(fmt(2) label(90th pct))") 


*/

// 
// TABLE 2: Variables that exist only in either origin or dest

	// poached worker age 
		// a. at destination: pc_age 
		// b. at origin: pc_age 
		
	// existing worker age
		// a. at destination: 
		// b. at origin:
		
	// poached experience
		// a. at destination: pc_exp 
		// b. at origin: pc_exp	
		
	// By def: only at dest.
	// existing mgr wage
		// a. at destination: 
		// b. at origin:
		
	// existing worker wage  
		// a. at destination: 
		// b. at origin:
		

	// existing experience
		// a. at destination: 
		// b. at origin:
	
	
	local vars pc_age pc_exp 
	
	eststo clear
		
		eststo: estpost summarize `vars', detail
		
		esttab using "$results/summary_statistics.tex", replace ///
			refcat(pc_wage_d "Wage of pc. mgr. at dest." ///
				pc_wage_o_l1 "\\ Wage of pc. mgr. at origin" ///
				rd_coworker_wage_d "\\ Wage of raided worker at dest." ///
				rd_coworker_wage_o "\\ Wage of raided worker at origin" ///
				pc_age "\\ Age of pc. mgr." ///
				pc_exp "\\ Experience of pc. mgr." ///
				fe_firm_d "\\ Dest. firm AKM FE" ///
				fe_firm_o "\\ Origin firm AKM FE" ///
				d_size "\\ Dest. firm size" ///
				o_size "\\ Origin firm size", nolabel) ///
			cells("p50(fmt(2)) mean(fmt(2)) sd(fmt(2))") nostar unstack nonumber ///
			compress nonote gap label booktabs frag nomtitle ///
			collabels("Median" "Mean" "SD")
			
			
	
