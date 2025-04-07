// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction "delta"
// "Absolute delta salary of a manager on the sum of the absolute delta wages of workers that were raided" 

*--------------------------*
* PREPARE
*--------------------------*

set seed 6543

// events "spv --> spv"
		
	use "${data}/poach_ind_spv_NEW", clear

	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1
	
	save "${temp}/preddelta_spv_spv", replace
		
// events "spv --> emp"
		
	use "${data}/poach_ind_spv_NEW", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest. 
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
	
	// generating identifier
	gen spv = 2
		
	save "${temp}/preddelta_spv_emp", replace

// events "emp --> spv"
		
	use "${data}/poach_ind_emp_NEW", clear
	
	// positive employment in all months 
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest. 
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 3
		
	save "${temp}/preddelta_emp_spv", replace
	
// combining and keeping what we need

	use "${temp}/preddelta_spv_spv", clear
	append using "${temp}/preddelta_spv_emp" 
	append using "${temp}/preddelta_emp_spv"
	
	// labeling event typs		
	la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv", replace
	la val spv spv

	// tagging top earners
	xtile waged_svpemp = pc_wage_d  if spv==2, nq(10)
	xtile waged_empspv = pc_wage_o_l1  if spv==3, nq(10) 
	
	// organizing some variables
	// note: Destination = 1, Origin = 2 
	
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
		
	// organizing main outcome variable
	g delta_pc_lvl = pc_wage_d_lvl - pc_wage_o_l1_lvl
	g delta_pc = pc_wage_d - pc_wage_o_l1
	
	// winsorizing main outcome and independent variables
	
		winsor delta_pc_lvl, gen(delta_pc_lvl_w) p(0.005)
		winsor delta_pc, gen(delta_pc_w) p(0.005)
		
		winsor delta_rd_sum_lvl, gen(delta_rd_sum_lvl_w) p(0.005)
		winsor delta_rd_sum, gen(delta_rd_sum_w) p(0.005)
		
		winsor delta_rd_avg_lvl, gen(delta_rd_avg_lvl_w) p(0.005)
		winsor delta_rd_avg, gen(delta_rd_avg_w) p(0.005)
		
	// winsorizing size variables
	
		// origin firm
		winsor o_size, gen(o_size_w) p(0.005) highonly
		winsor o_size_ratio, g(o_size_ratio_w) p(0.005)
		g o_size_w_ln = ln(o_size_w)
		
		// destination firm
		winsor d_size, gen(d_size_w) p(0.005) highonly
		g d_size_w_ln = ln(d_size_w)
		
	// winsorizing destination growth	
	winsor d_growth, gen(d_growth_w) p(0.05) 
	
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
		
		// fe_firm_d
		replace fe_firm_d = -99 if fe_firm_d==.
		g fe_firm_d_m = (fe_firm_d==-99)
		
	// labeling variables for table
	label var delta_rd_sum_lvl "Delta raided worker wages"
	label var delta_rd_sum "Delta raided worker wages"
			
	// saving
	save "${temp}/preddelta", replace

*--------------------------*
* ANALYSIS (LEVELS)
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global firm_o "o_size_ln o_avg_fe_worker"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/preddelta", clear
	
	// baseline events (spv-spv, mostly)
	
	eststo c1_spv: reg delta_pc_lvl_w delta_rd_sum_lvl_w  ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			summ delta_pc_lvl_w if e(sample) == 1, detail
			g delta_neg = (delta_pc_lvl_w <= 0)
			tab delta_neg if e(sample) == 1

	eststo c2_spv: reg delta_pc_lvl_w delta_rd_sum_lvl_w  ///
			$mgr ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c3_spv: reg delta_pc_lvl_w delta_rd_sum_lvl_w  ///
			$mgr $firm_d ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c4_spv: reg delta_pc_lvl_w delta_rd_sum_lvl_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob		
					  
		
	// spv-emp		
	
	eststo c4_spvs: reg delta_pc_lvl_w delta_rd_sum_lvl_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
	
	// emp-spv
	
	eststo c4_espv: reg delta_pc_lvl_w delta_rd_sum_lvl_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0 ,  rob 
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c4_spvs c4_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(delta_rd_sum_lvl_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		"\\ \textbf{Origin firm}  \\ Size = o_size_ln" "Firm avg quality = o_avg_fe_worker"  ///
		, labels("\cmark" ""))
	
	// save table
	/*
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
	*/

