// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: March 2025

// Purpose: Create main event-level data set

*--------------------------*
* BUILD
*--------------------------*
	
	use "${data}/202503_poach_ind", clear
		
	// event type variable
	
	gen type = .
	replace type = 1 if o_pc_spv == 1 & d_pc_spv == 1
	replace type = 2 if o_pc_spv == 1 & d_pc_emp == 1
	replace type = 3 if o_pc_emp == 1 & d_pc_spv == 1
	
	la def type 1 "spv-spv" 2 "spv-emp" 3 "emp-spv", replace
	la val type type
	
		// tagging top earners in spv-emp and emp-spv
		xtile waged_spvemp = pc_wage_d    if type==2, nq(10)
		xtile waged_empspv = pc_wage_o_l1 if type==3, nq(10)
		
		// winsorize and log destination firm size
		*winsor d_size, gen(d_size_w) p(0.005) highonly
		*gen d_size_w_ln = ln(d_size_w)
		
		// winsorize and log origin firm size
		winsor o_size, gen(o_size_w) p(0.005) highonly
		g o_size_w_ln = ln(o_size_w)
		
		// winsorize destination firm growth
		winsor d_growth, gen(d_growth_w) p(0.05) 
		
		// number of raided workers
		replace rd_coworker_n=0 if rd_coworker_n==.
			
		// ratio of raided coworkers over total hires
		drop ratio_cw_new_hire
		gen ratio_cw_new_hire = rd_coworker_n / d_hire
			
		// dummy for missing variables
		
			// destination firm FE
			gen fe_firm_d_m = (fe_firm_d==.)
			
			// poached worker FE
			gen pc_fe_m = (pc_fe==.)
			
			// raided worker FE
			gen rd_coworker_fe_m = (rd_coworker_fe==.)
		
	// saving this data set
	save "${data}/poaching_evt", replace
	
	
		
