// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: June 2024

// Purpose: Constructing panel with all hires around the poaching events

*--------------------------*
* BUILD
*--------------------------*

foreach e in dir dir5 spv emp {
	
// first: listing plants and months i'm interested in
	
		use "${data}/evt_panel_m_`e'", clear
			
		keep d_plant ym
		egen unique = tag(d_plant ym)
		keep if unique == 1
		drop unique
			
		save "${temp}/d_firmlist_m", replace
	
// second: using the complete RAIS panel, identify all hires by d_plants
	
	// looping through the months of interest
	forvalues ym=516/587 {

		use "${data}/rais_m/rais_m`ym'", clear
	
		// keeping only d_plants in the the months around the poaching events
		rename plant_id d_plant
		merge m:1 d_plant ym using "${temp}/d_firmlist_m", keep(match) nogen 

	if _N >= 1 {
		
		// identifying hires by the d_plants
		
			// set hiring date
			g hire_ym = ym(hire_year, hire_month) 
		
			// hire = 1 if they were hired in the month and type was 'readmissao'
			g d_hire_t = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2))
		
			// we're only interested in hires for this data set
			keep if d_hire_t == 1

		// saving
		
		save "${temp}/d_hires_m_`ym'", replace
	
	} // closing the "if _N >= 1"
	} // closing the loop through months 
	
	clear
	
	forvalues ym=516/587 {
			
		cap append using "${temp}/d_hires_m_`ym'"	
			
	} 
	
	sort d_plant ym
	
	save "${temp}/d_hires_m_`e'", replace
					
}

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


	
		
			
	
