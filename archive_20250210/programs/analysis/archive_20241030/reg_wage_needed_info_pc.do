// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Information needed at destination for mgrs. (table: information needed)

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS


	* evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
	use "${data}/poach_ind_spv", clear
	* we need to bind to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	* keep only people that became spv
	keep if type_spv == 1
	tempfile spv
	save `spv'
	
	
	use "${data}/poach_ind_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
	keep if type_spv == 1
	tempfile dir
	save `dir'
	
	use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_spv == 1
	tempfile emp
	save `emp'

	
	
	use `spv', clear
	append using `dir'
	append using `emp'
	
	// Handling missing values
	local missingvars pc_exp_ln pc_fe d_size_ln fe_firm_d d_wage_real_ln ///
			  d_size_ln d_growth_winsor turnover 
	
	// o_size_ln o_size_ratio o_size_ratio_ln ///
	// o_size_ratio_winsor team_cw_ln o_ratio_team o_ratio_team_ln o_ratio_team_winsor o_avg_fe_worker d_growth  ///
	// d_growth_winsor turnover rd_coworker_n_ln ratio_cw_new_hire d_hire_l12 d_team_cw_ln
						
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
	eststo clear
	
		eststo c1: reg pc_wage_d d_size_ln d_size_ln_m ///
				`pcctrl' `dctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
		eststo c2: reg pc_wage_d d_growth_winsor d_growth_winsor_m ///
				`pcctrl' `dctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		eststo c3: reg pc_wage_d turnover  ///
				`pcctrl' `dctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		eststo c4: reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m turnover  ///
				`pcctrl' `dctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			
		
			
	// table
	

esttab c1 c2 c3 c4 ///
    using "${results}/reg_wage_needed_info_pc.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached mgr. (at dest.)", ///
        pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    keep(d_size_ln d_growth_winsor turnover) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(d_size_ln "\hline \\ Size (ln)" ///
        d_growth_winsor "Growth rate" ///
	turnover "Annual turnover rate") ///
    refcat(d_size_ln "\textit{Destination firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ \textbf{Poached manager controls} \\ Years of experience = *pc_exp_ln*" "AKM FE (individual) = *pc_fe*" ///
        "\\ \textbf{Destination firm controls} \\ Avg. wage bill (ln) = *d_wage_real_ln*" "AKM FE (firm) = *fe_firm_d*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
    
    
