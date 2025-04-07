// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 2
// "When a firm poaches a manager from another firm, the poaching firm is more likely to also raid their workers"

*--------------------------*
* MAIN EVENTS
*--------------------------*

// "spv --> spv" events
		
	use "${data}/evt_panel_m_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1

	save "${temp}/pred2_spv_spv", replace
	
// "spv --> emp" events
		
	use "${data}/evt_panel_m_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_emp == 1
	
	// generating identifier
	gen spv = 2

	save "${temp}/pred2_spv_emp", replace	
	
// "emp --> spv" events	

	use "${data}/evt_panel_m_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 3

	save "${temp}/pred2_emp_spv", replace
		
// combining events and keeping what we need

	use "${temp}/pred2_spv_spv", clear
	append using "${temp}/pred2_spv_emp"
	append using "${temp}/pred2_emp_spv"
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	
	// generate unique id
	egen unique_id = group(event_id spv)
	
	// organizing some variables we need
	
		// hire variables: winsorize to remove outliers 
		winsor d_h_emp_o, gen(d_h_emp_o_w) p(0.01) highonly
		winsor d_h_emp, gen(d_h_emp_w) p(0.01) highonly
		winsor d_h_emp_o_pc, gen(d_h_emp_o_pc_w) p(0.01) highonly
		
		// main outcome variable: share of raided hires relative to all hires
		
		g numraid = .
		replace numraid = d_h_emp_o_w 			if spv == 1
		replace numraid = d_h_emp_o_w - d_h_emp_o_pc_w  if spv == 2
		replace numraid = d_h_emp_o_w 			if spv == 3
		
		g numhire = .
		replace numhire = d_h_emp_w 			if spv == 1
		replace numhire = d_h_emp_w - d_h_emp_o_pc_w 	if spv == 2
		replace numhire = d_h_emp_w 			if spv == 3
			
		gen ratio = (numraid) / (numhire)
		replace ratio = 0 if ratio == .
		
		// cumulative outcome variable
		
		bysort event_id (ym_rel) : gen numraid_cumm = sum(numraid) if ym_rel >= -9
		bysort event_id (ym_rel) : gen numhire_cumm = sum(numhire) if ym_rel >= -9
		
		gen ratio_cumm = (numraid_cumm) / (numhire_cumm) if ym_rel >= -9
		replace ratio_cumm = 0 if ratio_cumm == .
		
		// identifying months with zero/nonzero raids and hires
		g zeroraid = (numraid==0)
		g zerohire = (numhire==0)
		g nonzeroraid = (numraid>0 & numraid!=.)
		g nonzerohire = (numhire>0 & numhire!=.)
		
		// identifying event with at least 1 raided worker
		egen total_raid_temp = sum(numraid) if ym_rel >= 0, by(unique_id)
		egen total_raid = max(total_raid_temp), by(unique_id)
	
		// event time dummies		
						
			forvalues i = -12/12 {
				if (`i' < 0) {
					local j = abs(`i')
					gen evt_l`j' = (ym_rel == `i')
				}
				else if `i' >= 0 {
					gen evt_f`i' = (ym_rel == `i') 
				}
			}
			
		// event zero for graphing purposes
		gen evt_zero = 1	
		
	// regressions
	
	eststo main: reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(unique_id d_plant) vce(cluster unique_id)
			
	/*
	eststo main_cumm: reghdfe ratio_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(unique_id d_plant) vce(cluster unique_id)
		
		eststo mainoneplus: reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(unique_id d_plant) vce(cluster unique_id)
			
		eststo mainoneplus_cumm: reghdfe ratio_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(unique_id d_plant) vce(cluster unique_id)	
	*/				
		
	eststo mainnum: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(unique_id d_plant) vce(cluster unique_id)
	
	/*
	eststo mainnum_cumm: reghdfe numraid_cum $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(unique_id d_plant) vce(cluster unique_id)	
		
		eststo mainnumoneplus: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(unique_id d_plant) vce(cluster unique_id)
			
		eststo mainnumoneplus_cumm: reghdfe numraid_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(unique_id d_plant) vce(cluster unique_id)		
		
	eststo mainnonzero: reghdfe nonzeroraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(unique_id d_plant) vce(cluster unique_id)
		
	eststo mainnonzerohire: reghdfe nonzerohire $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(unique_id d_plant) vce(cluster unique_id)
	*/
	
	// calculating number of observations
	egen unique = tag(unique_id)if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)
	tab unique // 5722 events
	
	// calculating baseline average in t=-3
	summ ratio if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) & ym_rel == -3
	
*--------------------------*
* PLACEBO EVENTS
*--------------------------*

