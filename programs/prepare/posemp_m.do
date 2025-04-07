// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: February 2025

// Purpose: Calculate positive employment dummy variable

*--------------------------*
* BUILD
*--------------------------*

	forvalues ym = 600/683 {
			
	local ym_min = `ym' - 12
	local ym_max = `ym' + 12
		
	clear
	
	forvalues yymm=`ym_min'/`ym_max' {
	
		append using "${data}/plantsize_m/plantsize_m`yymm'"
		keep plant_id ym n_emp
		
	}
	
	// identifying `ym' plants
	
	gen ym_`ym' = (ym == `ym')
	egen ym_`ym'_plant = max(ym_`ym'), by(plant_id)
	keep if ym_`ym'_plant == 1
	drop ym_`ym'_plant ym_`ym'
		
	// counting plants that appear all months in the window (25 times)
	
	gen count = 1
	collapse (sum) n_months = count, by(plant_id)
	
	gen posemp = (n_months == 25)
	
	// organizing this data set
	
	gen ym=`ym'
	
	order plant_id ym n_months posemp
	
	label var plant_id "Worker ID (CPF)"
	label var ym "Year-Month"
	label var n_months "Months with Positive Employment (ym-12/ym+12)"
	label var posemp "25 Months of Positive Employment (ym-12/ym+12)"
	
	save "${data}/posemp_m/posemp_m`ym'", replace
	
	}
	
	
	
	
