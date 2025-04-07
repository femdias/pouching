// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: February 2025

// Purpose: Calculate number of employees in every month and in previous months

*--------------------------*
* BUILD
*--------------------------*

	forvalues ym = 516/695 {
	
		use "${data}/rais_m/rais_m`ym'", clear
	
		keep plant_id cpf
		gen count = 1
		collapse (sum) count, by(plant_id)
		gen ym = `ym'
	
		rename count n_emp
		
		order plant_id ym n_emp
		sort plant_id
		
		save "${data}/plantsize_m/plantsize_m`ym'", replace
	
	}
	
	// adding lagged employment variables
	
	forvalues ym = 516/695 {
		
	local ym_l12 = `ym' - 12
	local ym_l24 = `ym' - 24
	local ym_l36 = `ym' - 36
		
	use "${data}/plantsize_m/plantsize_m`ym'", clear
	
	if `ym' >= 516 & `ym' <= 527 {
		
		gen n_emp_l12 = .
		gen n_emp_l24 = .
		gen n_emp_l36 = .
		gen n_emp_lavg = .
		
	}
	
	if `ym' >= 528 & `ym' <= 539 {
		
		rename n_emp n_emp_current
		
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym_l12'", keepusing(n_emp)
		drop if _merge == 2
		drop _merge
		rename n_emp n_emp_l12
		replace n_emp_l12 = 0 if n_emp_l12 == .
		
		gen n_emp_l24 = .
		
		gen n_emp_l36 = .
		
		gen n_emp_lavg = n_emp_l12
		
		rename n_emp_current n_emp
		
	}
	
	
	if `ym' >= 540 & `ym' <= 551 {
		
		rename n_emp n_emp_current
		
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym_l12'", keepusing(n_emp)
		drop if _merge == 2
		drop _merge
		rename n_emp n_emp_l12
		replace n_emp_l12 = 0 if n_emp_l12 == .
		
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym_l24'", keepusing(n_emp)
		drop if _merge == 2
		drop _merge
		rename n_emp n_emp_l24
		replace n_emp_l24 = 0 if n_emp_l24 == .
		
		gen n_emp_l36 = .
		
		gen n_emp_lavg = (n_emp_l12 + n_emp_l24) / 2
		
		rename n_emp_current n_emp
		
	}
	
	if `ym' >= 552 & `ym' <= 695 {
		
		rename n_emp n_emp_current
		
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym_l12'", keepusing(n_emp)
		drop if _merge == 2
		drop _merge
		rename n_emp n_emp_l12
		replace n_emp_l12 = 0 if n_emp_l12 == .
		
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym_l24'", keepusing(n_emp)
		drop if _merge == 2
		drop _merge
		rename n_emp n_emp_l24
		replace n_emp_l24 = 0 if n_emp_l24 == .
		
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym_l36'", keepusing(n_emp)
		drop if _merge == 2
		drop _merge
		rename n_emp n_emp_l36
		replace n_emp_l36 = 0 if n_emp_l36 == .
		
		gen n_emp_lavg = (n_emp_l12 + n_emp_l24 + n_emp_l36) / 3
		
		rename n_emp_current n_emp
		
	}
	
	save "${data}/plantsize_m/plantsize_m`ym'", replace
	
	}
	
	
	
	
