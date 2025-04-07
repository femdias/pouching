
use "${data}/poach_ind_spv", clear
				
merge m:1 event_id using "${temp}/rd_coworker_wage_lvl_spv", keep(master match) nogen
merge m:1 event_id using "${temp}/pc_wage_lvl_spv", keep(master match) nogen
merge m:1 event_id using "${temp}/d_avg_fe_worker_spv", keep(master match) nogen
		
keep event_id rd_coworker_wage_d_lvl rd_coworker_wage_o_lvl rd_coworker_wage_d rd_coworker_wage_o pc_wage_o_l1_lvl pc_wage_o_l12_lvl pc_wage_o_l1 pc_wage_o_l12 pc_wage_d_lvl d_avg_fe_worker

gen rd_coworker_wage_d_ln = ln(rd_coworker_wage_d_lvl)
gen rd_coworker_wage_o_ln = ln(rd_coworker_wage_o_lvl)
gen rd_coworker_wage_d_exp = exp(rd_coworker_wage_d)
gen rd_coworker_wage_o_exp = exp(rd_coworker_wage_o)

gen pc_wage_o_l1_ln = ln(pc_wage_o_l1_lvl)
gen pc_wage_o_l12_ln = ln(pc_wage_o_l12_lvl)
gen pc_wage_o_l1_exp = exp(pc_wage_o_l1)
gen pc_wage_o_l12_exp = exp(pc_wage_o_l12)

gen pc_wage_d_lvl_ln = ln(pc_wage_d_lvl)
gen pc_wage_d_exp = exp(pc_wage_d_lvl)
		
		
			

