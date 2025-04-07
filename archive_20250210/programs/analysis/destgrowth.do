// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Event study around poaching events			

*--------------------------*
* ANALYSIS 
*--------------------------*

// we will use events from different data sets
// use list of events from Table 2

	use "${temp}/table2", clear 
	g spvsample = .
	local spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "	
	global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
	global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
	reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & `spvcond',  rob 
	replace spvsample = e(sample) 
	keep if spvsample == 1
	keep spv event_id
	save "${temp}/eventlist", replace	

// "spv --> spv" events
		
	// evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
	use "${data}/evt_panel_m_spv", clear
	// we need to merge to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	// keep only people that became spv
	keep if type_spv == 1
	// generating identifier
	gen spv = 1

	save "${temp}/destgrowth_spv", replace
	
// "spv --> emp" events
		
	// evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
	use "${data}/evt_panel_m_spv", clear
	// we need to merge to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	// keep only people that became spv
	keep if type_emp == 1
	// generating identifier
	gen spv = 2

	save "${temp}/destgrowth_spv_emp", replace	
	
// "emp --> spv" events	

	use "${data}/evt_panel_m_emp", clear
	// we need to merge to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	// keep only people that became spv
	keep if type_spv == 1
	// generating identifier
	gen spv = 3

	save "${temp}/destgrowth_emp", replace
		
// combining everything and keeping events from Table 2 (MEAN HIRES MEDIAN EMP)

	use "${temp}/destgrowth_spv", clear
	append using "${temp}/destgrowth_spv_emp"
	append using "${temp}/destgrowth_emp"
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	
	// outcome variables
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
		
			// hire variables: winsorize to remove outliers 
			winsor d_h, gen(d_h_w) p(0.01) highonly
	
		// total number of employees in destination plant
		* d_emp: already in the data set
						
	// collapsing by ym_rel & setting up a panel
	
	collapse (mean) d_h_w (median) d_emp, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	// graphing
	
	tsline d_emp, recast(connect) mcolor(gs1) m(Oh) lcolor(gs1) ///
		ytitle("Number of employees (monthly)") ylabel(125(25)275, grid glpattern(dot) glcolor(gs13*.3) gmax) ||  ///
		tsline d_h_w, recast(bar) yaxis(2) color(gs8%60) ///
		ytitle("Number of hires (monthly)", axis(2)) ylabel(15(5)40, grid glpattern(dot) glcolor(gs13*.3) gmax axis(2)) ///
			graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-0.5, lpattern(dot) lcolor(gs13) lwidth(5)) ///
		legend(order(1 "Employees" 2 "New Hires") region(lcolor(white)) pos(6) col(2)) ///
		text(275 -4.1 "Poaching event", size(medsmall) color(gs8))
		
		graph export "${results}/destgrowth_v1.pdf", as(pdf) replace
		
// combining everything and keeping events from Table 2 (MEDIAN HIRES MEDIAN EMP)

	use "${temp}/destgrowth_spv", clear
	append using "${temp}/destgrowth_spv_emp"
	append using "${temp}/destgrowth_emp"
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	
	// outcome variables
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
		
			// hire variables: winsorize to remove outliers 
			winsor d_h, gen(d_h_w) p(0.01) highonly
	
		// total number of employees in destination plant
		* d_emp: already in the data set
						
	// collapsing by ym_rel & setting up a panel
	
	collapse (median) d_h_w d_emp, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	// graphing
	
	tsline d_emp, recast(connect) mcolor(gs1) m(Oh) lcolor(gs1) ///
		ytitle("Number of employees (monthly)") ylabel(125(25)275, grid glpattern(dot) glcolor(gs13*.3) gmax) ||  ///
		tsline d_h_w, recast(bar) yaxis(2) color(gs8%60) ///
		ytitle("Number of hires (monthly)", axis(2)) ylabel(4(4)16, grid glpattern(dot) glcolor(gs13*.3) gmax axis(2)) ///
			graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-0.5, lpattern(dot) lcolor(gs13) lwidth(5)) ///
		legend(order(1 "Employees" 2 "New Hires") region(lcolor(white)) pos(6) col(2)) ///
		text(275 3.3 "Poaching event", size(medsmall) color(gs8))
		
		graph export "${results}/destgrowth_v2.pdf", as(pdf) replace		
	
