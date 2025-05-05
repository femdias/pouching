// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 6
// "The salary of a poached manager increases in the raided workers' abilities" 

*--------------------------*
* PREPARE
*--------------------------*

	use "${data}/poaching_evt", clear
	
	// we're only interested in spv-spv, spv-emp, and emp-spv
	keep if type == 1 | type == 2 | type == 3
	
	// organizing some variables for this analysis

	replace pc_fe = -99 if pc_fe==.
	replace rd_coworker_fe = -99 if rd_coworker_fe==.

	// labeling variables -- we need this for the tables
	*la var d_size_w_ln "Dest. firm size (ln)"
	la var d_growth_w "Dest. firm empl. growth rate"
	la var rd_coworker_n_ln "\# raided workers (ln)"
	la var rd_coworker_fe "Quality of raided workers"
	
	// analysis
	
		// sample selection
		drop if ratio_cw_new_hire>1 // TEMPORARY UNTIL PERMANENT FIX IN DATA CONSTRUCTION!!!
	
		// globals
		global mgr "pc_exp_ln pc_fe pc_fe_m"
		global spvcond "(type==1 | (type==2 & waged_spvemp==10) | (type==3 & waged_empspv==10))"
		global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0"
	 
		// baseline events (spv-spv, mostly)
		
		eststo c0_spv_6: reg pc_wage_d rd_coworker_fe ///
				///
				if $raidcond & $spvcond, rob
		
		eststo c3_spv_6: reg pc_wage_d d_size_ln d_growth_w  rd_coworker_fe    ///
				pc_wage_o_l1 ///
				if $raidcond & $spvcond, rob
				
		eststo c4_spv_6: reg pc_wage_d d_size_ln d_growth_w rd_coworker_fe     ///
				pc_wage_o_l1 pc_exp_ln ///
				if $raidcond & $spvcond, rob
				
		eststo c5_spv_6: reg pc_wage_d d_size_ln d_growth_w rd_coworker_fe     ///
				pc_wage_o_l1  $mgr ///
				if $raidcond & $spvcond, rob
				
		eststo c6_spv_6: reg pc_wage_d d_size_ln d_growth_w  c.rd_coworker_fe##c.rd_coworker_n_ln ///
				pc_wage_o_l1  $mgr  ///
				if $raidcond & $spvcond, rob
				
				estadd local pred "6"
				
		// spv-emp		
				
		eststo c6_spvs_6: reg pc_wage_d d_size_ln d_growth_w c.rd_coworker_fe##c.rd_coworker_n_ln ///
				pc_wage_o_l1 $mgr ///
				if $raidcond & (type==2 & waged_spvemp<10 & waged_spvemp>=1), rob
				
				estadd local pred "6"
		
		// emp-spv
		
		eststo c6_epvs_6: reg pc_wage_d d_size_ln d_growth_w c.rd_coworker_fe##c.rd_coworker_n_ln ///
				pc_wage_o_l1 $mgr ///
				if $raidcond & (type==3 & waged_empspv<10 & waged_empspv>=1) , rob
				
				estadd local pred "6"
				
		// display table
		
		esttab  c0_spv_6 c3_spv_6 c4_spv_6 c5_spv_6 c6_spv_6,  /// 
			replace compress noconstant nomtitles nogap collabels(none) label ///   
			mlabel("spv-spv" "spv-spv"  "spv-spv" "spv-spv"  "spv-spv") ///
			keep(rd_coworker_n_ln rd_coworker_fe  c.rd_coworker_fe#c.rd_coworker_n_ln ) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
			"Manager experience = pc_exp_ln" "Manager quality = pc_fe"  ///
			, labels("\cmark" ""))
		 
		// save table

		esttab c0_spv_6 c3_spv_6 c4_spv_6 c5_spv_6 c6_spv_6 using "${results}/202503_pred6.tex", booktabs  /// 
			replace compress noconstant nomtitles nogap collabels(none) label /// 
			mgroups("Outcome: Manager ln(salary) at destination",  ///
			pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
			keep(rd_coworker_n_ln rd_coworker_fe c.rd_coworker_fe#c.rd_coworker_n_ln ) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///    
			refcat(rd_coworker_fe "\midrule", nolabel) ///
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
			"Manager experience = pc_exp_ln" "Manager quality = pc_fe"  /// 
			"\\ \textbf{Destination firm} \\ Dest. firm size = d_size_ln" ///
			"Dest. firm growth = d_growth_w" ///
			, labels("\cmark" ""))	

	
/* ARCHIVE

*--------------------------*
* ANALYSIS (WITH ALL EVENT TYPES)
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
		keep(lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	 
	
	/*
	// save table

	esttab c3_spv c4_spv c5_spv c6_spv c5_spvs c6_spvs c5_epvs c6_epvs using "${results}/pred6.tex", booktabs  /// 
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
* ANALYSIS (WITHOUT CONTROLS FOR FIRM SIZE AND GROWTH)
*--------------------------*

// global
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

// regressions	

	use "${temp}/pred4", clear // baseline events: "spv --> spv" 
 
	// baseline events (spv-spv, mostly)
	
	eststo c3_spv: reg pc_wage_d rd_coworker_fe    ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv: reg pc_wage_d  rd_coworker_fe     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv: reg pc_wage_d rd_coworker_fe     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
	eststo c6_spv: reg pc_wage_d  c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1  $mgr  ///
			if $raidcond & $spvcond, rob
			
	// spv-emp		
			
	eststo c5_spvs: reg pc_wage_d  rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
			
	eststo c6_spvs: reg pc_wage_d  c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1 $mgr ///
			if $raidcond & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob		
	
	// emp-spv
	
	eststo c5_epvs: reg pc_wage_d rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
	
	eststo c6_epvs: reg pc_wage_d c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1 $mgr ///
			if $raidcond & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
			
	// display table
	
	esttab  c3_spv c4_spv c5_spv c6_spv c5_spvs c6_spvs c5_epvs c6_epvs,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel( "spv-spv"  "spv-spv" "spv-spv"  "spv-spv"  "spv-emp" "spv-emp" "emp-spv"  "emp-spv") ///
		keep(lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	 
	
	/*
	// save table

	esttab c3_spv c4_spv c5_spv c6_spv c5_spvs c6_spvs c5_epvs c6_epvs using "${results}/pred6.tex", booktabs  /// 
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
* ANALYSIS -- TESTING NUMBER OF RAIDED WORKER BY ITSELF
*--------------------------*

// global
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

// regressions	

	use "${temp}/pred6", clear // baseline events: "spv --> spv" 
 
	// baseline events (spv-spv, mostly)
	
	eststo c0_spv_6: reg pc_wage_d lnraid ///
			///
			if $raidcond & $spvcond, rob
	
	eststo c3_spv_6: reg pc_wage_d d_size_w_ln d_growth_w  lnraid    ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv_6: reg pc_wage_d d_size_w_ln d_growth_w lnraid     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv_6: reg pc_wage_d d_size_w_ln d_growth_w lnraid     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
	// display table
	
	esttab  c0_spv_6 c3_spv_6 c4_spv_6 c5_spv_6,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv"  "spv-spv" "spv-spv") ///
		keep(lnraid) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	 
	
	
	
	
	
	
	
	
	
	
	
