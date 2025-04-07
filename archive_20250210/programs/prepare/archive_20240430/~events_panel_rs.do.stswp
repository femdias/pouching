// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Constructing panel around the poaching events

*--------------------------*
* BUILD
*--------------------------*
	
	use "output/data/PoachingEvents_Quarterly_RS", clear
	
	collapse (sum) mgr director, by(event_id poaching_plant poaching_yq poached_plant) 
	isid event_id
	
		expand 13
		sort event_id
		
		by event_id: gen yq = poaching_yq - 7 + _n	
		format yq %tq
		
		gen yq_rel = yq - poaching_yq
		
		// restring to 2003-2008
		keep if yq >= yq(2003,1) & yq <= yq(2008,4)
		
	save "output/data/PoachingEvents_Panel_Quarterly_RS", replace
	
	
	// plants-quarters of interest
	
	use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
	keep poaching_plant yq
	egen unique = tag(poaching_plant yq)
	keep if unique == 1
	drop unique
		
	rename poaching_plant plant_id // for merging
		
	save "temp/d_firmlist", replace
	
// adding more variables
			
	// calculating number of employees using the full panel
	
	use "output/data/RAIS_Quarterly_RS", clear
		
	// keeping only the firms that poached workers in a period
		
	merge m:1 plant_id yq using "temp/d_firmlist", keep(match)

// Firm-level vars

	g emp_ft = emp if num_hours>=35 
	
	g hire_quarter = floor(hire_month / 4) + 1 // when they were hired, for the next date variable
	g hire_yq = yq(hire_year, hire_quarter) // set date
	g hire_t = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire == 2)) & num_hours>=35 // hire = 1 if they were hired in the quarter and type was 'readmissao'
	
	g h_wages = earn_avg_month_nom if hire_t==1
	g h_tenure = tenure_months if hire_t==1
	g h_tec = 1 if hire_t==1 & tcn==1 
	g h_dir = 1 if hire_t==1 & occ_1d==1
	g h_sup = 1 if hire_t==1 & occ_3d==0
	g h_dir5 = 1 if hire_t==1 & (occ_1d==1 | mgr_top5==1)
	
	g r_wages = earn_avg_month_nom if hire_t==0
	g r_tenure = tenure_months if hire_t==0
	g r_tec = 1 if hire_t==0 & tcn==1 
	g r_dir = 1 if hire_t==0 & occ_1d==1
	g r_sup = 1 if hire_t==0 & occ_3d==0
	g r_dir5 = 1 if hire_t==0 & (occ_1d==1 | mgr_top5==1)
		
// collapsing at the plant-quarter level
		
	collapse (sum) emp_ft emp hire_t h_tec h_dir h_sup h_dir5  r_tec r_dir r_sup r_dir5 (mean) h_wages h_tenure r_wages r_tenure , by(plant_id yq)
		
	order plant_id yq
	sort plant_id yq
		
	save "temp/d_firmvars", replace
		
// Event-level vars: number of coworker / director / mgr hires and employees

	use "output/data/CoWorkers_Panel_Quarterly_RS", clear

	// employment
	
	g emp_coworker = (plant_id == poaching_plant & occ_1d!=1)
	g emp_sup = (plant_id == poaching_plant & occ_3d==0)
	g emp_dir = (plant_id == poaching_plant & occ_1d == 1)
	g emp_dir5 = (plant_id == poaching_plant & occ_1d == 1 & (occ_1d==1 | mgr_top5==1))
	
	// hires
	
	g hire_quarter = floor(hire_month / 4) + 1
	g hire_yq = yq(hire_year, hire_quarter)
	
	g hire_t = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire == 2) & num_hours>=35)
	g hire_sup_t = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire == 2) & occ_3d==0 & num_hours>=35)
	g hire_dir_t = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire == 2) & occ_3d==0 & num_hours>=35)
	
	g h_coworker = (hire_t == 1 & plant_id == poaching_plant & occ_1d!=1) // exclude managers from this, but leave supervisors
	g h_sup = (hire_t == 1 & plant_id == poaching_plant & occ_3d==0)
	g h_dir = (hire_t == 1 & plant_id == poaching_plant & occ_1d == 1)
	g h_dir5 = (hire_t == 1 & plant_id == poaching_plant & occ_1d == 1 & (occ_1d==1 | mgr_top5==1))
		
	// collapsing at the ev - poaching_plant - yq
	
	collapse (sum) hire_t hire_sup_t hire_dir_t emp_coworker emp_sup emp_dir emp_dir5 h_coworker h_sup h_dir h_dir5, by(ev poaching_plant yq)  
	
	order ev poaching_plant yq
	sort ev poaching_plant yq
	
	save "temp/d_evtvars", replace
	
		// merging into the main data set: evt vars
		
		use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
		
		merge 1:1 ev poaching_plant yq using "temp/d_evtvars", nogen
		
		// merging into the main data set: firm vars
		
		rename poaching_plant plant_id // for merging -- again quite confusing to keep changing these
		merge m:1 plant_id yq using "temp/d_firmvars", nogen keep(master match) // lose 468?!

		rename plant_id poaching_plant
		
		// build variables
		
		tsset event_id yq_rel
		
		* Cumulative hires 
		
