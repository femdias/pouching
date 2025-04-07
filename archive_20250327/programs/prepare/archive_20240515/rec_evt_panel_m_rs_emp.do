// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Constructing panel around the poaching events

*--------------------------*
* BUILD
*--------------------------*

foreach e in emp {
	
	/*
	
// first: create an empty panel around the t=0 (when poaching takes place)

	use "temp/rec_evt_m_rs_`e'", clear // recreated list of event -- it was lost :(
	
	expand 25 // 12 months before, t=0, 12 months after
	sort event_id
		
	by event_id: gen ym= pc_ym - 13 + _n	
	format ym %tm
		
	gen ym_rel = ym - pc_ym
		
	// restring to 2003-2008
	keep if ym >= ym(2003,1) & ym <= ym(2008,12)
		
	save "output/data/rec_evt_panel_m_rs_`e'", replace
	
	*/
	
// second: plant-month variables for the destination plant

	// example: how many workers the d_plant is hiring each month 
	
	// listing plants and months i'm interested in
	
		use "output/data/rec_evt_panel_m_rs_`e'", clear
			
		keep d_plant ym
		egen unique = tag(d_plant ym)
		keep if unique == 1
		drop unique
			
		save "temp/d_firmlist_m", replace
	
	// using the complete RAIS panel, calcule the variables we need for the plants and months we're interested in
	
	use "output/data/rais_m_rs", clear
	
	rename plant_id d_plant
	merge m:1 d_plant ym using "temp/d_firmlist_m", keep(match)  // keeping only the plants that poached workers in a period -- d_plant

	// creating the plant-level variables

		// variable full-time contracts
		g d_emp_ft = emp if num_hours>=35
		
		// all contracts: existing variable -- just renaming it
		rename emp d_emp
		
		// employment
		g d_emp_dir = (dir == 1)
		g d_emp_dir5 = (dir5 == 1)
		g d_emp_spv = (spv == 1)
		g d_emp_emp = (dir == 0 & spv == 0)
		
			// set hiring date
			g hire_ym = ym(hire_year, hire_month) 
		
			// hire = 1 if they were hired in the quarter and type was 'readmissao'
			g d_hire_t = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2))
		
		// variables for hires
		g d_h_wages = earn_avg_month_nom if d_hire_t==1
		g d_h_tenure = tenure_months if d_hire_t==1
		g d_h_dir = 1 if d_hire_t==1 & dir==1
		g d_h_dir5 = 1 if d_hire_t==1 & dir5==1
		g d_h_spv = 1 if d_hire_t==1 & spv==1
		g d_h_emp = 1 if d_hire_t==1 & dir==0 & spv==0
	
		// variables for retained workers
		g d_r_wages = earn_avg_month_nom if d_hire_t==0
		g d_r_tenure = tenure_months if d_hire_t==0
		g d_r_dir = 1 if d_hire_t==0 & dir==1
		g d_r_dir5 = 1 if d_hire_t==0 & dir5==1
		g d_r_spv = 1 if d_hire_t==0 & spv==1
		g d_r_emp = 1 if d_hire_t==0 & dir==0 & spv==0
		
		// collapsing at the plant-month level
		
		collapse (sum) d_emp_ft d_emp d_emp_dir d_emp_dir5 d_emp_spv d_emp_emp ///
			d_hire_t d_h_dir d_h_dir5 d_h_spv d_h_emp ///
			d_r_dir d_r_dir5 d_r_spv d_r_emp ///
			(mean) d_h_wages d_h_tenure d_r_wages d_r_tenure , by(d_plant ym)
		
		order d_plant ym
		sort d_plant ym
		
		// label variables
		
		label var d_emp_ft     	"Employment (total, FT) in destination plant"
		label var d_emp	       	"Employment (total) in destination plant"
		label var d_emp_dir	"Employment (director) in destination plant"
		label var d_emp_dir5	"Employment (director + 5%) in destination plant"
		label var d_emp_spv	"Employment (supervisor) in destination plant"
		label var d_emp_emp	"Employment (employeed) in destination plant"
		label var d_hire_t	"Hired workers (total) in destination plant"	
		label var d_h_dir	"Hired workers (director) in destination plant"
		label var d_h_dir5	"Hired workers (director + 5%) in destination plant"
		label var d_h_spv 	"Hired workers (supervisor) in destination plant"
		label var d_h_emp	"Hired workers (employee) in destination plant"
		label var d_r_dir	"Retained workers (director) in destination plant"
		label var d_r_dir5	"Retained workers (director + 5%) in destination plant"
		label var d_r_spv	"Retained workers (supervisor) in destination plant"
		label var d_r_emp 	"Retained workers (employee) in destination plant" 
		label var d_h_wages	"Wages (hired workers) in destination plant"
		label var d_h_tenure    "Tenure (hired workers) in destination plant"
		label var d_r_wages     "Wages (retained workers) in destination plant"
		label var d_r_tenure	"Tenure (retained workers) in destination plant"
		
		// saving
		
		save "temp/d_firmvars_m", replace
		
