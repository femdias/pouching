// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Number of hired people at destination poached mgrs. (table on attracted people)

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_spv == 1
save "${temp}/reg_wage_hired_at_d_spv", replace
	
use "${data}/poach_ind_dir", clear
merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
keep if type_spv == 1
save "${temp}/reg_wage_hired_at_d_dir", replace
	
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_spv == 1
save "${temp}/reg_wage_hired_at_d_emp", replace

use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_emp == 1
save "${temp}/reg_wage_hired_at_d_emp_placebo", replace
	
use "${temp}/reg_wage_hired_at_d_spv", clear
append using "${temp}/reg_wage_hired_at_d_dir"
append using "${temp}/reg_wage_hired_at_d_emp"
save "${temp}/reg_wage_hired_at_d_all", replace

use "${temp}/reg_wage_hired_at_d_spv", clear
append using "${temp}/reg_wage_hired_at_d_dir"
save "${temp}/reg_wage_hired_at_d_spv_dir", replace


foreach e in spv dir emp emp_placebo all spv_dir {
	
	use "${temp}/reg_wage_hired_at_d_`e'", clear

// Creating dummy = 1 if no new hires -- recreating this variable, because it does not look right
drop d_hire_d0
gen d_hire_d0 = 1 if d_hire == 0
replace d_hire_d0 = 0 if d_hire != 0
		
	// Handling missing values 
	local missingvars pc_exp_ln pc_fe d_size_ln fe_firm_d d_wage_real_ln ratio_cw_new_hire ///
			  d_hire rd_coworker_n_ln d_size_ln turnover d_team_cw_ln
							 
	foreach var of local missingvars {
								
		misstable summ `var'
								
		if `r(N_eq_dot)' > 0 & `r(N_eq_dot)' < . {
									
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		}
	}
	// regressions
	
	local pcctrl "pc_exp_ln pc_exp_ln_m pc_fe pc_fe_m"
	local dctrl  "d_wage_real_ln fe_firm_d fe_firm_d_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		// Col 1: destination firm log # raided workers
		eststo c1_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob
	
		// Col 2: destination firm (# raided workers / # new hires)
		eststo c2_`e': reg pc_wage_d ratio_cw_new_hire ratio_cw_new_hire_m ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob
		
		// Col 3: destination firm log # raided workers CONTROLLING FOR # new hires
		eststo c3_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				d_hire ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob

		// Col 4: destination firm log # raided workers CONTROLLING FOR # new hires AND firm size (# total emp)
		eststo c4_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				d_hire d_size_ln d_size_ln_m ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob
		
		// Col 5: destination firm log # raided workers CONTROLLING FOR # new hires AND firm size (# total emp) AND turnover rate 
		eststo c5_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				d_hire d_size_ln d_size_ln_m turnover ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob
		
		// Col 6: destination firm log # raided workers CONTROLLING FOR # new hires AND firm size (# total emp) AND the # current workers in the same occupational code as the poached manager
		eststo c6_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				d_hire d_size_ln d_size_ln_m  d_team_cw_ln d_team_cw_ln_m ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob

		// Col 7: all these together
		eststo c7_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				ratio_cw_new_hire ratio_cw_new_hire_m turnover  ///
				d_hire d_size_ln d_size_ln_m  d_team_cw_ln d_team_cw_ln_m ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob
		
		// Col 8: all these together, plus destination firm controls (log of destination firm wage bill, destination firm AKM firm FE)
		eststo c8_`e': reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				ratio_cw_new_hire ratio_cw_new_hire_m turnover  ///
				d_hire d_size_ln d_size_ln_m  d_team_cw_ln d_team_cw_ln_m ///
				`pcctrl' `dctrl' if pc_ym >= ym(2010,1), rob
			
			
	// table
    
	* DISPLAY
}

foreach e in spv dir emp emp_placebo all spv_dir {

esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' c7_`e' c8_`e' /// 
    using "${results}/reg_wage_hired_at_d_pc_`e'.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached mgr. (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(rd_coworker_n_ln ratio_cw_new_hire) /// 
    cells(b(star fmt(3)) se(par fmt(3))) ///  // Only standard errors, no p-values
    coeflabels(rd_coworker_n_ln "\hline \\ Number of raided workers (ln)" /// 
        ratio_cw_new_hire "Share of raided new hires") ///
    refcat(o_size_ln "\textit{Destination firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ \textbf{Poached manager controls} \\ Years of experience = *pc_exp_ln*" "AKM FE (individual) = *pc_fe*" ///
        "\\ \textbf{Destination firm controls} \\ Firm size (ln) = *d_size_ln*" "Avg. wage bill (ln) = *d_wage_real_ln*" "AKM FE (firm) = *fe_firm_d*" "\\ Turnover = *turnover*" "Potential team size = *d_team_cw_ln*" "Size of new hires=*d_hire*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
}
