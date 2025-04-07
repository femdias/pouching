// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Information: poached non-mgrs. - PLACEBO!

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

	
	use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_emp == 1
	tempfile emp
	save `emp'
	
	
	use `emp', clear
	
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
	
		eststo c1: reg pc_wage_d o_size_ln ///
				`pcctrl' `dctrl2' if type_emp == 1 & pc_ym >= ym(2010,1), rob
			
				
		eststo c2: reg pc_wage_d o_ratio_team_ln o_ratio_team_ln_m ///
				`pcctrl' `dctrl2' if type_emp == 1 & pc_ym >= ym(2010,1), rob
			
		eststo c3: reg pc_wage_d o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl2' if type_emp == 1 & pc_ym >= ym(2010,1), rob
			
		
		eststo c4: reg pc_wage_d o_size_ln o_ratio_team_ln o_ratio_team_ln_m ///
				o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl2' if type_emp == 1 & pc_ym >= ym(2010,1), rob
		
			
		
			
	// table


esttab c1 c2 c3 c4 ///
    using "${results}/reg_wage_info_nonpc.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached non-mgr. (at dest.)", ///
        pattern(1 0 0 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
    keep(o_size_ln o_ratio_team_ln o_avg_fe_worker) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" ///
        o_ratio_team_ln  "Potential team size (ln)" /// * including this var
        o_avg_fe_worker "Avg. worker quality (AKM FE)") ///
	refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ \textbf{Poached non-mgr. controls} \\ Years of experience = *pc_exp_ln*" "AKM FE (individual) = *pc_fe*" ///
        "\\ \textbf{Destination firm controls} \\ Firm size (ln) = *d_size_ln*" "Avg. wage bill (ln) = *d_wage_real_ln*" "AKM FE (firm) = *fe_firm_d*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01)
    
    
