// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: June 2024

// Purpose: xxxxx

*--------------------------*
* BUILD
*--------------------------*

*foreach e in spv dir emp dir5 {
foreach e in emp  {
	
	*forvalues ym=528/683 {
	forvalues ym=612/683 {
		
	// defining locals for this analysis
	local ym_l12 = `ym' - 12
	local ym_f12 = `ym' + 12
		
	// first: listing plants and months i'm interested in
		
		use "${data}/evt_panel_m_`e'", clear
			
			keep if pc_ym == `ym'

			if _N >= 1 {
					
			keep d_plant
			duplicates drop	
			save "${temp}/d_firmlist_m", replace
		
			// second: using the complete RAIS panel, identify all workers in d_plants
		
			forvalues yymm=`ym_l12'/`ym_f12' {

				use "${data}/rais_m/rais_m`yymm'", clear
			
				// keeping only d_plants in the the months around the poaching events
				rename plant_id d_plant
				merge m:1 d_plant using "${temp}/d_firmlist_m", keep(match) nogen 
			
				save "${temp}/dest_panel_m_`ym'_`yymm'", replace
			
			} // closing the loop through months 
		
		clear
		
		forvalues yymm=`ym_l12'/`ym_f12' {
			
			cap append using "${temp}/dest_panel_m_`ym'_`yymm'"
			
		}
		
		save "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", replace
	
		} // closing the "if _N >= 1"
	} // closing the loop through cohorts	
} // closing the loop through event types
	
// adding more variables

	// worker AKM FEs
	
		*foreach e in spv dir emp dir5 {
		foreach e in emp {	
		*forvalues ym=528/683 {	
		forvalues ym=612/683 {	
			
			clear
			cap use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
			
			if _N >= 1 {
		
				merge m:1 cpf using "${AKM}/AKM_2003_2008_Worker", keep(master match) nogen
				
				save "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", replace
			
			}
		}		
		}

	// adding event_id variable
	
		*foreach e in spv dir emp dir5 {
		foreach e in emp {	
		*forvalues ym=528/683 {	
		forvalues ym=612/683 {		
			
			clear
			cap use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
			
			if _N >= 1 {
		
				gen pc_ym = `ym'
				format pc_ym %tm
				
				merge m:1 d_plant pc_ym using "${data}/evt_m_`e'", keepusing(event_id) keep(master match) nogen
				
				save "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", replace
			
			}
		}
		}
		
	// identifying raided and poached individuals	
		
	*foreach e in spv dir emp dir5 {
		foreach e in emp {	
		*forvalues ym=528/683 {	
		forvalues ym=612/683 {	
                  
                clear
                cap use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
                  
                if _N >= 1 {
                  
                        collapse (max) pc_individual raid_individual, by(cpf event_id)
                          
                        keep if pc_individual == 1 | raid_individual == 1
 
                        save "${temp}/workers_`e'_`ym'", replace
                         
                 }       
                 
                 clear
                 cap use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
                         
                if _N >= 1 {    
                          
                         merge m:1 event_id cpf using "${temp}/workers_`e'_`ym'", nogen

			 replace pc_individual = 0 if pc_individual == .
                         replace raid_individual = 0 if raid_individual == .

			 save "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", replace
                         
                }       
         }
         }
	 
	 // deflating wages
	 
	*foreach e in spv dir emp dir5 {
		foreach e in emp {	
		*forvalues ym=528/683 {	
		forvalues ym=612/683 {	
	 
		clear
		cap use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
		
		if _N >= 1 {
	 
			// adjusting wages
			merge m:1 year using "${input}/auxiliary/ipca_brazil"
			generate index_2008 = index if year == 2008
			egen index_base = max(index_2008)
			generate adj_index = index / index_base
			drop if _merge == 2
			drop _merge
				
			generate wage_real = earn_avg_month_nom / adj_index
			
				// in logs
				gen wage_real_ln = ln(wage_real)
			
			// saving
			save "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", replace
			
			
		} 	

	 }
	 }
	
	

	// STOP HERE FOR NOW
	
	/*

// third: using the coworkers panel, identify all hires by d_plants from o_plants
	
foreach e in dir spv emp dir5 {
	
	forvalues ym=528/575 {
	
	use "${data}/cowork_panel_m_`e'_`ym'", clear
	
	if _N >= 1 {
	
		// set hiring date
		g hire_ym = ym(hire_year, hire_month) 
		
		// hire = 1 if they were hired in the month and type was 'readmissao'
		g d_hire_t = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2))
		
		// we're only interested in hires INTO DESTINATION FIRM for this data set
		keep if d_hire_t == 1 & plant_id == d_plant
			
		// among these hires, who are the poached individuals directly?
		// note: this is indicated by the variable "pc"
			
		// keeping the variables we need
		keep cpf d_plant ym pc
				
		save "${temp}/d_hires_m_`e'_`ym'_fromorigin", replace
		
	} // closing the "IF" statement
	} // closing the loop over cohorts
} // closing the loop over event type

// fourth: now we put everything together 

foreach e in dir spv emp dir5 {

	use "${data}/evt_panel_m_`e'", clear
	
	keep event_id d_plant pc_ym o_plant ym

	// listing all hires
	
	merge 1:m d_plant ym using "${temp}/d_hires_m_`e'"
	keep if _merge == 3
	drop _merge
	
	sort event_id ym cpf
	
	// identifying hires from o_plant
	
	gen raid = 0
	gen poach = 0
	
	levelsof pc_ym, local(pc_ym_l)
	
	foreach ym of local pc_ym_l {
	
		merge 1:1 cpf ym d_plant using "${temp}/d_hires_m_`e'_`ym'_fromorigin"
		replace raid = 1 if _merge == 3
		replace poach = 1 if _merge == 3 & pc == 1
		drop pc _merge
	
	}
	
	sort event_id ym cpf
	
	// saving
	
	save "${data}/hires_panel_m_`e'", replace
			
}	

use "${data}/archive_20240725/hires_panel_m_spv", clear
	
		
			
	
