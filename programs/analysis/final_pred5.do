// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 5
// "The salary of a poached manager, on average, increases in the supply information, i.e., when poached by a larger firm"

*--------------------------*
* PREPARE
*--------------------------*

// events "spv --> spv"
	
	/*
	
	use "${data}/poach_ind_spv", clear

	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1
	
	save "${temp}/pred5_spv_spv", replace
		
// events "spv --> emp"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest. 
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became emp
	*keep if type_emp == 1
	keep if d_pc_emp == 1
	
	// generating identifier
	gen spv = 2
		
	save "${temp}/pred5_spv_emp", replace

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
		
	save "${temp}/pred5_emp_spv", replace

	// adding tenure overlap information
	
	use "${temp}/pred5_spv_spv", clear
	merge 1:1 event_id using "${temp}/tenureoverlap_spv", keep(master match) nogen
	save "${temp}/pred5_spv_spv", replace
	
	use "${temp}/pred5_spv_emp", clear
	merge 1:1 event_id using "${temp}/tenureoverlap_spv", keep(master match) nogen
	save "${temp}/pred5_spv_emp", replace
	
	use "${temp}/pred5_emp_spv", clear
	merge 1:1 event_id using "${temp}/tenureoverlap_emp", keep(master match) nogen
	save "${temp}/pred5_emp_spv", replace
	
	*/
	
// combining and keeping what we need

	use "${temp}/pred5_spv_spv", clear
	append using "${temp}/pred5_spv_emp" 
	append using "${temp}/pred5_emp_spv"
	
	// labeling event typs		
	la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv", replace
	la val spv spv

	// tagging top earners
	xtile waged_svpemp = pc_wage_d  if spv==2, nq(10)
	xtile waged_empspv = pc_wage_o_l1  if spv==3, nq(10) 
	
	// organizing some variables
	// note: Destination = 1, Origin = 2 
	
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)
	g o_size_w_ln = ln(o_size_w)
	
	// winsorize firm size
	winsor d_size, gen(d_size_w) p(0.005) highonly
	g d_size_w_ln = ln(d_size_w)
	winsor d_growth, gen(d_growth_w) p(0.05) 
	
	
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
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
		
	la var o_size_w_ln "Orig. firm size (ln)"
	la var team_cw_ln "Dept size (ln)"
	la var department_fe "Dept avg quality"
	la var o_avg_fe_worker "Orig. firm avg worker quality"
	la var tenure_overlap "Manager tenure overlap"
	
	// split sample by low and high tenure overlap
	
	summ full_overlap, detail
	summ tenure_overlap, detail
	summ tenure_overlap_raided, detail
	
	// saving
	save "${temp}/pred5", replace	

