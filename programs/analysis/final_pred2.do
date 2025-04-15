// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 2
// "When a firm poaches a manager from another firm, the poaching firm is more likely to also raid their workers"

*--------------------------*
* MAIN EVENTS
*--------------------------*

/*

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
	
*/	
		
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

	/*
	
	use "${data}/evt_panel_m_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
		
	save "${temp}/pred2_emp_emp", replace
	
	*/
	
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
			
*/

*--------------------------*
* REGRESSION
*--------------------------*		 

// build -- supervisor events

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
		
			// outcomes we need:
			//	-- num raid
			// 	-- num hire
			
		// number of employees -- use t=0 value
		gen d_emp_t0_temp = d_emp if ym_rel == 0
		egen d_emp_t0 = max(d_emp_t0_temp), by(unique_id)
		drop d_emp_t0_temp
		
		// collapsing at the event level
		keep if ym_rel >= 0
		collapse (sum) numraid numhire (mean) d_emp_t0, by(unique_id)
		drop unique_id
		
		// saving temp file
		gen spv = 1
		save "${temp}/pred2_reg_spv", replace

// build -- emp events

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
		
			// outcomes we need:
			//	-- num raid
			// 	-- num hire
		
		// number of employees -- use t=0 value
		gen d_emp_t0_temp = d_emp if ym_rel == 0
		egen d_emp_t0 = max(d_emp_t0_temp), by(event_id)
		drop d_emp_t0_temp
		
		// collapsing at the event level

			// I still have to impose the period restriction
			keep if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)
		
		keep if ym_rel >= 0
		collapse (sum) numraid numhire (mean) d_emp_t0, by(event_id)
		drop event_id
		
		// saving temp file
		gen spv = 0
		save "${temp}/pred2_reg_emp", replace
	
// analysis

	use "${temp}/pred2_reg_spv", clear
	append using "${temp}/pred2_reg_emp"
	
	// outcome variables
	
		// raid 1 or more workers
		gen raid = (numraid >= 1 & numraid != .)
		
		// number of raided workers
		* already in data set: numraid
		
		// share of raided workers
		gen shareraid = (numraid / numhire)
		replace shareraid = 0 if shareraid ==.
		
	// right-hand size
		
		// dummy for event type
		* already in data set: spv
		label var spv "\hline \\ Manager-Manager"
		
		// firm size (in log)
		gen d_emp_ln = ln(d_emp_t0)
		
	// regressions
	
	eststo clear
	
	eststo: reg raid spv, rob
	
		summ raid, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo: reg raid spv d_emp_ln, rob
	
		summ raid, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo: reg numraid spv, rob
	
		summ numraid, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo: reg numraid spv d_emp_ln, rob
	
		summ numraid, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo: reg shareraid spv, rob
	
		summ shareraid, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo: reg shareraid spv d_emp_ln, rob
	
		summ shareraid, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
		
	
	// display table
	
	esttab,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("Raid > 1" "Raid > 1"  "# Raid" "# Raid" "Share Raid" "Share Raid") ///
		keep(spv) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(lhs N r2 , fmt(3 0 3) label("\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Destination firm controls} \\ Firm size = d_emp_ln" ///
		, labels("\cmark" ""))
	 
	// save table

	esttab using "${results}/pred2_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(d_size_w_ln "\midrule", nolabel) ///
		mgroups("At Least 1 Raid" "\# of Raided Workers" "Share of Raided Workers",  /// 
		pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(spv) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(lhs N r2 , fmt(3 0 3) label("\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Destination firm controls} \\ Firm size = d_emp_ln", labels("\cmark" ""))
		
*/		
		
*--------------------------*
* IMPROVERS VS. NON-IMPROVERS
*--------------------------*	
						
// combining events and keeping what we need

	use "${temp}/pred2_spv_spv", clear
	append using "${temp}/pred2_spv_emp"
	append using "${temp}/pred2_emp_spv"
	
	keep if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	drop _merge
	
	// merge with wage growth & improvement dummies
	
	rename d_plant plant_id
	
	levelsof ym, local(yms)
	
	foreach ym of local yms {
	
		merge m:1 plant_id ym using "${data}/wagegrowth_m/wagegrowth_m`ym'", update
		drop if _merge == 2
		drop _merge
	
	} 
	
	rename plant_id d_plant
	
			// saving a temporary file
			save "${temp}/final_pred2_spv_improv", replace
			
			// using this temporary file
			use "${temp}/final_pred2_spv_improv", clear
	
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
		
		// improv measures using t=0 values
		
		foreach m in mean_rgi50 median_rgi50 mean_llm50 median_llm50 {
		
			gen improv_`m'_evt_temp = improv_`m' if ym_rel == 0
			egen improv_`m'_evt = max(improv_`m'_evt_temp), by(unique_id)
			drop improv_`m'_evt_temp
		
		}
	
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
	
	foreach m in mean_rgi50 median_rgi50 mean_llm50 median_llm50 {
	
	eststo main_improvyes_`m': reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 1, ///
		absorb(unique_id d_plant) vce(cluster unique_id)
		
	eststo main_improvno_`m': reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 0, ///
		absorb(unique_id d_plant) vce(cluster unique_id)	
			
	eststo num_improvyes_`m': reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 1, ///
		absorb(unique_id d_plant) vce(cluster unique_id)
		
	eststo num_improvno_`m': reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 0, ///
		absorb(unique_id d_plant) vce(cluster unique_id)
		
	}
	
	// distributions
	
	// winsorizing variables for the figures
	
	foreach var in mean_wage_delta median_wage_delta mean_wage_delta_rgi50 median_wage_delta_rgi50 mean_wage_delta_llm50 median_wage_delta_llm50 {
	
	
	winsor `var', gen(`var'_w) p(.01)
	replace `var' = `var'_w
	drop `var'_w

	}
	
	
	// plotting the distributions
	
	foreach var in mean_wage_delta_rgi50 mean_wage_delta_llm50 {
	
	twoway kdensity mean_wage_delta if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) & ym_rel >= -9 & ym_rel == 0, ///
		lcolor(black) lpattern(solid) lwidth(medthick) || ///
		kdensity `var' if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) & ym_rel >= -9 & ym_rel == 0, ///
		lcolor(gs10) lpattern(dash) lwidth(medthick) ///
		xtitle("Wage growth") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(1 "Poaching firms" 2 "Local labor markets") rows(1) region(lcolor(white)) pos(6) ring(1))
		
		graph export "${results}/pred2_pdf_`var'.pdf", as(pdf) replace
		
	}	
	
	foreach var in median_wage_delta_rgi50 median_wage_delta_llm50 {
	
	twoway kdensity median_wage_delta if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) & ym_rel >= -9 & ym_rel == 0, ///
		lcolor(black) lpattern(solid) lwidth(medthick) || ///
		kdensity `var' if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) & ym_rel >= -9 & ym_rel == 0, ///
		lcolor(gs10) lpattern(dash) lwidth(medthick) ///
		xtitle("Wage growth") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(1 "Poaching firms" 2 "Local labor markets") rows(1) region(lcolor(white)) pos(6) ring(1))
		
		graph export "${results}/pred2_pdf_`var'.pdf", as(pdf) replace
		
	}	
	
	// number of improving firms using each of the measures
	
	tab improv_median_rgi50_evt if ym_rel == 0   & pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) // 5,425 events -- 3,127 are improvers
		
	tab improv_median_llm50_evt if ym_rel == 0 &  pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)  // 5,374 events -- 2,951 are improvers
	
	// total number of events
	
	tab count if ym_rel == 0 &  pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)
	
