// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 5
// "The salary of a poached manager, on average, increases in the supply information, i.e., when poached by a larger firm"

*--------------------------*
* PREPARE
*--------------------------*

	use "${data}/poaching_evt", clear
	
	// we're only interested in spv-spv, spv-emp, and emp-spv
	keep if type == 1 | type == 2 | type == 3
	
	// organizing some variables for this analysis

	replace pc_fe = -99 if pc_fe==.
	replace rd_coworker_fe = -99 if rd_coworker_fe==.
		
	*la var o_size_w_ln "Orig. firm size (ln)"
	la var o_avg_fe_worker "Orig. firm avg worker quality"
	
	// analysis
	
		// sample selection
		drop if ratio_cw_new_hire>1 // TEMPORARY UNTIL PERMANENT FIX IN DATA CONSTRUCTION!!!

		// globals
		global mgr "pc_exp_ln pc_fe pc_fe_m"
		global firm_d "d_size_ln d_growth_w fe_firm_d_m"
		global spvcond "(type==1 | (type==2 & waged_spvemp==10) | (type==3 & waged_empspv==10)) "
		global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

		// baseline events (spv-spv, mostly)
		
		qui eststo c0_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker ///
				if $spvcond ///
				& $raidcond, rob
		
		qui eststo c1_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker ///
				pc_wage_o_l1 ///
				if $spvcond ///
				& $raidcond, rob
			
		qui eststo c2_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker ///
				pc_wage_o_l1 ///
				if $spvcond ///
				& $raidcond, rob
					  
		qui eststo c3_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker /// 
				pc_wage_o_l1 pc_exp_ln ///
				if $spvcond ///
				& $raidcond, rob
					
		qui eststo c4_spv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker /// 
				pc_wage_o_l1 $mgr ///
				if $spvcond ///
				& $raidcond, rob
					
		qui eststo c5_spv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker /// 
				pc_wage_o_l1 $mgr $firm_d  ///
				if $spvcond ///
				& $raidcond, rob
				
				estadd local pred "5"
					
		// spv-emp		
		
		qui eststo c5_spvs_5: reg pc_wage_d c.o_size_w_ln##c.o_avg_fe_worker    /// 
				pc_wage_o_l1 $mgr $firm_d ///
				if (type==2 & waged_spvemp<10 & waged_spvemp>=1) ///
				& $raidcond, rob
				
				estadd local pred "5"
		
		// emp-spv
		
		qui eststo c5_espv_5: reg pc_wage_d c.o_size_w_ln##c.o_avg_fe_worker    /// 
				pc_wage_o_l1 $mgr $firm_d ///
				if (type==3 & waged_empspv<10 & waged_empspv>=1) ///
				& $raidcond, rob 
				
				estadd local pred "5"
		
		// display table
		    
		esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5,  /// 
			replace compress noconstant nomtitles nogap collabels(none) label ///   
			mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv") ///
			keep(o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker ) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
			"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
			"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Growth = d_growth_w"  ///
			, labels("\cmark" ""))
		
		// save table
		
		esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 using "${results}/202503_pred5.tex", booktabs  /// 
			replace compress noconstant nomtitles nogap collabels(none) label /// 
			refcat(o_size_w_ln "\midrule", nolabel) ///
			mgroups("Outcome: Manager ln(salary) at destination",  ///
			pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
			keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
			cells(b(star fmt(3)) se(par fmt(3))) ///    
			stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
			obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
			indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
			"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
			"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_ln" "Destination firm growth = d_growth_w"  ///
			, labels("\cmark" ""))	
		

		
		
		
		
/* ARCHIVE

*--------------------------*
* ANALYSIS (WITH OTHER EVENTS)
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/pred5", clear
	
	// baseline events (spv-spv, mostly)
	
	qui eststo c1_spv: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
		
	qui eststo c2_spv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if  pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				  
	qui eststo c3_spv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
	qui eststo c4_spv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0, rob
				
	eststo c5_spv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
				
	// spv-emp		
	
	qui eststo c5_spvs: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
	
	// emp-spv
	
	qui eststo c5_espv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob 
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	
	// save table
	
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv using "${results}/pred5.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))	
		
*--------------------------*
* ANALYSIS - SIZE ONLY
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/pred5", clear
	
	// baseline events (spv-spv, mostly)
	
	qui eststo c1_spv: reg pc_wage_d o_size_w_ln    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond, rob
					  
	qui eststo c3_spv: reg pc_wage_d  o_size_w_ln   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond, rob
				
	qui eststo c4_spv: reg pc_wage_d   o_size_w_ln   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond, rob
				
	eststo c5_spv: reg pc_wage_d   o_size_w_ln    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond,  rob
				
	// spv-emp		
	
	qui eststo c5_spvs: reg pc_wage_d  o_size_w_ln    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1),  rob 
	
	// emp-spv
	
	qui eststo c5_espv: reg pc_wage_d   o_size_w_ln    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ,  rob 
	
	// display table
	    
	esttab c1_spv c3_spv c4_spv c5_spv c5_spvs c5_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(o_size_w_ln) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	
	// save table
	
	esttab c1_spv c3_spv c4_spv c5_spv c5_spvs c5_espv using "${results}/pred5.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	
*--------------------------*
* ANALYSIS - SIZE AND ABILITY
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/pred5", clear
	
	// baseline events (spv-spv, mostly)
	
	qui eststo c1_spv: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond, rob
			  
	qui eststo c3_spv: reg pc_wage_d  o_size_w_ln o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond, rob
				
	qui eststo c4_spv: reg pc_wage_d o_size_w_ln   o_avg_fe_worker   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond, rob
				
	eststo c5_spv: reg pc_wage_d   o_size_w_ln o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond,  rob
				
	// spv-emp		
	
	qui eststo c5_spvs: reg pc_wage_d  o_size_w_ln o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1),  rob 
	
	// emp-spv
	
	qui eststo c5_espv: reg pc_wage_d  o_size_w_ln o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ,  rob 
	
	// display table
	    
	esttab c1_spv c3_spv c4_spv c5_spv c5_spvs c5_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(o_size_w_ln o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	
	// save table
	/*
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv using "${results}/pred5.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	*/	
	
*--------------------------*
* ANALYSIS - SIZE, ABILITY, AND INTERACTION
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/pred5", clear
	
	// baseline events (spv-spv, mostly)
	
	qui eststo c1_spv: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond , rob
		
	qui eststo c2_spv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if  pc_ym >= ym(2010,1) & $spvcond, rob
				  
	qui eststo c3_spv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond, rob
				
	qui eststo c4_spv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond, rob
				
	eststo c5_spv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond,  rob
				
	// spv-emp		
	
	qui eststo c5_spvs: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1),  rob 
	
	// emp-spv
	
	qui eststo c5_espv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ,  rob 
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	
	// save table
	
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv using "${results}/pred5.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))
	

