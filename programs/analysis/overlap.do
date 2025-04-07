
	// goal: find overlapping events (same pc_ym, same d_firm) among spv--spv and emp--emp events

		// listing the events we have in the spv--spv dataset
		
			use "${data}/poach_ind_spv", clear
			* we need to bind to get some selections of sample, don't worry about it
			merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
			* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
			merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
			* keep only people that became spv
			keep if type_spv == 1
			
				// listing d_plant pc_ym
				
				egen unique = tag(d_plant pc_ym)
				keep if unique == 1
				
				keep d_plant pc_ym
				
				save "${temp}/list_spv", replace // keeping the list of events
				
		// listing the events we have in the emp--emp data set
		
		use "${data}/poach_ind_emp", clear
		merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
		keep if type_emp == 1
		
		
				// listing d_plant pc_ym
				
				egen unique = tag(d_plant pc_ym)
				keep if unique == 1
				
				keep d_plant pc_ym
				
				// merging with list of spv events
				
				merge 1:1 d_plant pc_ym using "${temp}/list_spv"
				keep if _merge == 3
				drop _merge
				
				save "${temp}/list_placebo", replace /// this is the list of overlapping events!