// "emp --> emp" events	
	
	use "${data}/evt_panel_m_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
		
	save "${temp}/pred2_emp_emp", replace
	
	// organizing some variables we need
	
	use "${temp}/pred2_emp_emp", clear
	
		// hire variables: winsorize to remove outliers 
		winsor d_h_emp_o, gen(d_h_emp_o_w) p(0.01) highonly
		winsor d_h_emp, gen(d_h_emp_w) p(0.01) highonly
		winsor d_h_emp_o_pc, gen(d_h_emp_o_pc_w) p(0.01) highonly
		
		// main outcome variable: share of raided hires relative to all hires
		
		g numraid = d_h_emp_o_w - d_h_emp_o_pc_w
		g numhire = d_h_emp_w - d_h_emp_o_pc_w
			
		gen ratio = (numraid) / (numhire)
		replace ratio = 0 if ratio == .
		
		// cumulative outcome variable
		
		bysort event_id (ym_rel) : gen numraid_cumm = sum(numraid) if ym_rel >= -9
		bysort event_id (ym_rel) : gen numhire_cumm = sum(numhire) if ym_rel >= -9
		
		gen ratio_cumm = (numraid_cumm) / (numhire_cumm) if ym_rel >= -9
		replace ratio_cumm = 0 if ratio_cumm == .
	
		// identifying months with zero/nonzero raids and hires
		
		g zeroraid = (numraid==0)
		g zerohire = (numhire==0)
		g nonzeroraid = (numraid>0 & numraid!=.)
		g nonzerohire = numhire>0 & numhire!=.
		
		// identifying event with at least 1 raided worker
		egen total_raid_temp = sum(numraid) if ym_rel >= 0, by(event_id)
		egen total_raid = max(total_raid_temp), by(event_id)
	
		// event time dummies		
						
			forvalues i = -12/12 {
				if (`i' < 0) {
					local j = abs(`i')
					gen evt_l`j' = (ym_rel == `i')
				}
				else if `i' >= 0 {
					gen evt_f`i' = (ym_rel == `i') 
				}
			}
			
		// event zero for graphing purposes
		gen evt_zero = 1	
		
	// regressions
		
	eststo control: reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
	
	/*
	eststo control_cumm: reghdfe ratio_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)	
		
		eststo controloneplus: reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(event_id d_plant) vce(cluster event_id)
			
		eststo controloneplus_cumm: reghdfe ratio_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(event_id d_plant) vce(cluster event_id)
	*/		
		
	eststo controlnum: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
	
	/*
	eststo controlnum_cumm: reghdfe numraid_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)	
		
		eststo controlnumoneplus: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(event_id d_plant) vce(cluster event_id)
			
		eststo controlnumoneplus_cumm: reghdfe numraid_cumm $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9 & total_raid >= 1, absorb(event_id d_plant) vce(cluster event_id)	
		
	eststo controlnonzero: reghdfe nonzeroraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	eststo controlzerohire: reghdfe zerohire $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	eststo controlnonzerohire: reghdfe nonzerohire $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
	*/
	
	egen unique = tag(event_id) if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)
	tab unique // 95,580
		
*--------------------------*
* EXHIBITS
*--------------------------*	
	
	clear
			
	coefplot (main, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (control, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 ylabel(-.02(.02).08) name(spv, replace)
		 
		 graph export "${results}/es_baseline.pdf", as(pdf) replace
		
	coefplot (mainnum, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (controlnum, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Average number of raided hires" ) ///
		 ylabel(0(1)2) name(spv_num, replace)
		 
		 graph export "${results}/es_baseline_n.pdf", as(pdf) replace
		
	/* ARCHIVE
				 
	coefplot (main_cumm, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (control_cumm, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 ylabel(-.02(.02).08) name(spv, replace)
		 
		 graph export "${results}/es_baseline_cumm.pdf", as(pdf) replace
			 
		 
		coefplot (mainoneplus, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
			 (controloneplus, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
			 , ///
			 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
			 plotregion(lcolor(white)) ///
			 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
			 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
			 xtitle("Months relative to poaching event") ///
			 ytitle("Share of new hires" "from the same firm as poached worker") ///
			 ylabel(-.02(.02).14) name(spv, replace)
			 
			 graph export "${results}/es_baseline_oneplus.pdf", as(pdf) replace
			 
			 
			 coefplot (mainoneplus_cumm, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
			 (controloneplus_cumm, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
			 , ///
			 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
			 plotregion(lcolor(white)) ///
			 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
			 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
			 xtitle("Months relative to poaching event") ///
			 ytitle("Share of new hires" "from the same firm as poached worker") ///
			 ylabel(-.02(.02).14) name(spv, replace)
			 
			 graph export "${results}/es_baseline_oneplus_cumm.pdf", as(pdf) replace
			 	 
	coefplot (mainnum_cumm, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (controlnum_cumm, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Average number of raided hires" ) ///
		 ylabel(0(1)8) name(spv_num, replace)
		 
		 graph export "${results}/es_baseline_cumm_n.pdf", as(pdf) replace

		 
		coefplot (mainnumoneplus, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
			 (controlnumoneplus, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
			 , ///
			 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
			 plotregion(lcolor(white)) ///
			 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
			 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
			 xtitle("Months relative to poaching event") ///
			 ytitle("Average number of raided hires" ) ///
			 ylabel(0(1)3) name(spv_num, replace)
			 
			 graph export "${results}/es_baseline_oneplus_n.pdf", as(pdf) replace
			 
			 
		coefplot (mainnumoneplus_cumm, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
			 (controlnumoneplus_cumm, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
			  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
			 , ///
			 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
			 plotregion(lcolor(white)) ///
			 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
			 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
			 xtitle("Months relative to poaching event") ///
			 ytitle("Average number of raided hires" ) ///
			 ylabel(0(2)10) name(spv_num, replace)
			 
			 graph export "${results}/es_baseline_oneplus_n_cumm.pdf", as(pdf) replace
			
		 
	
	
	
	
