// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Selecting events we want

*--------------------------*
* PREPARE
*--------------------------*

set seed 6543

// events "spv --> spv"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// saving
	save "${temp}/eventlist_spv_spv", replace

// events "spv --> emp"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
		
	save "${temp}/eventlist_spv_emp", replace
	
// events "emp --> spv"
		
	use "${data}/poach_ind_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// saving	
	save "${temp}/eventlist_emp_spv", replace	

// combining events

	// start with spv-spv: info + accountability
	use "${temp}/eventlist_spv_spv", clear
	gen spv = 1
	
	// append spv-emp: info but no accountability (maybe some?)
	append using "${temp}/eventlist_spv_emp" 
	replace spv = 2 if spv == .
	
		// tag top earners
		xtile waged_svpemp = pc_wage_d  if spv==2, nq(10)  
	
	// append emp-svp (no info, some accountability)
	append using "${temp}/eventlist_emp_spv" 
	replace spv = 3 if spv == .
	
		// tag top earners
		xtile waged_empspv = pc_wage_o_l1  if spv==3, nq(10)   

	// labeling event typs		
	la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv"
	la val spv spv

	// winsorizing size variables to remove outliers
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)
	g o_size_w_ln = ln(o_size_w)
		
	// dealing with missing obs in some vairables

		// pc_exp -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
		replace pc_exp_ln = -99 if pc_exp_ln==.
		g pc_exp_m =(pc_exp_ln==-99)
			
		// pc_fe
		replace pc_fe = -99 if pc_fe==.
		g pc_fe_m = (pc_fe==-99)
			
		// fe_firm_d
		replace fe_firm_d = -99 if fe_firm_d==.
		g fe_firm_d_m = (fe_firm_d==-99)
			
	// labeling variables
		
	la var o_size_w_ln "Firm size (ln)"
	la var team_cw_ln "Dept size (ln)"
	la var department_fe "Dept avg quality"
	la var o_avg_fe_worker "Firm avg quality"
	
	// listing the events in this data set
	// we might need this to select observations in other data sets
		
	// using complete regression to determine which observations to keep
	g spvsample = .
			
	// all spv-spv, but only top decile of spvemp and empspv
	local spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10))"

	// regression	
	global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
	global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
	reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
		pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & `spvcond',  rob 
				
	// keeping sample list and saving		
	replace spvsample = e(sample) 
	keep if spvsample == 1
	keep spv event_id
	save "${temp}/eventlist", replace


	
	
	
	
	
	
	

