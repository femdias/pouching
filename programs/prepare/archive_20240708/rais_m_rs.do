// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Organize quarterly panel with data from RS

*--------------------------*
* BUILD
*--------------------------*

use "input/poaching_m_rs", clear

	// remove CBO and IGNORADO from the occupation string
	replace occup_cbo2002 = subinstr(occup_cbo2002,"CBO","",.)
	replace occup_cbo2002 = subinstr(occup_cbo2002,"IGNORADO","",.)
	replace occup_cbo2002 = trim(occup_cbo2002)

	// remove CLASSE from the industry strings and then destring
	replace cnae20_class = subinstr(cnae20_class,"CLASSE","",.)
	destring cnae20_class, replace
	destring cnae20_subclass, replace

	// occupational code: 1st digit
	gen occ_1d = substr(occup_cbo2002, 1, 1)
	destring occ_1d, replace 
		
	// occupational code: 3rd digit
	gen occ_3d = substr(occup_cbo2002, 3, 1)
	destring occ_3d, replace
		
	// variable: occup_group
		
		// DIRECTORS
				
		// A. identify directors via occupation codes
		gen dir_temp = (occ_1d == 1)
		
			// within a year, director if director in all employed months
			
			egen n_emp_plant_year = count(plant_id), by(cpf year plant_id)
			egen n_dir_plant_year = sum(dir_temp), by(cpf year plant_id)
			
			gen dir = (dir_temp == 1 & (n_emp_plant_year == n_dir_plant_year))
						
		// B. identify directors via occupation codes OR via income criteria
		
		egen p95 = pctile(earn_avg_month_nom), p(95) by(plant_id ym)
		gen dirinc_temp = (earn_avg_month_nom >= p95 & earn_avg_month_nom < .)
		
			// within a year, director (income) if director (income) in all employed months
			
			egen n_dirinc_plant_year = sum(dirinc_temp), by(cpf year plant_id)
			
			gen dirinc = (dirinc_temp == 1 & (n_emp_plant_year == n_dirinc_plant_year))
			
		gen dir5 = (dir == 1 | dirinc == 1)
					
		// C. identify supervisors via occupation codes
		gen spv_temp = (occ_3d == 0)
				
		// within a year, supervisor if supervisor in all employed months
			
			egen n_spv_plant_year = sum(spv_temp), by(cpf year plant_id)
			
			gen spv = (spv_temp == 1 & (n_emp_plant_year == n_spv_plant_year))
			replace spv = 0 if dir == 1 // exclusion criteria
	
	// identify government firms
	
	tostring legal_nature, gen(legal_str)	
	gen gov = 0
	replace gov=1 if substr(legal_str, 1, 1) != "2" & legal_str!="."
	replace gov=1 if legal_str == "2011" | legal_str == "2038"
	drop legal_str

	// making the data set lighter, if possible
	
	compress 

	destring cpf plant_id, replace // automatically destringed as double

	format plant_id %14.0f
	format cpf %14.0f

	drop cnpj_root
	
	// number of employees in each firm
	gen emp = 1 if plant_id != .
	egen n_emp = sum(emp), by(plant_id ym)
	replace n_emp = . if n_emp == 0
	
	// saving
	tsset cpf ym
	save "output/data/rais_m_rs", replace
	
	
	
	
	
	
	
	
	
	
	
