// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Organize quarterly panel with data from RS

*--------------------------*
* BUILD
*--------------------------*

use "input/Poaching_RS", clear

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
		
		// MANAGERS
				
		// A. identify managers via occupation codes
		gen mgr_occ = (occ_1d == 1 | occ_3d == 0)
					
		// identify firms with no managers, at the firm-level
		gen firm_id = substr(plant_id, 1, 8)
		egen has_mgr_occ = max(mgr_occ), by(firm_id)
						
		// B. identify managers as the top 5% earners
		egen p95 = pctile(earn_avg_month_nom), p(95) by(firm_id)
		gen mgr_top5 = (earn_avg_month_nom >= p95 & earn_avg_month_nom < .)
					
		// combine A. and B.
		gen mgr = .
		replace mgr = mgr_occ if has_mgr_occ == 1
		replace mgr = mgr_top5 if has_mgr_occ == 0 // we only use B. if A. is not satisfied
				
		// TECHNICAL WORKERS
		gen tcn = (mgr == 0 & (occ_1d == 2 | occ_3d == 3))
				
		// OTHER / SHOP FLOOR WORKERS
		gen other = (mgr == 0 & tcn == 0)
				
		// combining into a single occup variable
		gen occ_gr = .
		replace occ_gr = 1 if mgr == 1
		replace occ_gr = 2 if tcn == 1
		replace occ_gr = 3 if other == 1
				
		label var occ_gr "Occupational group"
		label define occ_gr 1 "Manager" 2 "Technical" 3 "Shop floor", replace
		label values occ_gr occ_gr

	// variable: occup_group_o (no income criteria)
		
		gen occ_gr_o = .
		replace occ_gr_o = 1 if mgr_occ == 1
		replace occ_gr_o = 2 if (mgr_occ == 0 & (occ_1d == 2 | occ_3d == 3))
		replace occ_gr_o = 3 if occ_gr_o == .
			
		label var occ_gr_o "Occupational group (w/o income criteria)"
		label define occ_gr_o 1 "Manager" 2 "Technical" 3 "Shop floor", replace
		label values occ_gr_o occ_gr_o

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
	drop firm_id
	
	// number of employees in each firm
	gen emp = 1 if plant_id != .
	egen n_emp = sum(emp), by(plant_id yq)
	replace n_emp = . if n_emp == 0
	
	// saving
	tsset cpf yq
	save "output/data/RAIS_Quarterly_RS", replace
	
	
	
	
	
	
	
	
	
	
	
