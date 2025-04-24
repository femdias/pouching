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
	
*/	

*--------------------------*
* ANALYSIS
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_w_ln d_growth_w fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

// regressions 

	use "${temp}/pred5", clear
	
	// full overlap, share
	
	rename full_overlap tenure_overlap_full
	la var tenure_overlap_full "Manager tenure overlap"
	
	gen tenure_overlap_full_m = (tenure_overlap_full == .)
	replace tenure_overlap_full = -99 if tenure_overlap_full == .
	
	
	// labeling other variables
	
	la var o_size_w_ln "Size (ln \# empl)"
	la var o_avg_fe_worker "Avg worker ability"
	
	
	// baseline events (spv-spv, mostly)
	
	*eststo c1_spv_5: reg pc_wage_d o_size_w_ln ///
			pc_wage_o_l1   ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
	*		estadd local events "All"
	
	eststo c2_spv_5: reg pc_wage_d o_size_w_ln o_avg_fe_worker  ///
			pc_wage_o_l1  ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
			
			estadd local events "All"
			
	eststo c3_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker /// 
			pc_wage_o_l1 ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"
			
	eststo c4_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker tenure_overlap_full i.tenure_overlap_full_m /// 
			pc_wage_o_l1 ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"		
				  
	eststo c5_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker tenure_overlap_full i.tenure_overlap_full_m /// 
			pc_wage_o_l1 $mgr ///
			 if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"	
				
	eststo c6_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker tenure_overlap_full  i.tenure_overlap_full_m /// 
			pc_wage_o_l1 $mgr $firm_d ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			& rd_coworker_n>=1 & rd_coworker_fe_m==0, rob
				
			estadd local events "All"	
	
	eststo c7_spv_5: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker tenure_overlap_full i.tenure_overlap_full_m /// 
			pc_wage_o_l1 $mgr $firm_d ///
			if pc_ym >= ym(2010,1) & $spvcond ///
			, rob
				
			estadd local events "All"	

	// save table
	
	esttab c2_spv_5 c3_spv_5 c4_spv_5 c5_spv_5 c6_spv_5 c7_spv_5 using "${results}/pred5_20250421.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(o_size_w_ln "\midrule \\ \textbf{Origin firm}", nolabel) ///
		mgroups("Outcome: Manager ln(salary) at destination",  ///
		pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker tenure_overlap_full) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Destination firm size (ln) = d_size_w_ln" "Destination firm growth = d_growth_w"  ///
		, labels("\cmark" ""))
		
