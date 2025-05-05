// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 5
// "The salary of a poached manager, on average, increases in the supply information, i.e., when poached by a larger firm"

*--------------------------*
* PREPARE
*--------------------------*

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
	
	gen o_size_ln = ln(o_size)
		
	la var o_size_ln "Size (ln \# empl)"
	la var o_avg_worker_akm_fe "Avg worker ability"
	
	// analysis
	
		// sample selection
		drop if ratio_cw_new_hire>1 // TEMPORARY UNTIL PERMANENT FIX IN DATA CONSTRUCTION!!!
		// the issue here is that total hires in calculated after t=0 only, but raids start in t=-12

		// globals
		global mgr "main_exp_ln main_worker_akm_fe main_worker_akm_fe_m"
		global spvcond "(type==5 | (type==6 & waged_spvemp==10) | (type==8 & waged_empspv==10)) "
		global raidcond "rdpc_coworker_n>=1"
		global firm_d "d_size_ln d_growth"
		
		// baseline events (spv-spv, mostly)
			
		eststo c2_spv_5: reg main_wage_d o_size_ln o_avg_worker_akm_fe  ///
			main_wage_o_l1  ///
			if $raidcond & $spvcond, rob
			
			estadd local events "All"
			
		eststo c3_spv_5: reg main_wage_d c.o_size_ln##c.o_avg_worker_akm_fe /// 
			main_wage_o_l1 ///
			if $raidcond &  $spvcond ///
			& rd_coworker_n>=1, rob
				
			estadd local events "All"
			
		eststo c4_spv_5: reg main_wage_d  c.o_size_ln##c.o_avg_worker_akm_fe tenure_overlap_full i.tenure_overlap_full_m /// 
			main_wage_o_l1 ///
			if $raidcond & $spvcond ///
			& rd_coworker_n>=1, rob
				
			estadd local events "All"		
				  
		eststo c5_spv_5: reg main_wage_d  c.o_size_ln##c.o_avg_worker_akm_fe tenure_overlap_full i.tenure_overlap_full_m /// 
			main_wage_o_l1 $mgr ///
			 if $raidcond &  $spvcond ///
			& rd_coworker_n>=1, rob
				
			estadd local events "All"	
				
		eststo c6_spv_5: reg main_wage_d  c.o_size_ln##c.o_avg_worker_akm_fe tenure_overlap_full  i.tenure_overlap_full_m /// 
			main_wage_o_l1 $mgr $firm_d ///
			if $raidcond & $spvcond ///
			& rd_coworker_n>=1, rob
				
			estadd local events "All"
			
			estadd local pred "5"
	
		eststo c7_spv_5: reg main_wage_d  c.o_size_ln##c.o_avg_worker_akm_fe tenure_overlap_full i.tenure_overlap_full_m /// 
			main_wage_o_l1 $mgr $firm_d ///
			if $raidcond & $spvcond ///
			, rob
				
			estadd local events "All"
					
		// spv-emp		
		
		qui eststo c5_spvs_5: reg main_wage_d c.o_size_ln##c.o_avg_worker_akm_fe    /// 
				main_wage_o_l1 $mgr $firm_d ///
				if (type==2 & waged_spvemp<10 & waged_spvemp>=1) ///
				& $raidcond, rob
				
				estadd local pred "5"
		
		// emp-spv
		
		qui eststo c5_espv_5: reg main_wage_d c.o_size_ln##c.o_avg_worker_akm_fe    /// 
				main_wage_o_l1 $mgr $firm_d ///
				if (type==3 & waged_empspv<10 & waged_empspv>=1) ///
				& $raidcond, rob 
				
				estadd local pred "5"
		
		// display table
		    
		esttab c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c6_spv_5 c7_spv_5,  /// 
			replace compress noconstant nomtitles nogap collabels(none) label ///   
			mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv"  "spv-spv") ///
			keep(o_size_ln o_avg_worker_akm_fe  c.o_size_ln#c.o_avg_worker_akm_fe tenure_overlap_full) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\textbf{Manager controls} \\ Manager salary at origin = main_wage_o_l1" ///
			"Manager experience = main_exp_ln" "Manager ability = main_worker_akm_fe" ///
			"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_ln" "Destination firm growth = d_growth"  ///
			, labels("\cmark" ""))
		
		// save table
		
		esttab c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c6_spv_5 c7_spv_5 using "${results}/202503_pred5.tex", booktabs  /// 
			replace compress noconstant nomtitles nogap collabels(none) label /// 
			refcat(o_size_ln "\midrule \\ \textbf{Origin firm}", nolabel) ///
			mgroups("Outcome: Manager ln(salary) at destination",  ///
			pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
			keep(o_size_ln o_avg_worker_akm_fe c.o_size_ln#c.o_avg_worker_akm_fe tenure_overlap_full) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///    
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = main_wage_o_l1" ///
			"Manager experience = main_exp_ln" "Manager ability = main_worker_akm_fe" ///
			"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_ln" "Destination firm growth = d_growth"  ///
			, labels("\cmark" ""))	
		