// third: plant-month variables in the destination plant FROM ORIGIN PLAN
	
	use "output/data/archive_20240506/cowork_panel_m_rs_`e'", clear
	
	// creating plant-level variables
	
		// variable full-time contracts FROM ORIGIN PLANT
		g d_emp_ft_o = emp if num_hours>=35 & plant_id == d_plant
		
		// all contracts FROM ORIGIN PLANT: 
		g  d_emp_o = emp if plant_id == d_plant
	
		// employment from ORIGIN PLANT
		g d_emp_dir_o = (plant_id == d_plant & dir == 1)
		g d_emp_dir5_o = (plant_id == d_plant & dir5 == 1)
		g d_emp_spv_o = (plant_id == d_plant & spv == 1)
		g d_emp_emp_o = (plant_id == d_plant & dir == 0 & spv == 0)

			// set hiring date
			g hire_ym = ym(hire_year, hire_month) 
			
			// hire = 1 if they were hired in the quarter and type was 'readmissao' AND MOVING TO DESTINATION PLANT
			g d_hire_t_o = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2)) & plant_id == d_plant

		// variables for hires FROM ORIGIN PLANT
		g d_h_wages_o = earn_avg_month_nom if d_hire_t_o==1
		g d_h_tenure_o = tenure_months if d_hire_t_o==1
		g d_h_dir_o = 1 if d_hire_t_o==1 & dir==1
		g d_h_dir5_o = 1 if d_hire_t_o==1 & dir5==1
		g d_h_spv_o = 1 if d_hire_t_o==1 & spv==1
		g d_h_emp_o = 1 if d_hire_t_o==1 & dir==0 & spv==0
		
		// collapsing at the plant-month level
		
		collapse (sum) d_emp_ft_o d_emp_o d_emp_dir_o d_emp_dir5_o d_emp_spv_o d_emp_emp_o ///	
			d_hire_t_o d_h_dir_o d_h_dir5_o d_h_spv_o d_h_emp_o ///
			(mean) d_h_wages_o d_h_tenure_o, by(ev d_plant ym)

		order ev d_plant ym
		sort ev d_plant ym
	
		// label variables
		
		label var d_emp_ft_o     	"From orig. plant: Employment (total, FT) in destination plant"
		label var d_emp_o	       	"From orig. plant: Employment (total) in destination plant"
		label var d_emp_dir_o		"From orig. plant: Employment (director) in destination plant"
		label var d_emp_dir5_o		"From orig. plant: Employment (director + 5%) in destination plant"
		label var d_emp_spv_o		"From orig. plant: Employment (supervisor) in destination plant"
		label var d_emp_emp_o		"From orig. plant: Employment (employee) in destination plant"
		label var d_hire_t_o		"From orig. plant: Hired workers (total) in destination plant"	
		label var d_h_dir_o		"From orig. plant: Hired workers (director) in destination plant"
		label var d_h_dir5_o		"From orig. plant: Hired workers (director + 5%) in destination plant"
		label var d_h_spv_o 		"From orig. plant: Hired workers (supervisor) in destination plant"
		label var d_h_emp_o		"From orig. plant: Hired workers (employee) in destination plant"
		label var d_h_wages_o		"From orig. plant: Wages (hired workers) in destination plant"
		label var d_h_tenure_o    	"From orig. plant: Tenure (hired workers) in destination plant"
	
		save "temp/d_evtvars_m", replace
		