*		foreach var in hire_t h_coworker
		by event_id: g c_hire_t = sum(hire_t)
		by event_id: g c_hire_sup_t = sum(hire_sup_t)
		by event_id: g c_hire_dir_t = sum(hire_dir_t)
		by event_id: g c_h_coworker = sum(h_coworker)
		by event_id: g c_h_sup = sum(h_sup)
		by event_id: g c_h_dir = sum(h_dir)
		
		by event_id: g c_h_dir = sum(h_dir)
		
		g wageratio = h_wages /r_wages
		
		g h_cw_q = h_coworker / hire_t  // Coworker hires relative to total hires
		g h_cw_c = c_h_coworker / c_hire_t  // Coworker hires relative to total hires
		
		g h_sup_q = h_sup / hire_sup_t  // Coworker hires relative to total hires
		g h_sup_c = c_h_sup / c_hire_sup_t  // Coworker hires relative to total hires
				
		g h_dir_q = h_dir / hire_dir_t  // Coworker hires relative to total hires
		g h_dir_c = c_h_dir / c_hire_dir_t  // Coworker hires relative to total hires

		g h_cwe_q = h_coworker / emp_ft  // Coworker hires relative to total employment
		g h_cwe_c = c_h_coworker / emp_ft  // Coworker hires relative to total employment
		
		* Employment at destination firm --- need to get employment at the origin firm
		xtile emp_quartile = emp_ft if yq_rel==-1, nq(3)
		by event_id: egen emp_dfirm = max(emp_quartile)
		
		save "output/data/analysis_evt.dta", replace
		
				// FIRST PASS
				
				use "output/data/analysis_evt", clear
					
							
				binscatter wageratio yq_rel, line(connect) mcolor(navy) m(Oh)  by(emp_dfirm) ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative Quarter (manager poached at t=1, starts at t=0)") xlabel(-6(1)6) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Share of poached new hires (quarterly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
					
					
					
					
					
				binscatter h_cw_q yq_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative Quarter (manager poached at t=1, starts at t=0)") xlabel(-6(1)6) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Share of poached new hires (quarterly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
					
				binscatter h_cw_c yq_rel, line(connect) mcolor(navy) m(Oh)  ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative Quarter (manager poached at t=1, starts at t=0)") xlabel(-6(1)6) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Cumulate poached new hires / " "Total cumulative new hires") ylabel(0(.01).06, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
				binscatter h_cwe_c yq_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative Quarter") xlabel(-6(1)6) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Cumulative poached employees /" "total employment ") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
					
				binscatter h_sup_c yq_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative Quarter") xlabel(-6(1)6) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Share of poached supervisor hires (cumulative) ") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
						
					
				binscatter h_dir_c yq_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative Quarter") xlabel(-6(1)6) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Share of poached director hires (cumulative) ") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
					
				/*
				collapse (mean) hire hire_coworker hire_mgr hire_director, by(yq_rel)
				
				gen id = 1
				order id
				tsset id yq_rel
				
					tsline hire
					
					tsline hire_mgr
					
					gen hire_coworker_sansmgr = hire_coworker - hire_mgr
					tsline hire_coworker_sansmgr
					
					gen hire_mgr_rel = hire_mgr / hire
					tsline hire_mgr_rel
					
					gen hire_sansmgr = hire - hire_mgr
					gen hire_coworker_sansmgr_rel = hire_coworker_sansmgr / hire_sansmgr
					tsline hire_coworker_sansmgr_rel
					
					
					gen hire_coworker_sansdir = hire_coworker - hire_director
					tsline hire_coworker_sansdir
					
					gen hire_sansdir = hire - hire_dir
					gen hire_coworker_sansdir_rel = hire_coworker_sansdir / hire_sansdir
					tsline hire_coworker_sansdir_rel
		
		
		
		
	
	
	
		
		
	
	
	
