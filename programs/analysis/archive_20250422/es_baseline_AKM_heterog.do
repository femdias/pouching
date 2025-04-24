// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: September 2024

// Purpose: Event study around poaching events			
	
*--------------------------*
* PREPARE
*--------------------------*

	// organizing data set with "spv --> spv" events
	/*
		// evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
		use "${data}/evt_panel_m_spv", clear
		// we need to merge to get some selections of sample, don't worry about it
		merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
		// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
		merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
		// keep only people that became spv
		keep if type_spv == 1

		save "${temp}/es_baseline_spv", replace
		
	// organizing data set with "dir --> spv" events	

		use "${data}/evt_panel_m_dir", clear
		merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
		keep if type_spv == 1
		
		save "${temp}/es_baseline_dir", replace
	
	// organizing data set with "emp --> spv" events	
	
		use "${data}/evt_panel_m_emp", clear
		merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
		keep if type_spv == 1
		
		save "${temp}/es_baseline_emp", replace
		
	// organizing data set with "emp --> emp" events (placebo evnts)
	
		use "${data}/evt_panel_m_emp", clear
		merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
		merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
		keep if type_emp == 1
		
		save "${temp}/es_baseline_placebo", replace
	*/
	
*--------------------------*
* ANALYSIS ---> using AKM FE classification
*--------------------------*



// Companies in the dataset in the AKM dataset
	use "${temp}/es_baseline_spv", clear // this all we need for the baseline events
	*append using "${temp}/es_baseline_dir"
	*append using "${temp}/es_baseline_emp"

	keep d_plant
	duplicates drop 
	
	* Editting and renaming destine firm ID before the merge
	tostring d_plant, generate(d_plant_str) format(%20.0f)
	gen firm_id = substr(d_plant_str, 1, 8)

	* If you need firm_id as numeric instead of string
	destring firm_id, replace

	* Bringing AKM classification (merge by destination firm)
	merge m:1 firm_id using "${data}/AKM_merged_classified.dta", keep(match master)

	/*
	    Result                      Number of obs
	    -----------------------------------------
	    Not matched                         4,240
		from master                     4,240  (_merge==1)
		from using                          0  (_merge==2)

	    Matched                             2,842  (_merge==3)
	    -----------------------------------------
	*/

	tab AKM_classification

	/*
	 AKM_classi |      Freq.     Percent        Cum.
	------------+-----------------------------------
	  High-High |      2,387       83.99       83.99
	   High-Low |        103        3.62       87.61
	   Low-High |        160        5.63       93.24
	    Low-Low |        192        6.76      100.00
	------------+-----------------------------------
	      Total |      2,842      100.00
	*/



// MAIN LINE: SPV --> SPV EVENTS
	
	use "${temp}/es_baseline_spv", clear // this all we need for the baseline events
	*append using "${temp}/es_baseline_dir"
	*append using "${temp}/es_baseline_emp"
	
	* Editting and renaming destine firm ID before the merge
	tostring d_plant, generate(d_plant_str) format(%20.0f)
	gen firm_id = substr(d_plant_str, 1, 8)

	* If you need firm_id as numeric instead of string
	destring firm_id, replace
	
	* Bringing AKM classification (merge by destination firm)
	merge m:1 firm_id using "${data}/AKM_merged_classified.dta", keep(match master)
	/*
		    Result                      Number of obs
	    -----------------------------------------
	    Not matched                       118,450
		from master                   118,450  (_merge==1)
		from using                          0  (_merge==2)

	    Matched                            83,875  (_merge==3)
	    -----------------------------------------
	*/
	
	drop if _merge == 1
	drop _merge
	
	
	// Loop through each AKM classification category
	forvalues akm_cat = 1/4 {
		
		// Filtering by AKM classification
		preserve
		keep if AKM_classification == `akm_cat'

		// organizing some variables we need
	
		// hire variables: winsorize to remove outliers 
		winsor d_h_emp_o, gen(d_h_emp_o_w) p(0.01) highonly
		winsor d_h_emp, gen(d_h_emp_w) p(0.01) highonl
		
		// main outcome variable: share of raided hires relative to all hires
		gen ratio = d_h_emp_o_w / d_h_emp_w 
		replace ratio = 0 if ratio == .
	
		// identifying months with zero/nonzero raids and hires
		g zeroraid = (d_h_emp_o_w==0)
		g zerohire = (d_h_emp_o_w==0)
		g nonzeroraid = (d_h_emp_o_w>0 & d_h_emp_w!=.)
		g nonzerohire = (d_h_emp_o_w>0 & d_h_emp_w!=.)
	
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
			
		eststo main_akm`akm_cat': reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		/*	
		eststo mainnum_akm`akm_cat': reghdfe d_h_emp_o_w $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
			
		eststo mainnonzero_akm`akm_cat': reghdfe nonzeroraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
			
		eststo mainnonzerohire_akm`akm_cat': reghdfe nonzerohire $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
			& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		*/
		restore
	}

	
	
	
// CONTROL LINE: EMP --> EMP EVENTS
	
	use "${temp}/es_baseline_placebo", clear // this all we need for the placebo events
	
	// organizing some variables we need
	
		// main outcome variable: share of raided hires relative to all hires 
		
		gen ratio = (d_h_emp_o - d_h_emp_o_pc) / (d_h_emp - d_h_emp_o_pc)
		replace ratio = 0 if ratio == .
	
		// identifying months with zero/nonzero raids and hires
		
		g numraid = d_h_emp_o - d_h_emp_o_pc
		g numhire = d_h_emp - d_h_emp_o_pc
		
		g zeroraid = (numraid==0)
		g zerohire = (numhire==0)
		g nonzeroraid = (numraid>0 & numraid!=.)
		g nonzerohire = numhire>0 & numhire!=.
	
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
	eststo controlnum: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	eststo controlnonzero: reghdfe nonzeroraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	eststo controlzerohire: reghdfe zerohire $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	eststo controlnonzerohire: reghdfe nonzerohire $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	*/	
		
			
	// FIGURE for each AKM category
	forvalues akm_cat = 1/4 {
		// Define AKM category label for the graph title
		local akm_label = cond(`akm_cat'==1, "High-High", ///
			     cond(`akm_cat'==2, "High-Low", ///
			     cond(`akm_cat'==3, "Low-High", "Low-Low")))

		// Ratio plot
		coefplot (main_akm`akm_cat', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
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
		 ylabel(-.02(.02).06) name(spv_akm`akm_cat', replace)
		 ///		 title("AKM: `akm_label'")
		 
		graph export "${results}/es_baseline_akm`akm_cat'.pdf", as(pdf) replace
/*
		// Number plot
		coefplot (mainnum_akm`akm_cat', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
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
		 ylabel(0(1)2) name(spv_num_akm`akm_cat', replace) ///
		 title("AKM: `akm_label'")
		 
		*graph export "${results}/es_baseline_n_akm`akm_cat'.pdf", as(pdf) replace */
	}		
			
			
			
			
			
			

			
			
			
			
			
			
			
			
			
		
			
			
			
			/*
			
			
			
			
			
	// FIGURE		
			
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
			 ylabel(-.02(.02).06) name(spv, replace)
			 
			 graph export "${results}/es_baseline.pdf", as(pdf) replace
			 *graph export "${results}/es_baseline.png", as(png) replace
		
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
			 *graph export "${results}/es_baseline_n.png", as(png) replace

}
