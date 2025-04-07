// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: October 2024

// Purpose: Summary statistics

*--------------------------*
* BUILD
*--------------------------*	
	
set seed 12345	

	// creating the data sets we need (one for each event type combinations)

		// events "spv --> spv" 
		
		use "${data}/poach_ind_spv", clear
		* we need to bind to get some selections of sample, don't worry about it
		merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
		* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
		merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
		gen e_type = "spv"
		* keep only people that became spv
		keep if type_spv == 1
		
		*save "${temp}/summary_stats_spv", replace
		save "${temp}/summary_stats_spv_fd", replace // FD NOTE: TEMPORARY FIX CAUSE I COULDN'T SAVE THE PREVIOUS LINE
		
		// events "dir --> spv"
		
		use "${data}/poach_ind_dir", clear
		merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
		gen e_type = "dir"
		keep if type_spv == 1
				
			// FD NOTE: WHY DO WE NEED TO CREATE THIS HERE???	
			gen d_size_ln = ln(d_size)
			gen pc_exp_ln = ln(pc_exp)
			gen o_size_ln = ln(o_size)
			gen team_cw_ln = ln(team_cw)
		
		save "${temp}/summary_stats_dir", replace

		// events "emp --> spv"
		
		use "${data}/poach_ind_emp", clear
		merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
		gen e_type = "emp"
		keep if type_spv == 1
		
		save "${temp}/summary_stats_emp", replace

		// events "emp --> emp" (placebo)
		
		use "${data}/poach_ind_emp", clear
		merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
		gen e_type = "emp"
		keep if type_emp == 1
		
		save "${temp}/summary_stats_emp_placebo", replace

			// subsample of placebo with 5775 obs. (same number as spv --> spv and dir --> spv)
			sample 5775, count
			save "${temp}/summary_stats_emp_placebo_sample", replace

		// events "spv --> spv" + "dir --> spv"
		
		use "${temp}/summary_stats_spv", clear
		append using "${temp}/summary_stats_dir"
		save "${temp}/summary_stats_spv_dir", replace
			
*--------------------------*
* ANALYSIS
*--------------------------*			

	use "${temp}/summary_stats_spv_fd", clear // _FD CAUSE I COULDN'T SAVE THE DATA SET

	egen unique_id = group(event_id e_type)
	
	// Not all events are events we should be using 
	
	// organizing some variables we need for the table
	// note: Destination = 1, Origin = 2 
	
		// firm variables:
	
			// wage premium: productivity proxy
			rename fe_firm_o fe_firm2
			rename fe_firm_d fe_firm1
			
			// firm size (# workers)
			winsor o_size, gen(o_size_w) p(0.005) highonly
			winsor d_size, gen(d_size_w) p(0.005) highonly
			rename o_size_w size_w2
			rename d_size_w size_w1
			
			// raided workers avg wage ---> SHOULDN'T BE IN LOG!
			rename rd_coworker_wage_o rd_coworker_wage2
			rename rd_coworker_wage_d rd_coworker_wage1
					
			// avg worker wage
			* not in data set
			
			// avg manager wage
			* not in data set
			
			// avg worker AKM fe
			rename o_avg_fe_worker avg_fe_worker2
			* d_avg_fe_worker not in data set
				
			// industry
			rename cnae_d cnae2
			rename cnae_o cnae1
			
				// industry: manufacturing
				gen manu1 = (cnae1 >= 10 & cnae1 <= 33)
				gen manu2 = (cnae2 >= 10 & cnae2 <= 33)
			
				// industry: services
				gen serv1 = (cnae1 >= 55 & cnae1 <= 66) | ( cnae1 >= 69 & cnae1 <= 82) | (cnae1 >= 94 & cnae1 <= 97)
				gen serv2 = (cnae2 >= 55 & cnae2 <= 66) | ( cnae2 >= 69 & cnae2 <= 82) | (cnae2 >= 94 & cnae2 <= 97)
				
				// industry: retail
				gen ret1 = (cnae1 >= 45 & cnae1 <= 47)
				gen ret2 = (cnae2 >= 45 & cnae2 <= 47)
				
				// industry: other
				gen oth1 = (manu1 == 0 & serv1 == 0 & ret1 == 0)
				gen oth2 = (manu2 == 0 & serv2 == 0 & ret2 == 0)
				
			// employment growth
			winsor d_size, gen(d_size_w) p(0.005) highonly
			g d_size_w_ln = ln(d_size_w)
			winsor d_growth, gen(d_growth_w) p(0.05) 
			* not available for origin firm
			
			// team size
			* not clear which of the team variables is what we want here
			
	// manager variables
			
		// wage
		rename pc_wage_o_l1 pc_wage2
		rename pc_wage_d pc_wage1
			
		// age
		rename pc_age pc_age2
			
		// experience
		rename pc_exp pc_exp2
			
		// quality
		rename pc_fe pc_fe2
		
		// temporary fix: wage variables from log to levels
		*replace rd_coworker_wage2 = exp(rd_coworker_wage2)
		*replace rd_coworker_wage1 = exp(rd_coworker_wage1)
		*replace pc_wage_o = exp(pc_wage2)
		*replace pc_wage_d = exp(pc_wage1)

	// reshaping data set	
	reshape long fe_firm size_w rd_coworker_wage  manu serv ret oth pc_wage pc_age pc_exp pc_fe, i(unique_id) j(or_dest)

	// labeling variables -- we need this for the table	
	la var fe_firm "Wage premium"
	la var size_w "Firm size (\# workers)"
	la var rd_coworker_wage "Raided workers wage"
	la var manu "Industry: manufacturing"
	la var serv "Industry: services"
	la var ret "Industry: retail"
	la var oth "Industry: other"
	la var pc_wage "Wage"
	la var pc_age "Age"
	la var pc_exp "Experience"
	la var pc_fe "Quality"
	
	// summary statistics
	
	estpost su  fe_firm size_w rd_coworker_wage manu serv ret oth pc_wage pc_age pc_exp pc_fe if or_dest==2, d
	est store sumO

	estpost su  fe_firm size_w rd_coworker_wage manu serv ret oth pc_wage if or_dest==1, d
	est store sumD 
				
	// display table
	
	esttab sumO sumD, label nonotes nonum ///
		cells("mean(fmt(2) label(Mean)) p10(fmt(2) label(10th pct)) p50(fmt(2) label(Median)) p90(fmt(2) label(90th pct))")

	// export table

	esttab sumO sumD using "${results}/summary_statistics_simple_ds.tex", booktabs replace ///
		label nonotes nonum ///
		mgroups("\textbf{Origin firm}" "\textbf{Destination firm}", ///
		pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		refcat(fe_firm "\textbf{Firm variables}" pc_wage "\\ \textbf{Manager variables}" , nolabel) ///
		cells("mean(fmt(2) label(Mean)) p10(fmt(2) label(10th pct)) p50(fmt(2) label(Median)) p90(fmt(2) label(90th pct))") 




			
