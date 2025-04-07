	
				// FIRST PASS
				
				use "output/data/evt_panel_m_rs_dir", clear
					
							
				binscatter wageratio ym_rel, line(connect) mcolor(navy) m(Oh)  by(emp_dfirm) ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Wage ratio (monthly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 

					
				binscatter h_cw_q ym_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Share of poached new hires (montlhly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
					
				binscatter h_cw_c ym_rel, line(connect) mcolor(navy) m(Oh)  ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Cumulate poached new hires / " "Total cumulative new hires") ylabel(0(.01).06, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
				binscatter h_cwe_c ym_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative month") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Cumulative poached employees /" "total employment ") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
					
					
				binscatter h_spv_c ym_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative month") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
					ytitle("Share of poached supervisor hires (cumulative) ") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax ) 
						
					
				binscatter h_dir_c ym_rel, line(connect) mcolor(navy) m(Oh)   ///
					graphregion(lcolor(white)) plotregion(lcolor(white)) ///
					xtitle("Relative month") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
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
		
		
		
		
	
	
	
		
		
	
	
	
