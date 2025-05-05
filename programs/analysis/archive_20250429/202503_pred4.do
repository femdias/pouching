// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 4
// "The salary of a poached manager, on average, increases in the demand for information, i.e., when poached by a larger firm"

*--------------------------*
* PREPARE
*--------------------------

	use "${data}/poaching_evt", clear
	
	// we're only interested in spv-spv, spv-emp, and emp-spv
	keep if type == 1 | type == 2 | type == 3
	
	// organizing some variables for this analysis

	replace pc_fe = -99 if pc_fe==.
	replace rd_coworker_fe = -99 if rd_coworker_fe==.

	*la var d_size_w_ln "Dest. firm size (ln)"
	la var d_growth_w "Dest. firm empl. growth rate"
	la var rd_coworker_fe "Quality of raided workers" 
	
	// analysis
	
		// sample selection
		drop if ratio_cw_new_hire>1 // TEMPORARY UNTIL PERMANENT FIX IN DATA CONSTRUCTION!!!
		
		// globals
		global mgr "pc_exp_ln pc_fe pc_fe_m"
		global spvcond "(type==1 | (type==2 & waged_spvemp==10) | (type==3 & waged_empspv==10)) "
		global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

		// baseline events (spv-spv, mostly)
		
		/*
		
		eststo c0_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
				if $raidcond & $spvcond, rob
		
		eststo c3_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
				pc_wage_o_l1 ///
				if $raidcond & $spvcond, rob
				
		eststo c4_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
				pc_wage_o_l1 pc_exp_ln ///
				if $raidcond & $spvcond, rob
				
		eststo c5_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
				pc_wage_o_l1  $mgr ///
				if $raidcond & $spvcond, rob
				
			estadd local pred "4"	
				
		// spv-emp		
				
		eststo c5_spvs_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
				pc_wage_o_l1 $mgr ///
				if $raidcond  & (type==2 & waged_spvemp<10 & waged_spvemp>=1), rob
			
			estadd local pred "4"
					
		// emp-spv
		
		eststo c5_epvs_4: reg pc_wage_d d_size_w_ln d_growth_w    ///
				pc_wage_o_l1 $mgr ///
				if $raidcond  & (type==3 & waged_empspv<10 & waged_empspv>=1) , rob
				
			estadd local pred "4"
		
		*/
		
					eststo c0_spv_4: reg pc_wage_d d_size_ln d_growth_w     ///
							if $raidcond & $spvcond, rob
					
					eststo c3_spv_4: reg pc_wage_d d_size_ln d_growth_w     ///
							pc_wage_o_l1 ///
							if $raidcond & $spvcond, rob
							
					eststo c4_spv_4: reg pc_wage_d d_size_ln d_growth_w    ///
							pc_wage_o_l1 pc_exp_ln ///
							if $raidcond & $spvcond, rob
							
					eststo c5_spv_4: reg pc_wage_d d_size_ln d_growth_w     ///
							pc_wage_o_l1  $mgr ///
							if $raidcond & $spvcond, rob
							
						estadd local pred "4"	
							
					// spv-emp		
							
					eststo c5_spvs_4: reg pc_wage_d d_size_ln d_growth_w     ///
							pc_wage_o_l1 $mgr ///
							if $raidcond  & (type==2 & waged_spvemp<10 & waged_spvemp>=1), rob
						
						estadd local pred "4"
								
					// emp-spv
					
					eststo c5_epvs_4: reg pc_wage_d d_size_ln d_growth_w    ///
							pc_wage_o_l1 $mgr ///
							if $raidcond  & (type==3 & waged_empspv<10 & waged_empspv>=1) , rob
							
						estadd local pred "4"
		
		
		// display table
		
		/*
		
		esttab  c0_spv_4 c3_spv_4 c4_spv_4 c5_spv_4,  /// 
			replace compress noconstant nomtitles nogap collabels(none) label ///   
			mlabel("spv-spv" "spv-spv"  "spv-spv" "spv-spv") ///
			keep(d_size_w_ln d_growth_w) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
			"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
			, labels("\cmark" ""))
			
		*/	
			
			
						esttab  c0_spv_4 c3_spv_4 c4_spv_4 c5_spv_4,  /// 
						replace compress noconstant nomtitles nogap collabels(none) label ///   
						mlabel("spv-spv" "spv-spv"  "spv-spv" "spv-spv") ///
						keep(d_size_ln d_growth_w) ///
						cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
						stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
						obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
						indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
						"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
						, labels("\cmark" ""))
					 
		 
		// save table

		esttab c0_spv_4 c3_spv_4 c4_spv_4 c5_spv_4 using "${results}/202503_pred4.tex", booktabs  /// 
			replace compress noconstant nomtitles nogap collabels(none) label /// 
			refcat(d_size_w_ln "\midrule", nolabel) ///
			mgroups("Outcome: Manager ln(salary) at destination",  /// 
			pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
			keep(d_size_w_ln d_growth_w) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///    
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
			"Manager experience = pc_exp_ln" "Manager quality = pc_fe"  /// 
			, labels("\cmark" ""))
			
			
			/*
			
			
			
			
			
			
*--------------------------*
* ANALYSIS (EVALUATE THE ROLE OF INFORMATION)
*--------------------------*		
	
	// for this analysis, we also need information on the non-poached managers
	// I will use the data set from Prediction 3 and merge it with some info from this data set
	
	use "${temp}/pred3_end", clear
	
		// outcome variable: log wage at destination
		* already in data set: wage_real_ln
		
		// destination firm size
		* use d_size_w_ln for pred4
		
		// destination employment growth
		* use d_growth_w from pred4
		
		// raids / no raids
		* use rd_coworker_n from pred4
		
		// fe_worker exists in pred3
		
		// exp_ln exists in pred3
		
		// pc_ym exists in pred3
		
		// use rd_coworker_fe_m from pred 4
	
	drop _merge
	merge m:1 spv event_id using "${temp}/pred4", keepusing(d_size_w_ln d_growth_w rd_coworker_n rd_coworker_fe_m pc_wage_o_l1 pc_wage_d)
	keep if _merge != 2
	drop _merge
	
	// this analysis has to be at the event level (as pred 4)
	// so that we give the same weight to all events
	collapse (mean) wage_real_ln fe_worker exp_ln ///
			d_size_w_ln d_growth_w rd_coworker_n rd_coworker_fe_m pc_wage_o_l1 pc_wage_d, ///
			by(spv event_id pc_ym group)
	
	// testing whether this yields the same results from the previous table -- MATCHING IN BOTH CASES
	
	reg wage_real_ln d_size_w_ln d_growth_w pc_wage_o_l1    ///
			if $raidcond & group == 1, rob
			
	reg pc_wage_d d_size_w_ln d_growth_w pc_wage_o_l1    ///
			if $raidcond & group == 1, rob		
			
	// now for this new analysis...
	
		// categorical variables
		
			// ommited category: non-poached manager
		
			// pnr: poached, no raids
			gen pnr = (group == 1 & rd_coworker_n == 0)
			
			// pwr: poached, with raids
			gen pwr = (group == 1 & rd_coworker_n >= 1)
			
			
			
		// regression
		
		reg wage_real_ln pnr pwr ///
			if pc_ym >= ym(2010,1), rob
			
			// PROBLEM IS -- I HAVE TO CONTROL FOR THE ORIGIN WAGE AND I DON'T HAVE THIS FOR THE NON-POACHED MANAGERS!!!
			

/***************************************************************************************************************************	
/* ARCHIVE	

*--------------------------*
* ANALYSIS (WITH OTHER EVENTS)
*--------------------------*

// global
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

// regressions	

	use "${temp}/pred4", clear // baseline events: "spv --> spv" 
 
	// baseline events (spv-spv, mostly)
	
	eststo c3_spv: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
	// spv-emp		
			
	eststo c5_spvs: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
				
	// emp-spv
	
	eststo c5_epvs: reg pc_wage_d d_size_w_ln d_growth_w    ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
	
	// display table
	
	esttab  c3_spv c4_spv c5_spv c5_spvs c5_epvs,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel( "spv-spv"  "spv-spv" "spv-spv"  "spv-emp" "emp-spv") ///
		keep(d_size_w_ln d_growth_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	 
	// save table

	esttab c3_spv c4_spv c5_spv c5_spvs c5_epvs using "${results}/pred4.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(d_size_w_ln "\midrule \textit{Destination firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  /// 
		, labels("\cmark" ""))


*--------------------------*
* ANALYSIS (WITH ABILITY)
*--------------------------*

// global
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

// regressions	

	use "${temp}/pred4", clear // baseline events: "spv --> spv" 
 
	// baseline events (spv-spv, mostly)
	
	eststo c3_spv: reg pc_wage_d d_size_w_ln d_growth_w  rd_coworker_fe    ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv: reg pc_wage_d d_size_w_ln d_growth_w rd_coworker_fe     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv: reg pc_wage_d d_size_w_ln d_growth_w rd_coworker_fe     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
	// spv-emp		
			
	eststo c5_spvs: reg pc_wage_d d_size_w_ln d_growth_w   rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
				
	// emp-spv
	
	eststo c5_epvs: reg pc_wage_d d_size_w_ln d_growth_w   rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
	
	// display table
	
	esttab  c3_spv c4_spv c5_spv c5_spvs c5_epvs,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel( "spv-spv"  "spv-spv" "spv-spv"  "spv-emp" "emp-spv") ///
		keep(d_size_w_ln d_growth_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	 
	// save table

	/*
	
	esttab c3_spv c4_spv c5_spv c6_spv c5_spvs c6_spvs c5_epvs c6_epvs using "${results}/pred4.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(d_size_w_ln "\midrule \textit{Destination firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  /// 
		, labels("\cmark" ""))
		
	*/		

