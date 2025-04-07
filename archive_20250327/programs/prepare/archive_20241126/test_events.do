
	// verificar events (usando EMP)
	
	use "output/data/evt_panel_m_emp", clear
	
	// I need one event where a coworker is hired before the poaching event
	
		// some important variables

			// keeping events with complete panel
			bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
			keep if n_emp_pos >= 25 & n_emp_pos < .
		
			// total number of hires in destination plant
			gen d_h = d_h_dir + d_h_spv + d_h_emp
			
			// number of hirings from origin plant (only poached individuals)
			gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
			
			// number of hirings from origin plant (excluding poached individuals)
			gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc
			
		// identifying hires before the poaching event
		
		gen h_beforepoach = (d_h_o_sanspc > 0 & d_h_o_sanspc != . & ym_rel < 0)
		
		// identifying events where this is happening
		
		egen h_beforepoach_event = max(h_beforepoach), by(event_id)
		
		// randomly selection 1 of these events
		
		keep if h_beforepoach_event == 1
		
		keep if event_id == 23062 // my choice, cohort = 2006m5 (556)
		
	// now, let's check the dataset of coworkers
	
	use "output/data/cowork_panel_m_emp_556", clear
	keep if event_id == 23062
	
	// identify all cases when a worker is raided
	
	tsset cpf ym_rel
	gen raid = (plant_id == d_plant & L.plant_id != d_plant) // one of them is the poached individual itself
	replace raid = 0 if pc == 1
	
	// only keeping the raided individuals
	egen raid_ind = max(raid), by(cpf)
	keep if raid_ind == 1
	
		// individual who could have been poached in 2006m2 (553)
		keep if cpf == 5139306476
		
		// 1. worker is employed in an establishment with at least 45 employees in t-1
		gen criteria1 = (L.n_emp >= 45 & L.n_emp < .) & ym == 553
		
		// 2. worker is employed in the same establishment in t-12 and t-1
		gen criteria2 = ((L.plant_id == L12.plant_id) & (L.plant_id != .) & (L12.plant_id != .))   & ym == 553 
		
		// 3. worker is employed in a different establishment in t
		gen criteria3 = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .)) & ym == 553 
		
		// 4. worker is employed in a different firm in t
		gen criteria4 = ((firm_id != L.firm_id) & (firm_id != .) & (L.firm_id != .)) & ym == 553
		
		// 5. worker is employed in a establishment with at least 45 employees in t
		gen criteria5 = (n_emp >= 45 & n_emp < .)   & ym == 553
		
		// 6. worker must be separated from the old establishment in t
		
			gen sep = (cause_of_sep == 10 | cause_of_sep == 11 | cause_of_sep == 12 | ///
				cause_of_sep == 20 | cause_of_sep == 21) 

			gen sep_ym = ym(year, sep_month)					
			
		gen criteria6 = ((ym == L.sep_ym) & (L.sep_ym != .) & (L.sep == 1))  & ym == 553

		// 7. worker must be hired by the new establishment in t

			gen hire = (type_of_hire == 2)
			
			gen hire_ym = ym(hire_year, hire_month)
			
		gen criteria7 = ((ym == hire_ym) & (hire_ym != .) & (hire == 1))  & ym == 553
		
		// 8. worker is employed in non-gov establishment in t-1 and t
		gen criteria8 = ((L.gov == 0 & gov == 0) & (L.plant_id != .) & (plant_id != .))   & ym == 553 
			// no gov variable in this data set... i'm assuming this is not an issue
		
		// 9. worker is still employed in the new establishment in t+12
		gen criteria9 = ((plant_id == F12.plant_id) & (plant_id != .) & (F12.plant_id != .))   & ym == 553
		
		
	// IT FAILS CRITERIA 2, BUT IT SEEMS TO BE SOMETHING WEIRD ABOUT TRANSFER BETWEEN THE SAME CNPJ
	// LET'S CHECK THIS PERSON IN 2004... 2004m12 should work (539)
	
	// we have to briefly change the working directory
	cd "/home/ecco_rais/data/interwrk/daniela_group/displacement"
	
	use "output/data/RAIS_Monthly/PrimaryContracts_m539", clear
	
	keep if cpf == 5139306476
	
	
		
