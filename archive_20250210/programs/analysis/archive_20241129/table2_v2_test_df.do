// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Table 2

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
save "${temp}/table2_spv", replace

	
// dir --> spv
use "${data}/poach_ind_dir", clear
merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
keep if type_spv == 1
gen d_size_ln = ln(d_size)
gen pc_exp_ln = ln(pc_exp)
gen o_size_ln = ln(o_size)
gen team_cw_ln = ln(team_cw)
save "${temp}/table2_dir", replace

// emp --> spv
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_spv == 1
save "${temp}/table2_emp", replace

// emp --> emp (placebo)
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_emp == 1
save "${temp}/table2_emp_placebo", replace

// subsample of placebo with 5775 obs. (same number as spv --> spv and dir --> spv)
sample 5775, count
save "${temp}/table2_emp_placebo_sample", replace

// spv --> spv + dir --> spv
use "${temp}/table2_spv", clear
append using "${temp}/table2_dir"
save "${temp}/table2_spv_dir", replace

// spv --> emp
use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_emp == 1
save "${temp}/table2_spv_emp", replace


// TABLE FOR SPV --> SPV + DIR --> SPV

use "${temp}/table2_spv_dir", clear
	
	// Handling missing values 
	local missingvars d_size_ln pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  o_size_ln o_avg_fe_worker team_cw_ln department_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "d_size_ln pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "d_size_ln_m pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
	
		eststo c2_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c3_`e': reghdfe pc_wage_d team_cw_ln team_cw_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c4_`e': reghdfe pc_wage_d team_cw_ln team_cw_ln_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c5_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c6_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  pc_wage_o_l1 pc_wage_o_l1_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
    
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
	
esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' /// 
    using "${results}/table2_spv_dir_v2.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(o_size_ln o_avg_fe_worker team_cw_ln department_fe) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" /// 
        o_avg_fe_worker "Avg. worker quality (AKM FE)" ///
	team_cw_ln "Department size (ln)" ///
	department_fe "Avg. worker quality by department (AKM FE)") ///
    refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 cnae_d pc_ym, fmt(0 3 0 0) label(" \\ Obs" "R-Squared" "\\ Dest. CNAE (2 dig.)" "Event time FE")) ///
    obslast nolines ///
     indicate("\\ Size (ln) of dest. firm = *d_size_ln*" "Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 



// TABLE FOR EMP --> EMP (SAMPLE)	
use "${temp}/table2_emp_placebo_sample", clear
	
	// Handling missing values 
	local missingvars d_size_ln pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  o_size_ln o_avg_fe_worker team_cw_ln department_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "d_size_ln pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "d_size_ln_m pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
	
		eststo c2_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c3_`e': reghdfe pc_wage_d team_cw_ln team_cw_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c4_`e': reghdfe pc_wage_d team_cw_ln team_cw_ln_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c5_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c6_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  pc_wage_o_l1 pc_wage_o_l1_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
    
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
	
esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' /// 
    using "${results}/table2_emp_placebo_sample_v2.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(o_size_ln o_avg_fe_worker team_cw_ln department_fe) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" /// 
        o_avg_fe_worker "Avg. worker quality (AKM FE)" ///
	team_cw_ln "Department size (ln)" ///
	department_fe "Avg. worker quality by department (AKM FE)") ///
    refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 cnae_d pc_ym, fmt(0 3 0 0) label(" \\ Obs" "R-Squared" "\\ Dest. CNAE (2 dig.)" "Event time FE")) ///
    obslast nolines ///
     indicate("\\ Size (ln) of dest. firm = *d_size_ln*" "Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
	
}




// TABLE CONSIDERING INTERACTION BETWEEN FIRM SIZE AND DEPARTMENT SIZE
foreach e in spv_dir emp_placebo_sample {  // 
	
	display "`e'"
	use "${temp}/table2_`e'", clear
	
	// Handling missing values 
	local missingvars d_size_ln pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  o_size_ln o_avg_fe_worker team_cw_ln department_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "d_size_ln pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "d_size_ln_m pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
	
		eststo c2_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c3_`e': reghdfe pc_wage_d team_cw_ln team_cw_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c4_`e': reghdfe pc_wage_d team_cw_ln team_cw_ln_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c7_`e': reghdfe pc_wage_d c.o_size_ln#c.team_cw_ln o_size_ln_m team_cw_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
	
				
		eststo c5_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  c.o_size_ln#c.team_cw_ln ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c6_`e': reghdfe pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  pc_wage_o_l1 pc_wage_o_l1_m c.o_size_ln#c.team_cw_ln ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
    
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
	
esttab c1_`e' c2_`e' c3_`e' c7_`e' c4_`e' c5_`e' c6_`e' /// 
    using "${results}/table2_`e'_v2.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(o_size_ln o_avg_fe_worker team_cw_ln department_fe c.o_size_ln#c.team_cw_ln) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" /// 
        o_avg_fe_worker "Avg. worker quality (AKM FE)" ///
	team_cw_ln "Department size (ln)" ///
	department_fe "Avg. worker quality by department (AKM FE)" ///
	c.o_size_ln#c.team_cw_ln "Interaction between firm and department size") ///
    refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 cnae_d pc_ym, fmt(0 3 0 0) label(" \\ Obs" "R-Squared" "\\ Dest. CNAE (2 dig.)" "Event time FE")) ///
    obslast nolines ///
     indicate("\\ Size (ln) of dest. firm = *d_size_ln*" "Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
	
}