*--------------------------*
* PLACEBO EVENTS
*--------------------------*

// "emp --> emp" events	

	// organizing some variables we need
	
	use "${temp}/pred2_emp_emp", clear
	
	keep if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12)
	
	// merge with wage growth & improvement dummies
	
	rename d_plant plant_id
	
	levelsof ym, local(yms)
	
	foreach ym of local yms {
	
		merge m:1 plant_id ym using "${data}/wagegrowth_m/wagegrowth_m`ym'", update
		drop if _merge == 2
		drop _merge
	
	} 
	
	rename plant_id d_plant
	
			// saving a temporary file
			save "${temp}/final_pred2_emp_improv", replace
			
			// using this temporary file
			use "${temp}/final_pred2_emp_improv", clear
	
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
		
		// improv measures using t=0 values
		
		foreach m in mean_rgi50 median_rgi50 mean_llm50 median_llm50 {
		
			gen improv_`m'_evt_temp = improv_`m' if ym_rel == 0
			egen improv_`m'_evt = max(improv_`m'_evt_temp), by(event_id)
			drop improv_`m'_evt_temp
		
		}
	
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
	
	foreach m in mean_rgi50 median_rgi50 mean_llm50 median_llm50 {
	
	eststo ctrl_improvyes_`m': reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 1, ///
		absorb(event_id d_plant) vce(cluster event_id)
		
	eststo ctrl_improvno_`m': reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 0, ///
		absorb(event_id d_plant) vce(cluster event_id)	
			
	eststo nct_improvyes_`m': reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 1, ///
		absorb(event_id d_plant) vce(cluster event_id)
		
	eststo nct_improvno_`m': reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9 ///
		& improv_`m'_evt == 0, ///
		absorb(event_id d_plant) vce(cluster event_id)
		
	}
	
	
*--------------------------*
* EXHIBITS
*--------------------------*	
	
	clear
	
	foreach m in mean_rgi50 median_rgi50 mean_llm50 median_llm50 {
			
	coefplot (main_improvyes_`m', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (ctrl_improvyes_`m', recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 ylabel(-.02(.02).08) name(spv, replace)
		 
		 graph export "${results}/pred2_mainyes_`m'.pdf", as(pdf) replace
		 
	coefplot (main_improvno_`m', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (ctrl_improvno_`m', recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 ylabel(-.02(.02).08) name(spv, replace)
		 
		 graph export "${results}/pred2_mainno_`m'.pdf", as(pdf) replace	 
		
	coefplot (num_improvyes_`m', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (nct_improvyes_`m', recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 name(spv, replace)
		 
		 graph export "${results}/pred2_numyes_`m'.pdf", as(pdf) replace
		 
	coefplot (num_improvno_`m', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (nct_improvno_`m', recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 name(spv, replace)
		 
		 graph export "${results}/pred2_numno_`m'.pdf", as(pdf) replace
		 
	}	 