*--------------------------*
* DEC 2024 DRAFT VERSION
*--------------------------*

// global
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

// regressions	

	use "${temp}/pred4", clear // baseline events: "spv --> spv" 
 
	// baseline events (spv-spv, mostly)
	
	eststo c3_spv: reg pc_wage_d d_size_w_ln d_growth_w  rd_coworker_fe    ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv: reg pc_wage_d d_size_w_ln d_growth_w rd_coworker_fe     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv: reg pc_wage_d d_size_w_ln d_growth_w rd_coworker_fe     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
	eststo c6_spv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1  $mgr  ///
			if $raidcond & $spvcond, rob
			
	// spv-emp		
			
	eststo c5_spvs: reg pc_wage_d d_size_w_ln d_growth_w   rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
			
	eststo c6_spvs: reg pc_wage_d d_size_w_ln d_growth_w    c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1 $mgr ///
			if $raidcond & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob		
	
	// emp-spv
	
	eststo c5_epvs: reg pc_wage_d d_size_w_ln d_growth_w   rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
	
	eststo c6_epvs: reg pc_wage_d d_size_w_ln d_growth_w    c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1 $mgr ///
			if $raidcond & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
			
	// display table
	
	esttab  c3_spv c4_spv c5_spv c6_spv c5_spvs c6_spvs c5_epvs c6_epvs,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel( "spv-spv"  "spv-spv" "spv-spv"  "spv-spv"  "spv-emp" "spv-emp" "emp-spv"  "emp-spv") ///
		keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	 
	// save table

	esttab c3_spv c4_spv c5_spv c6_spv c5_spvs c6_spvs c5_epvs c6_epvs using "${results}/pred4.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(d_size_w_ln "\midrule \textit{Destination firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  /// 
		, labels("\cmark" ""))




	
