// Pocaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Create monthly panel with primary contracts only

*-----------------------------------------*
* BUILD
*-----------------------------------------*

forvalues y=2003/2017 {

	use "${RAIS_Clean}/RAIS_Clean_`y'", clear
	
	drop if cpf == ""
	drop worker_name // too heavy
	
			// dropping other variables we won't need
			cap drop pis
			cap drop ctps
			cap drop emp_on_dec31
			cap drop occup_cbo94
			cap drop date_of_birth
			cap drop nationality
			cap drop worker_disabled
			cap drop earn_dec_mw
			cap drop earn_avg_month_mw
			cap drop earn_dec_nom
			cap drop final_pay_year
			cap drop type_of_disability
			cap drop cnae95_class
			cap drop estab_type
			cap drop ibge_subsector
			cap drop ind_estab_cei
			cap drop cei_contract_estab
			cap drop ind_vinc_alvara
			cap drop estab_in_pat
			cap drop ind_simples
			cap drop leave_1_cause
			cap drop leave_2_cause
			cap drop leave_3_cause
			cap drop leave_1_ini_day
			cap drop leave_2_ini_day
			cap drop leave_3_ini_day
			cap drop leave_1_end_day
			cap drop leave_2_end_day
			cap drop leave_3_end_day
			cap drop leave_1_ini_mon
			cap drop leave_2_ini_mon
			cap drop leave_3_ini_mon
			cap drop leave_1_end_mon
			cap drop leave_2_end_mon
			cap drop leave_3_end_mon
			cap drop num_leave_days
			cap drop year_of_arrival
			cap drop cep_of_estab
			cap drop worker_muni
			cap drop company_name
			cap drop jan_pay
			cap drop feb_pay
			cap drop mar_pay
			cap drop apr_pay
			cap drop may_pay
			cap drop jun_pay
			cap drop jul_pay
			cap drop aug_pay
			cap drop sep_pay
			cap drop oct_pay
			cap drop nov_pay
			cap drop worker_in_union
			cap drop CLASCNAE20
	
	// worker status in each month
	
		generate hire_date = mdy(hire_month, hire_day, hire_year)
		format hire_date %td
		
		generate sep_date = mdy(sep_month, 1, `y') // assuming separating on day 1
		replace sep_date = hire_date if sep_date < hire_date // issue arising from lack of precise sep day
		format sep_date %td
		
		// end of month status
		generate emp_on_m1 = hire_date <= mdy(1,31,`y') & sep_date > mdy(1,31,`y')
		generate emp_on_m2 = hire_date <= mdy(2,28,`y') & sep_date > mdy(2,28,`y')
		generate emp_on_m3 = hire_date <= mdy(3,31,`y') & sep_date > mdy(3,31,`y')
		generate emp_on_m4 = hire_date <= mdy(4,30,`y') & sep_date > mdy(4,30,`y')
		generate emp_on_m5 = hire_date <= mdy(5,31,`y') & sep_date > mdy(5,31,`y')
		generate emp_on_m6 = hire_date <= mdy(6,30,`y') & sep_date > mdy(6,30,`y')
		generate emp_on_m7 = hire_date <= mdy(7,31,`y') & sep_date > mdy(7,31,`y')
		generate emp_on_m8 = hire_date <= mdy(8,31,`y') & sep_date > mdy(8,31,`y')
		generate emp_on_m9 = hire_date <= mdy(9,30,`y') & sep_date > mdy(9,30,`y')
		generate emp_on_m10 = hire_date <= mdy(10,31,`y') & sep_date > mdy(10,31,`y')
		generate emp_on_m11 = hire_date <= mdy(11,30,`y') & sep_date > mdy(11,30,`y')
		generate emp_on_m12 = hire_date <= mdy(12,31,`y') & sep_date > mdy(12,31,`y')
	
		save "${temp}/temp_`y'", replace
	
			// saving this into months
	
			forvalues m=1/12 {
				
				use "${temp}/temp_`y'", clear
				keep if emp_on_m`m' == 1
				save "${temp}/temp_`y'm`m'", replace
				
			 }
		
		// selecting the primary contract
		
		forvalues m=1/12 {
		
		use "${temp}/temp_`y'm`m'", clear
		
			// a. highest earning in the quarter
			egen double earn_avg_month_nom_max = max(earn_avg_month_nom), by(cpf)
			keep if earn_avg_month_nom == earn_avg_month_nom_max
			drop earn_avg_month_nom_max
			
			// b. highest number of contracted hours
			egen byte num_hours_contracted_max = max(num_hours_contracted), by(cpf)
			keep if num_hours_contracted == num_hours_contracted_max
			drop num_hours_contracted_max
			
			// c. highest tenure
			egen double tenure_months_max = max(tenure_months), by(cpf)
			keep if tenure_months == tenure_months_max
			drop tenure_months_max
			
			// d. sort by cpf-plant_id and select first observation
			sort cpf plant_id
			duplicates drop cpf, force
			
		// organizing panel
		gen year = `y'
		gen month = `m'
		gen ym = ym(year, month)
		format ym %tm
		order cpf ym year month
		
		// dropping some variables we won't need
		drop emp_on_m*
		
		// saving
		compress
		save "${data}/rais_m/rais_m_`y'm`m'", replace
		
		// erasing temporary file
		cap erase "${temp}/temp_`y'm`m'.dta"
		
		}
		
		// erasing temporary file
		cap erase "${temp}/temp_`y'.dta"
}

	// I want to rename these data sets, using monthly notation
	
	forvalues y=2003/2017 {
	forvalues m=1/12 {

		use "${data}/rais_m/rais_m_`y'm`m'", clear
	
		local ym = ym(`y', `m')
		di "`ym'"
	
		save "${data}/rais_m/rais_m`ym'", replace
		
			// erasing files with the other notation
			erase "${data}/rais_m/rais_m_`y'm`m'.dta"		
	
	}
	}
		
// organizing these data sets / adding more variables / deleting some files

forvalues ym=516/695 {	
	
use "${data}/rais_m/rais_m`ym'", clear

	// creating firm identifier
	drop cnpj_root
	gen firm_id = substr(plant_id,1,8)

	// remove CBO and IGNORADO from the occupation string
	replace occup_cbo2002 = subinstr(occup_cbo2002,"CBO","",.)
	replace occup_cbo2002 = subinstr(occup_cbo2002,"IGNORADO","",.)
	replace occup_cbo2002 = trim(occup_cbo2002)

	// remove CLASSE from the industry strings and then destring
	// remark: cnae20_class e cnae20_subclass is only avaiable in 2006-2017
	if `ym' >= ym(2006,1) {			
	
		replace cnae20_class = subinstr(cnae20_class,"CLASSE","",.)
		destring cnae20_class, force replace
		destring cnae20_subclass, force replace
		
	}	

	// occupational code: 1st digit
	gen occ_1d = substr(occup_cbo2002, 1, 1)
	destring occ_1d, replace 
		
	// occupational code: 3rd digit
	gen occ_3d = substr(occup_cbo2002, 3, 1)
	destring occ_3d, replace
	
	// identify government establishments
	
	tostring legal_nature, gen(legal_str)	
	gen gov = 0
	replace gov=1 if substr(legal_str, 1, 1) != "2" & legal_str!="."
	replace gov=1 if legal_str == "2011" | legal_str == "2038"
	drop legal_str

	// making the data set lighter, if possible
	
	compress 

	destring cpf plant_id firm_id, replace // automatically destringed as double

	format cpf %14.0f
	format plant_id %14.0f
	format firm_id %14.0f
	
	// number of employees in each ESTABLISHMENT
	gen emp = 1 if plant_id != .
	egen n_emp = sum(emp), by(plant_id)
	replace n_emp = . if n_emp == 0
	
	// number of employees in each FIRM
	egen n_emp_firm = sum(emp), by(firm_id)
	replace n_emp_firm = . if n_emp_firm == 0
	
	// saving
	tsset cpf ym
	save "${data}/rais_m/rais_m`ym'", replace
	
	
}

// identify occupational groups
// this analysis is done using calendar YEARS (hence, we have to temporarily combine all months in each year)

forvalues y=2003/2017 {

clear

	forvalues m=1/12 {
		
		local ym=ym(`y',`m')
		append using "output/data/rais_m/rais_m`ym'"	
		
	}
	
		// DIRECTORS
				
		// A. identify directors via occupation codes
		gen dir_temp = (occ_1d == 1)
		
			// within a year, director if director in all employed months
			
			egen n_emp_plant_year = count(plant_id), by(cpf plant_id)
			egen n_dir_plant_year = sum(dir_temp), by(cpf plant_id)
			
			gen dir = (dir_temp == 1 & (n_emp_plant_year == n_dir_plant_year))
						
		// B. identify directors via occupation codes OR via income criteria
		
		egen p95 = pctile(earn_avg_month_nom), p(95) by(plant_id ym)
		gen dirinc_temp = (earn_avg_month_nom >= p95 & earn_avg_month_nom < .)
		
			// within a year, director (income) if director (income) in all employed months
			
			egen n_dirinc_plant_year = sum(dirinc_temp), by(cpf plant_id)
			
			gen dirinc = (dirinc_temp == 1 & (n_emp_plant_year == n_dirinc_plant_year))
			
		gen dir5 = (dir == 1 | dirinc == 1)
					
		// C. identify supervisors via occupation codes
		gen spv_temp = (occ_3d == 0)
				
		// within a year, supervisor if supervisor in all employed months
			
			egen n_spv_plant_year = sum(spv_temp), by(cpf plant_id)
			
			gen spv = (spv_temp == 1 & (n_emp_plant_year == n_spv_plant_year))
			replace spv = 0 if dir == 1 // exclusion criteria
			
	// saving a temporary file
	save "${temp}/`y'", replace
	
	// once again, going back to the monthly data sets
	forvalues m=1/12 {
		
		use "${temp}/`y'", clear
		local ym=ym(`y',`m')
		keep if ym == `ym'
		save "${data}/rais_m/rais_m`ym'", replace	
		
	}

	// deleting the temporary file
	erase "${temp}/`y'.dta"
	
}			
		

	
	