*--------------------------*
* ANALYSIS
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_w_ln d_growth_w fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/pred5", clear
	
	// tenure overlap
		
	la var tenure_overlap "Manager tenure overlap"
	
	// tenue overlap, ln
	
	gen tenure_overlap_ln = ln(tenure_overlap)
	la var tenure_overlap_ln "Manager tenure overlap (ln)"
	
	// tenure overlap, sum
	
	la var tenure_overlap_sum "Manager tenure overlap"
	
	// tenue overlap, sum, lm
	
	gen tenure_overlap_sum_ln = ln(tenure_overlap_sum)
	la var tenure_overlap_sum_ln "Manafer tenure overlap (ln)"
	
	// tenure overlap, raided
	
	la var tenure_overlap_raided "Manager tenure overlap"
	
	// tenure overlap, raided, ln
	
	gen tenure_overlap_raided_ln = ln(tenure_overlap_raided)
	la var tenure_overlap_raided_ln "Manager tenure overlap (ln)"
	
	// tenure overlap, raided, sum
	
	la var tenure_overlap_raided_sum "Manager tenure overlap"
	
	// tenure overlap, raided, sum, ln
	
	gen tenure_overlap_rd_sum_ln = ln(tenure_overlap_raided_sum)
	la var tenure_overlap_rd_sum_ln "Manager tenure overlap (ln)"
	
	// full overlap, share
	
	rename full_overlap tenure_overlap_full
	la var tenure_overlap_full "Manager tenure overlap"
	
	// full overlap, sum
	
	rename full_overlap_sum tenure_overlap_full_sum
	la var tenure_overlap_full_sum "Manager tenure overlap"
	
	// full overlap, sum, ln
	
	gen tenure_overlap_fll_s_ln = ln(tenure_overlap_full_sum)
	la var tenure_overlap_fll_s_ln "Manager tenure overlap (ln)"
	
	// at least 1 year of overlap
	
	la var tenure_overlap_1y "Manager tenure overlap"
	
	// baseline events (spv-spv, mostly)
	
	 eststo c0_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
	
	qui eststo c1_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
		
	qui eststo c2_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if  pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				  
	qui eststo c3_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"	
				
	qui eststo c4_spv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				
	eststo c5_spv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
			
			estadd local pred "5"
			estadd local events "All"
			
	eststo c6_spv_5: reg pc_wage_d  c.o_size_w_ln##c.tenure_overlap_ln   /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
			
			estadd local events "All"		
			
	// quartiles of tenure overlap
			
			xtile tenure_xtile_spvspv = tenure_overlap  if e(sample) == 1, nq(4)
			
	eststo c5_spv_5_belowmed: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 1 | tenure_xtile_spvspv == 2),  rob
			
			estadd local events "Low Overlap"
			
	eststo c5_spv_5_abovemed: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 3 | tenure_xtile_spvspv == 4),  rob
			
			estadd local events "High Overlap"
			
	eststo c5_spv_5_q1: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 1),  rob
			
			estadd local events "Low Overlap"
			
	eststo c5_spv_5_q4: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 4),  rob
			
			estadd local events "High Overlap"
			
	// tenure overlap (in levels) instead of firm avg worker quality		
	
	foreach var in overlap overlap_ln overlap_sum overlap_sum_ln overlap_raided overlap_raided_ln overlap_raided_sum overlap_rd_sum_ln overlap_full overlap_full_sum overlap_fll_s_ln overlap_1y {
	
	qui eststo c1_spv_5_`var': reg pc_wage_d o_size_w_ln tenure_`var'  ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
		
	qui eststo c2_spv_5_`var': reg pc_wage_d  c.o_size_w_ln##c.tenure_`var'     ///
			pc_wage_o_l1 if  pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				  
	qui eststo c3_spv_5_`var': reg pc_wage_d  c.o_size_w_ln##c.tenure_`var'   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"	
				
	qui eststo c4_spv_5_`var': reg pc_wage_d   c.o_size_w_ln##c.tenure_`var'   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				
	qui eststo c5_spv_5_`var': reg pc_wage_d   c.o_size_w_ln##c.tenure_`var'    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
			
			estadd local pred "5"
			
	}		
				
				
	// spv-emp		
	
	qui eststo c5_spvs_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
			
			estadd local pred "5"
	
	// emp-spv
	
	qui eststo c5_espv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob 
			
			estadd local pred "5"
	
	// display table
	
	/*
	    
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c6_spv_5,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv") ///
		keep(o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker tenure_overlap_ln c.o_size_w_ln#c.tenure_overlap_ln) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_w_ln" "Growth = d_growth_w"  ///
		, labels("\cmark" ""))
	
	*/
			
		
	// save table
	
	// original table
	
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 using "${results}/pred5.tex", booktabs  /// 
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
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		, labels("\cmark" ""))
		
	// v1: with below and above median tenure overlap columns
	
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c5_spv_5_belowmed  c5_spv_5_abovemed using "${results}/pred5_v1.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(events N r2, fmt(0 0 3) label(" \\ Events" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		, labels("\cmark" ""))
		
	// v2: with bottom and top quartiles of tenure overlap	
		
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c5_spv_5_q1  c5_spv_5_q4 using "${results}/pred5_v2.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(events N r2, fmt(0 0 3) label(" \\ Events" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		, labels("\cmark" ""))	
		
	// version with tenure overlap as an explanatory variable
	
	foreach var in overlap overlap_ln overlap_sum overlap_sum_ln overlap_raided overlap_raided_ln overlap_raided_sum overlap_rd_sum_ln overlap_full overlap_full_sum overlap_fll_s_ln overlap_1y {
		
	esttab c1_spv_5_`var' c2_spv_5_`var' c3_spv_5_`var' c4_spv_5_`var' c5_spv_5_`var' using "${results}/pred5_`var'.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln tenure_`var' c.o_size_w_ln#c.tenure_`var' ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(events N r2, fmt(0 0 3) label(" \\ Events" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		, labels("\cmark" ""))	
		
	}	
		
