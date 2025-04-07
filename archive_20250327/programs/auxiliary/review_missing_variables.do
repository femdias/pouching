// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: November 2024

// Purpose: Review reasons for missing variables that are being used in Tables 2 and 3

*--------------------------*
* PREPARE
*--------------------------*

use "${data}/poach_ind_spv", clear 
// append using "${data}/poach_ind_dir"
// append using "${data}/poach_ind_emp"

/*
// pc_wage_d 
misstable summ pc_wage_d

// pc_wage_o_l1
misstable summ pc_wage_o_l1

// o_size
	// o_size
	misstable summ o_size
	
	// o_size_w
	winsor o_size, gen(o_size_w) p(0.005) highonly
	misstable summ o_size_w
	
	// o_size_w_ln
	g o_size_w_ln = ln(o_size_w)
	misstable summ o_size_w_ln
	
// d_size
	// d_size
	misstable summ d_size
	
	// d_size_w
	winsor d_size, gen(d_size_w) p(0.005) highonly
	misstable summ d_size_w
	
	// d_size_w_ln
	g d_size_w_ln = ln(d_size_w)
	misstable summ d_size_w_ln

// cnae_d 
misstable summ cnae_d

// cnae_o
misstable summ cnae_o
		
// pc_age 
misstable summ pc_age
			
// d_hire
misstable summ d_hire


// o_avg_fe_worker 
misstable summ o_avg_fe_worker
keep if o_avg_fe_worker == .



// pc_exp_ln
	// pc_exp
	misstable summ pc_exp
	
	// pc_exp_ln
	misstable summ pc_exp_ln
	/*
	keep if pc_exp_ln ==.
	keep event_id pc_age pc_educ_years
	gen dif = pc_age - pc_educ_years
	sort dif
	*/
	
// fe_firm_d
misstable summ fe_firm_d
keep if fe_firm_d == .
sort pc_ym


// fe_firm_o
misstable summ fe_firm_o

// pc_fe
misstable summ pc_fe

// rd_coworker_fe
misstable summ rd_coworker_fe


// d_growth
// d_growth
*/
misstable summ d_growth
keep if d_growth == .
	
use "${data}/evt_panel_m_spv", clear
append using "${data}/evt_panel_m_dir"
append using "${data}/evt_panel_m_emp"

gen d_emp_l12_temp = d_emp if ym_rel == -12
egen d_emp_l12 = max(d_emp_l12_temp), by(event_id)
drop d_emp_l12_temp
			
gen d_emp_l1_temp = d_emp if ym_rel == -1
egen d_emp_l1 = max(d_emp_l1_temp), by(event_id)
drop d_emp_l1_temp

keep if (d_emp_l12 == . | d_emp_l1 == .) & ym >= ym(2010,2)
distinct event_id
	
/*
// d_growth_w
winsor d_growth, gen(d_growth_w) p(0.05) 
misstable summ d_growth_w
			
// rd_coworker_wage_o 
misstable summ rd_coworker_wage_o

// rd_coworker_wage_d 
misstable summ rd_coworker_wage_d




// rd_coworker_n (raidw)
	// rd_coworker_n (raidw)
	g raidw = rd_coworker_n 
	misstable summ raidw
	// replace raidw = 0 if raidw==.
	
	// raidw_w
	winsor raidw, gen(raidw_w) p(0.05) highonly
	misstable summ raidw_w

	// lnraid_w
	g lnraid_w = ln(raidw_w+1)
	misstable summ lnraid_w
		
	g lnraid = ln(rd_coworker_n)
	misstable summ lnraid



*/