// fourth: similar to third, but just for the poached individuals
	
	use "output/data/archive_20240506/cowork_panel_m_rs_`e'", clear
	
	// identifying the poached individuals among the coworkers -- note that this based on the old (and wrong criteria)
	
	bysort event_id cpf: gen pc = ym_rel == 0 & (dir == 0 & spv == 0) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
	
		// test: do all events have a poached individual?
		*egen test = max(pc), by(event_id) // yes!
		
	// expanding for the entire individual and only keeping them
	
	egen pc_individual = max(pc), by(event_id cpf)
	keep if pc_individual == 1
	
	// creating plant-level variables
	
		// variable full-time contracts FROM ORIGIN PLANT
		g d_emp_ft_o_pc = emp if num_hours>=35 & plant_id == d_plant
		
		// all contracts FROM ORIGIN PLANT: 
		g  d_emp_o_pc = emp if plant_id == d_plant
	
		// employment from ORIGIN PLANT
		g d_emp_dir_o_pc = (plant_id == d_plant & dir == 1)
		g d_emp_dir5_o_pc = (plant_id == d_plant & dir5 == 1)
		g d_emp_spv_o_pc = (plant_id == d_plant & spv == 1)
		g d_emp_emp_o_pc = (plant_id == d_plant & dir == 0 & spv == 0)

			// set hiring date
			g hire_ym = ym(hire_year, hire_month) 
			
			// hire = 1 if they were hired in the quarter and type was 'readmissao' AND MOVING TO DESTINATION PLANT
			g d_hire_t_o_pc = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2)) & plant_id == d_plant

		// variables for hires FROM ORIGIN PLANT
		g d_h_wages_o_pc = earn_avg_month_nom if d_hire_t_o_pc==1
		g d_h_tenure_o_pc = tenure_months if d_hire_t_o_pc==1
		g d_h_dir_o_pc = 1 if d_hire_t_o_pc==1 & dir==1
		g d_h_dir5_o_pc = 1 if d_hire_t_o_pc==1 & dir5==1
		g d_h_spv_o_pc = 1 if d_hire_t_o_pc==1 & spv==1
		g d_h_emp_o_pc = 1 if d_hire_t_o_pc==1 & dir==0 & spv==0
		
		// collapsing at the plant-month level
		
		collapse (sum) d_emp_ft_o_pc d_emp_o_pc d_emp_dir_o_pc d_emp_dir5_o_pc d_emp_spv_o_pc d_emp_emp_o_pc ///	
			d_hire_t_o_pc d_h_dir_o_pc d_h_dir5_o_pc d_h_spv_o_pc d_h_emp_o_pc ///
			(mean) d_h_wages_o_pc d_h_tenure_o_pc, by(ev d_plant ym)

		order ev d_plant ym
		sort ev d_plant ym
	
		// label variables
		
		label var d_emp_ft_o_pc     	"Poched from orig. plant: Employment (total, FT) in destination plant"
		label var d_emp_o_pc	       	"Poched from orig. plant: Employment (total) in destination plant"
		label var d_emp_dir_o_pc	"Poched from orig. plant: Employment (director) in destination plant"
		label var d_emp_dir5_o_pc	"Poched from orig. plant: Employment (director + 5%) in destination plant"
		label var d_emp_spv_o_pc	"Poched from orig. plant: Employment (supervisor) in destination plant"
		label var d_emp_emp_o_pc	"Poched from orig. plant: Employment (employee) in destination plant"
		label var d_hire_t_o_pc		"Poched from orig. plant: Hired workers (total) in destination plant"	
		label var d_h_dir_o_pc		"Poched from orig. plant: Hired workers (director) in destination plant"
		label var d_h_dir5_o_pc		"Poched from orig. plant: Hired workers (director + 5%) in destination plant"
		label var d_h_spv_o_pc 		"Poched from orig. plant: Hired workers (supervisor) in destination plant"
		label var d_h_emp_o_pc		"Poched from orig. plant: Hired workers (employee) in destination plant"
		label var d_h_wages_o_pc	"Poched from orig. plant: Wages (hired workers) in destination plant"
		label var d_h_tenure_o_pc   	"Poched from orig. plant: Tenure (hired workers) in destination plant"
	
		save "temp/d_evtvars_m_pc", replace		
	
// fourth: merging everything with the main data set
	
	use "output/data/rec_evt_panel_m_rs_`e'", clear
		
	// merging into the main data set: firm vars
	merge m:1 d_plant ym using "temp/d_firmvars_m", nogen keep(master match) // lose 40
		
	// merging into the main data set: evt vars
	merge 1:1 ev d_plant ym using "temp/d_evtvars_m", nogen
	
	// merging into the main data set: evt vars (only with the poached individuals)
	merge 1:1 ev d_plant ym using "temp/d_evtvars_m_pc", nogen
		
	// organizing and saving
		
	tsset event_id ym_rel
	sort event_id ym_rel
	
	// saving
	save "output/data/rec_evt_panel_m_rs_`e'.dta", replace
		
}


		
