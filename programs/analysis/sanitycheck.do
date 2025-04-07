
			// COMPARING THE DATA SETS
			
			// number of events
				
				// old data set
				
				use "${data}/evt_m/evt_m_610", clear // 12,977 obs
				
				tab pc_dir // 266
				tab pc_dir5 // 820
				tab pc_spv // 447
				tab pc_emp // 12,264
				
				// new data set
				
				use "${data}/evt_m/new_evt_m_610", clear // 9,942 obs
				
				tab pc_dir // 265
				tab pc_dir5 // 736
				tab pc_spv // 360
				tab pc_emp // 9,317
				
				tab pc_dir if d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50 // 189
				tab pc_dir5 if d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50 // 566
				tab pc_spv if d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50 // 274
				tab pc_emp if d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50 // 6,997
				
			// check overlap of events
			
				use "${data}/evt_m/evt_m_610", clear
				keep d_plant o_plant pc_ym pc_cpf
				isid d_plant o_plant pc_ym pc_cpf
				save "${temp}/list610", replace
				
				use "${data}/evt_m/new_evt_m_610", clear
				keep if d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50
				keep d_plant o_plant pc_ym pc_cpf
				isid d_plant o_plant pc_ym pc_cpf
				save "${temp}/new_list610", replace
				
			// the new events should be a very good subset of the old events
			
				use "${temp}/new_list610", clear
				merge 1:1 d_plant o_plant pc_ym pc_cpf using "${temp}/list610"
				
				// there 7,460 in our new data set
				// of these, we can find 7,313 in the old data set: 98%
				
				
				
				
				
					
					
					
					
				
