// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 4
// "The salary of a poached manager, on average, increases in the demand for information, i.e., when poached by a larger firm"

*--------------------------*
* PREPARE
*--------------------------

set seed 6543

// events "spv --> spv"
		
	use "${data}/poach_ind_spv", clear

	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1
	
	save "${temp}/pred4_spv_spv", replace
		
// events "spv --> emp"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest. 
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
	
	// generating identifier
	gen spv = 2
		
	save "${temp}/pred4_spv_emp", replace

// events "emp --> spv"
		
	use "${data}/poach_ind_emp", clear
	
	// positive employment in all months 
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest. 
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 3
		
	save "${temp}/pred4_emp_spv", replace
	
// combining and keeping what we need

	use "${temp}/pred4_spv_spv", clear
	append using "${temp}/pred4_spv_emp" 
	append using "${temp}/pred4_emp_spv"
	
	// labeling event typs		
	la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv", replace
	la val spv spv

	// tagging top earners
	xtile waged_svpemp = pc_wage_d  if spv==2, nq(10)
	xtile waged_empspv = pc_wage_o_l1  if spv==3, nq(10) 
	
	// organizing some variables
	// note: Destination = 1, Origin = 2 
	
	// winsorize firm size
	winsor d_size, gen(d_size_w) p(0.005) highonly
	g d_size_w_ln = ln(d_size_w)
	winsor d_growth, gen(d_growth_w) p(0.05) 
	
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
		// wage premium: productivity proxy
		rename fe_firm_o fe_firm2
		rename fe_firm_d fe_firm1
					
		replace fe_firm1 = . if fe_firm1==-99
		replace fe_firm2 = . if fe_firm2==-99

	// organize raid variables
	
		g raidw = rd_coworker_n 
		replace raidw = 0 if raidw==.
			
		winsor raidw, gen(raidw_w) p(0.05) highonly
		g lnraid_w = ln(raidw_w+1)
			
		replace rd_coworker_n=0 if rd_coworker_n==.
			
		g lnraid = ln(rd_coworker_n)
			
		g raidratio = rd_coworker_n / d_hire
			
		// drop if raidratio doesn't make sense
		drop if raidratio>1
			
		// identifying events where there is at least 1 raided worker
		g atleastraid = (rd_coworker_n>=1)
	
	// deadling with missing obs in some variables
		
		// pc_exp_ln -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
		replace pc_exp_ln = -99 if pc_exp_ln==.
		g pc_exp_m =(pc_exp_ln==-99)
			
		// pc_fe
		replace pc_fe = -99 if pc_fe==.
		g pc_fe_m = (pc_fe==-99)
			
		// rd_coworker_fe
		replace rd_coworker_fe = -99 if rd_coworker_fe==.
		g rd_coworker_fe_m = (rd_coworker_fe==-99)

	// labeling variables -- we need this for the tables
	la var d_size_w_ln "Dest. firm size (ln)"
	la var d_growth_w "Dest. firm empl. growth rate"
	la var lnraid "\# raided workers (ln)"
	la var rd_coworker_fe "Quality of raided workers" 
	
	// saving
	save "${temp}/pred4", replace

*--------------------------*
* ANALYSIS
*--------------------------*

// global
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "

// regressions	

	use "${temp}/pred4", clear // baseline events: "spv --> spv" 
 
	// baseline events (spv-spv, mostly)
	
	eststo c0_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
			if $raidcond & $spvcond, rob
	
	eststo c3_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
		estadd local pred "4"	
			
	// spv-emp		
			
	eststo c5_spvs_4: reg pc_wage_d d_size_w_ln d_growth_w     ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
		
		estadd local pred "4"
				
	// emp-spv
	
	eststo c5_epvs_4: reg pc_wage_d d_size_w_ln d_growth_w    ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
			
		estadd local pred "4"		
	
	// display table
	
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
	 
	// save table

	esttab c0_spv_4 c3_spv_4 c4_spv_4 c5_spv_4 using "${results}/pred4.tex", booktabs  /// 
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




	
