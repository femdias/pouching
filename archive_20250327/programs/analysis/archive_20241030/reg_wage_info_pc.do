// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Information: poached mgrs.

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

* evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
	use "${data}/poach_ind_spv", clear // start with 15,513 events
	* we need to bind to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen // 13,907 events
	* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen // 13,907 events
	* keep only people that became spv
	keep if type_spv == 1 // 4,619 events
	tempfile spv
	save `spv'
	
	use "${data}/poach_ind_dir", clear // 12,269 events
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen // 11,638 events
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen // 11,638 events
	keep if type_spv == 1 // 1,156 events
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
	
	local missingvars pc_exp_ln pc_fe d_size_ln fe_firm_d d_wage_real_ln ///
			  o_size_ln o_ratio_team_ln o_avg_fe_worker pc_wage_o_l1 ///
			  o_size_ratio team_cw_ln ratio_above_75th
							 
	foreach var of local missingvars {
								
		misstable summ `var'
								
		if `r(N_eq_dot)' > 0 & `r(N_eq_dot)' < . {
									
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		}
	}


	// regressions
	
	local pcctrl "pc_exp_ln pc_exp_ln_m pc_fe pc_fe_m"
	local dctrl1  "d_size_ln d_wage_real_ln"
	local dctrl2  "d_size_ln d_wage_real_ln fe_firm_d fe_firm_d_m"

	eststo clear
	
		eststo c1: reg pc_wage_d o_size_ln o_size_ln_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
				
		eststo c2: reg pc_wage_d o_ratio_team_ln o_ratio_team_ln_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
		eststo c3: reg pc_wage_d o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
		
		eststo c4: reg pc_wage_d o_size_ln o_size_ln_m o_ratio_team_ln o_ratio_team_ln_m ///
				o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			
		
			
	// table


esttab c1 c2 c3 c4 ///
    using "${results}/reg_wage_info_pc.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached mgr. (at dest.)", ///
        pattern(1 0 0 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    keep(o_size_ln o_ratio_team_ln o_avg_fe_worker) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" ///
        o_ratio_team_ln  "Potential team size (ln)" /// * including this var
        o_avg_fe_worker "Avg. worker quality (AKM FE)") ///
	refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ \textbf{Poached manager controls} \\ Years of experience = *pc_exp_ln*" "AKM FE (individual) = *pc_fe*" ///
        "\\ \textbf{Destination firm controls} \\ Firm size (ln) = *d_size_ln*" "Avg. wage bill (ln) = *d_wage_real_ln*" "AKM FE (firm) = *fe_firm_d*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01)
    
    
    // v2: here we are including ln wage of poached manager at origin at t = -1 as control
    local pcctrl "pc_exp_ln pc_exp_ln_m pc_fe pc_fe_m pc_wage_o_l1"
    local dctrl2  "d_size_ln d_wage_real_ln fe_firm_d fe_firm_d_m"

    eststo clear
	
		eststo c1: reg pc_wage_d o_size_ln o_size_ln_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
				
		eststo c2: reg pc_wage_d o_ratio_team_ln o_ratio_team_ln_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
		eststo c3: reg pc_wage_d o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
		
		eststo c4: reg pc_wage_d o_size_ln o_size_ln_m o_ratio_team_ln o_ratio_team_ln_m ///
				o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		

esttab c1 c2 c3 c4 ///
    using "${results}/reg_wage_info_pc_with_pc_wage_o.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached mgr. (at dest.)", ///
        pattern(1 0 0 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    keep(o_size_ln o_ratio_team_ln o_avg_fe_worker) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" ///
        o_ratio_team_ln  "Potential team size (ln)" /// * including this var
        o_avg_fe_worker "Avg. worker quality (AKM FE)") ///
	refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ \textbf{Poached manager controls} \\ Years of experience = *pc_exp_ln*" "AKM FE (individual) = *pc_fe*"  ///
        "ln(wage) at origin = *pc_wage_o_l1*" "\\ \textbf{Destination firm controls} \\ Firm size (ln) = *d_size_ln*" "Avg. wage bill (ln) = *d_wage_real_ln*" "AKM FE (firm) = *fe_firm_d*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01)
    
    
    
    // v3: changing vars.
    local pcctrl "pc_exp_ln pc_exp_ln_m pc_fe pc_fe_m"
	local dctrl1  "d_size_ln d_wage_real_ln"
	local dctrl2  "d_size_ln d_wage_real_ln fe_firm_d fe_firm_d_m"

	eststo clear
	
		// col 1: origin firm log # emp
		eststo c1: reg pc_wage_d o_size_ln o_size_ln_m ///
				`pcctrl'  if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		// col 2: origin firm (# emp / # mgr) 		
		eststo c2: reg pc_wage_d o_size_ratio o_size_ratio_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		// col 3: origin firm # emp  within same occ cat. as pc mgr.		
		eststo c3: reg pc_wage_d team_cw_ln team_cw_ln_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		// col 4: origin firm (# emp / # mgr) within same occ cat. as pc mgr.		
		eststo c4: reg pc_wage_d o_ratio_team_ln o_ratio_team_ln_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		// col 5: origin firm avg. AKM FE (avg AKM FE of workers in origin firm)
		eststo c5: reg pc_wage_d o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl'  if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		// col 6: origin firm sh. of workers with above-75pctile AKM FE
		eststo c6: reg pc_wage_d ratio_above_75th ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
		// col 7: all of these together
		eststo c7: reg pc_wage_d o_size_ln o_size_ln_m o_size_ratio o_size_ratio_m ///
				team_cw_ln team_cw_ln_m o_ratio_team_ln o_ratio_team_ln_m o_avg_fe_worker ///
				o_avg_fe_worker_m ratio_above_75th ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
				
		// col 8: all of these together + dest firm controls
		eststo c8: reg pc_wage_d o_size_ln o_size_ln_m o_size_ratio o_size_ratio_m ///
				team_cw_ln team_cw_ln_m o_ratio_team_ln o_ratio_team_ln_m o_avg_fe_worker ///
				o_avg_fe_worker_m ratio_above_75th ///
				`pcctrl' `dctrl2' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
		
			
	// table


esttab c1 c2 c3 c4 c5 c6 c7 c8 ///
    using "${results}/reg_wage_info_pc_initial_version.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached manager (at destination)", ///
        pattern(1 0 0 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    keep(o_size_ln o_size_ratio team_cw_ln o_ratio_team_ln o_avg_fe_worker ratio_above_75th) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" ///
	o_size_ratio "Size / Number of mgrs." ///
	team_cw_ln "Size same cat. as mgr. (ln)" ///
        o_ratio_team_ln  "Potential team size (ln)" /// * including this var
        o_avg_fe_worker "Avg. worker quality (AKM FE)" ///
	ratio_above_75th "Sh. of workers above 75th pctile AKM FE") ///
	refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ \textbf{Poached manager controls} \\ Years of experience = *pc_exp_ln*" "AKM FE (individual) = *pc_fe*" ///
        "\\ \textbf{Destination firm controls} \\ Firm size (ln) = *d_size_ln*" "Avg. wage bill (ln) = *d_wage_real_ln*" "AKM FE (firm) = *fe_firm_d*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01)
    
    

