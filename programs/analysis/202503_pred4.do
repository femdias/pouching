// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 4
// "The salary of a poached manager, on average, increases in the demand for information, i.e., when poached by a larger firm"

*--------------------------*
* PREPARE
*--------------------------

	use "${data}/202503_poach_ind", clear
	
	// which are the events we are interested in?
	gen keep = .
				
		// identify the main events events we're interested in 
		merge m:1 eventid using "${temp}/202503_eventlist"
		replace keep = 1 if _merge == 3
		drop _merge
	
	keep if keep == 1
	
	// organizing some variables for this analysis

	replace main_worker_akm_fe = -99 if main_worker_akm_fe==.
	gen main_worker_akm_fe_m = (main_worker_akm_fe == -99)
	
	gen main_exp_ln = ln(main_exp)

	la var d_size_ln "Size (ln)"
	la var d_growth "Empl. growth rate"
	
	// analysis
	
		// sample selection
		drop if ratio_cw_new_hire>1 // TEMPORARY UNTIL PERMANENT FIX IN DATA CONSTRUCTION!!!
		// the issue here is that total hires in calculated after t=0 only, but raids start in t=-12
		
		// globals
		global mgr "main_exp_ln main_worker_akm_fe main_worker_akm_fe_m"
		global spvcond "(type==5 | (type==6 & waged_spvemp==10) | (type==8 & waged_empspv==10)) "
		global raidcond "rdpc_coworker_n>=1"
		
			// TO BE SOLVED: raidpc_coworker_n inclui desde t=-12!
			// eu acho que deveria recalcular isso usando evt_panel_m e usar somente a some pós t=-12

		// baseline events (spv-spv, mostly)
		
		eststo c3_spv_4: reg main_wage_d d_size_ln d_growth    ///
			main_wage_o_l1 ///
			if $raidcond & $spvcond, rob
							
		eststo c4_spv_4: reg main_wage_d d_size_ln d_growth    ///
			main_wage_o_l1 main_exp_ln ///
			if $raidcond & $spvcond, rob
							
		eststo c5_spv_4: reg main_wage_d d_size_ln d_growth     ///
			main_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob	
							
			estadd local pred "3"
			
		eststo c6_spv_4: reg main_wage_d d_size_ln d_growth     ///
			main_wage_o_l1  $mgr ///
			if $spvcond, rob	
							
		/*
		
		// spv-emp		
							
		eststo c5_spvs_4: reg main_wage_d d_size_ln d_growth     ///
			main_wage_o_l1 $mgr ///
			if $raidcond  & (type==2 & waged_spvemp<10 & waged_spvemp>=1), rob
						
			estadd local pred "3"
								
		// emp-spv
					
		eststo c5_epvs_4: reg main_wage_d d_size_ln d_growth   ///
			main_wage_o_l1 $mgr ///
			if $raidcond  & (type==3 & waged_empspv<10 & waged_empspv>=1) , rob
							
			estadd local pred "3"
			
		*/
		
		// display table

		esttab  c3_spv_4 c4_spv_4 c5_spv_4 c6_spv_4,  /// 
			replace compress noconstant nomtitles nogap collabels(none) label ///   
			mlabel("spv-spv" "spv-spv"  "spv-spv" "spv-spv") ///
			keep(d_size_ln d_growth) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\textbf{Manager controls} \\ Manager salary at origin = main_wage_o_l1" ///
			"Manager experience = main_exp_ln" "Manager ability = main_worker_akm_fe"  ///
			, labels("\cmark" ""))
					  
		// save table

		esttab c3_spv_4 c4_spv_4 c5_spv_4 c6_spv_4 using "${results}/202503_pred4.tex", booktabs  /// 
			replace compress noconstant nomtitles nogap collabels(none) label /// 
			refcat(d_size_ln "\midrule \\ \textbf{Destination firm}", nolabel) ///
			mgroups("Outcome: ln(salary) at destination",  /// 
			pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
			keep(d_size_ln d_growth) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///    
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = main_wage_o_l1" ///
			"Manager experience = main_exp_ln" "Manager ability = main_worker_akm_fe"  /// 
			, labels("\cmark" ""))
			
			