*--------------------------*
* ANALYSIS (LOG)
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global firm_o "o_size_ln o_avg_fe_worker"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/preddelta", clear
	
	// baseline events (spv-spv, mostly)
	
	eststo c1_spv: reg delta_pc_w delta_rd_sum_w ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c2_spv: reg delta_pc_w delta_rd_sum_w  ///
			$mgr ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c3_spv: reg delta_pc_w delta_rd_sum_w  ///
			$mgr $firm_d ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c4_spv: reg delta_pc_w delta_rd_sum_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob		
					  
		
	// spv-emp		
	
	eststo c4_spvs: reg delta_pc_w delta_rd_sum_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
	
	// emp-spv
	
	eststo c4_espv: reg delta_pc_w delta_rd_sum_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0 ,  rob 
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c4_spvs c4_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(delta_rd_sum_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		"\\ \textbf{Origin firm}  \\ Size = o_size_ln" "Firm avg quality = o_avg_fe_worker"  ///
		, labels("\cmark" ""))
	
	// save table
	/*
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
	*/
	
*--------------------------*
* ANALYSIS (LEVELS --- AVERAGE)
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global firm_o "o_size_ln o_avg_fe_worker"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/preddelta", clear
	
	// baseline events (spv-spv, mostly)
	
	eststo c1_spv: reg delta_pc_lvl_w delta_rd_avg_lvl_w  ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c2_spv: reg delta_pc_lvl_w delta_rd_avg_lvl_w  ///
			$mgr ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c3_spv: reg delta_pc_lvl_w delta_rd_avg_lvl_w  ///
			$mgr $firm_d ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c4_spv: reg delta_pc_lvl_w delta_rd_avg_lvl_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob		
					  
		
	// spv-emp		
	
	eststo c4_spvs: reg delta_pc_lvl_w delta_rd_avg_lvl_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
	
	// emp-spv
	
	eststo c4_espv: reg delta_pc_lvl_w delta_rd_avg_lvl_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0 ,  rob 
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c4_spvs c4_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(delta_rd_avg_lvl_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		"\\ \textbf{Origin firm}  \\ Size = o_size_ln" "Firm avg quality = o_avg_fe_worker"  ///
		, labels("\cmark" ""))
	
	// save table
	/*
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
	*/

*--------------------------*
* ANALYSIS (LOG)
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global firm_o "o_size_ln o_avg_fe_worker"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/preddelta", clear
	
	// baseline events (spv-spv, mostly)
	
	eststo c1_spv: reg delta_pc_w delta_rd_avg_w ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c2_spv: reg delta_pc_w delta_rd_avg_w  ///
			$mgr ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c3_spv: reg delta_pc_w delta_rd_avg_w  ///
			$mgr $firm_d ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	eststo c4_spv: reg delta_pc_w delta_rd_avg_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob		
					  
		
	// spv-emp		
	
	eststo c4_spvs: reg delta_pc_w delta_rd_avg_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
	
	// emp-spv
	
	eststo c4_espv: reg delta_pc_w delta_rd_avg_w  ///
			$mgr $firm_d $firm_o ///
			if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0 ,  rob 
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c4_spvs c4_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(delta_rd_avg_w) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		"\\ \textbf{Origin firm}  \\ Size = o_size_ln" "Firm avg quality = o_avg_fe_worker"  ///
		, labels("\cmark" ""))
	
	// save table
	/*
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
	*/
	