// calculating the distributions

	foreach var in overlap_full overlap_1y {

		twoway kdensity tenure_`var' ///
			if pc_ym >= ym(2010,1) & $spvcond & rd_coworker_n>=1 & rd_coworker_fe_m==0, ///
			lcolor(black) lpattern(solid) lwidth(medthick) ///
			xtitle("Tenure overlap measure") ///
			ytitle("Cumulative probability") plotregion(lcolor(white)) 

		graph export "${results}/final_pred5_dist_`var'.pdf", as(pdf) replace 	
	
	}	
	
	

	
	
	
	
	
*--------------------------*
* ANALYSIS (ADDING MORE CONTROLS, number of workers and managers pouched)
*--------------------------*
	


// regressions 

	use "${temp}/pred5", clear
	
	// log of number of managers pouched			
	gen pc_n_ln = ln(pc_n)
	
	// tenure overlap
		
	la var tenure_overlap "Manager tenure overlap"
	
	// tenue overlap, ln
	
	gen tenure_overlap_ln = ln(tenure_overlap)
	la var tenure_overlap_ln "Manager tenure overlap (ln)"
	
	// tenure overlap, sum
	
	la var tenure_overlap_sum "Manager tenure overlap"
	
	// tenue overlap, sum, lm
	
	gen tenure_overlap_sum_ln = ln(tenure_overlap_sum)
	la var tenure_overlap_sum_ln "Manafer tenure overlap (ln)"
	
	// tenure overlap, raided
	
	la var tenure_overlap_raided "Manager tenure overlap"
	
	// tenure overlap, raided, ln
	
	gen tenure_overlap_raided_ln = ln(tenure_overlap_raided)
	la var tenure_overlap_raided_ln "Manager tenure overlap (ln)"
	
	// tenure overlap, raided, sum
	
	la var tenure_overlap_raided_sum "Manager tenure overlap"
	
	// tenure overlap, raided, sum, ln
	
	gen tenure_overlap_rd_sum_ln = ln(tenure_overlap_raided_sum)
	la var tenure_overlap_rd_sum_ln "Manager tenure overlap (ln)"
	
	// full overlap, share
	
	rename full_overlap tenure_overlap_full
	la var tenure_overlap_full "Manager tenure overlap"
	
	// full overlap, sum
	
	rename full_overlap_sum tenure_overlap_full_sum
	la var tenure_overlap_full_sum "Manager tenure overlap"
	
	// full overlap, sum, ln
	
	gen tenure_overlap_fll_s_ln = ln(tenure_overlap_full_sum)
	la var tenure_overlap_fll_s_ln "Manager tenure overlap (ln)"
	
	// at least 1 year of overlap
	
	la var tenure_overlap_1y "Manager tenure overlap"
	
	// baseline events (spv-spv, mostly)
	
	 eststo c0_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
	
	qui eststo c1_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
		
	qui eststo c2_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if  pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				  
	qui eststo c3_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"	
				
	qui eststo c4_spv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				
	eststo c5_spv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
			
			estadd local pred "5"
			estadd local events "All"
			
	eststo c6_spv_5: reg pc_wage_d  c.o_size_w_ln##c.tenure_overlap_ln   /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
			
			estadd local events "All"		
			
	// quartiles of tenure overlap
			
			xtile tenure_xtile_spvspv = tenure_overlap  if e(sample) == 1, nq(4)
			
	eststo c5_spv_5_belowmed: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 1 | tenure_xtile_spvspv == 2),  rob
			
			estadd local events "Low Overlap"
			
	eststo c5_spv_5_abovemed: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 3 | tenure_xtile_spvspv == 4),  rob
			
			estadd local events "High Overlap"
			
	eststo c5_spv_5_q1: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 1),  rob
			
			estadd local events "Low Overlap"
			
	eststo c5_spv_5_q4: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0 ///
			& (tenure_xtile_spvspv == 4),  rob
			
			estadd local events "High Overlap"
			
	// tenure overlap (in levels) instead of firm avg worker quality		
	
	foreach var in overlap overlap_ln overlap_sum overlap_sum_ln overlap_raided overlap_raided_ln overlap_raided_sum overlap_rd_sum_ln overlap_full overlap_full_sum overlap_fll_s_ln overlap_1y {
	
	qui eststo c1_spv_5_`var': reg pc_wage_d o_size_w_ln tenure_`var'  ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
		
	qui eststo c2_spv_5_`var': reg pc_wage_d  c.o_size_w_ln##c.tenure_`var'     ///
			pc_wage_o_l1 rd_coworker_n_ln pc_n_ln  ///
			if  pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				  
	qui eststo c3_spv_5_`var': reg pc_wage_d  c.o_size_w_ln##c.tenure_`var'   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m rd_coworker_n_ln pc_n_ln  ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"	
				
	qui eststo c4_spv_5_`var': reg pc_wage_d   c.o_size_w_ln##c.tenure_`var'   /// 
			pc_wage_o_l1 $mgr rd_coworker_n_ln pc_n_ln if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
				
	qui eststo c5_spv_5_`var': reg pc_wage_d   c.o_size_w_ln##c.tenure_`var'    /// 
			pc_wage_o_l1 $mgr $firm_d  rd_coworker_n_ln pc_n_ln ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob
			
			estadd local pred "5"
			
	}		
				
				
	// spv-emp		
	
	qui eststo c5_spvs_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d rd_coworker_n_ln pc_n_ln ///
			if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0,  rob 
			
			estadd local pred "5"
	
	// emp-spv
	
	qui eststo c5_espv_5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d rd_coworker_n_ln pc_n_ln  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
			& rd_coworker_n>=1  & rd_coworker_fe_m==0,  rob 
			
			estadd local pred "5"
	
	// display table
	
	/*
	    
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c6_spv_5,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv") ///
		keep(o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker tenure_overlap_ln c.o_size_w_ln#c.tenure_overlap_ln) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_w_ln" "Growth = d_growth_w"  ///
		, labels("\cmark" ""))
	
	*/
			
		
	// save table
	
	// original table
	
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 using "${results}/pred5_alt.tex", booktabs  /// 
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
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		"\textbf{Event controls} \\ # raided workers (ln) = rd_coworker_n_ln" "# poached managers (ln) = pc_n_ln"  ///
		, labels("\cmark" ""))
		
	// v1: with below and above median tenure overlap columns
	
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c5_spv_5_belowmed  c5_spv_5_abovemed using "${results}/pred5_v1_alt.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(events N r2, fmt(0 0 3) label(" \\ Events" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		"\textbf{Event controls} \\ # raided workers (ln) = rd_coworker_n_ln" "# poached managers (ln) = pc_n_ln"  ///
		, labels("\cmark" ""))
		
	// v2: with bottom and top quartiles of tenure overlap	
		
	esttab c1_spv_5 c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c5_spv_5_q1  c5_spv_5_q4 using "${results}/pred5_v2_alt.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(events N r2, fmt(0 0 3) label(" \\ Events" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		"\textbf{Event controls} \\ # raided workers (ln) = rd_coworker_n_ln" "# poached managers (ln) = pc_n_ln"  ///
		, labels("\cmark" ""))	
		
	// version with tenure overlap as an explanatory variable
	
	foreach var in overlap overlap_ln overlap_sum overlap_sum_ln overlap_raided overlap_raided_ln overlap_raided_sum overlap_rd_sum_ln overlap_full overlap_full_sum overlap_fll_s_ln overlap_1y {
		
	esttab c1_spv_5_`var' c2_spv_5_`var' c3_spv_5_`var' c4_spv_5_`var' c5_spv_5_`var' using "${results}/pred5_`var'_alt.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln tenure_`var' c.o_size_w_ln#c.tenure_`var' ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(events N r2, fmt(0 0 3) label(" \\ Events" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		"\textbf{Event controls} \\ # raided workers (ln) = rd_coworker_n_ln" "# poached managers (ln) = pc_n_ln"  ///
		, labels("\cmark" ""))	
		
	}	
		
// calculating the distributions

	foreach var in overlap_full overlap_1y {

		twoway kdensity tenure_`var' ///
			if pc_ym >= ym(2010,1) & $spvcond & rd_coworker_n>=1 & rd_coworker_fe_m==0, ///
			lcolor(black) lpattern(solid) lwidth(medthick) ///
			xtitle("Tenure overlap measure") ///
			ytitle("Cumulative probability") plotregion(lcolor(white)) 

		graph export "${results}/final_pred5_dist_`var'_alt.pdf", as(pdf) replace 	
	
	}	
	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
		
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
	

