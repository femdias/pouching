// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Event study around poaching events; heterogeneity by director status at destination			
	
*--------------------------*
* ANALYSIS
*--------------------------*

	use "output/data/evt_panel_m_dir", clear

	// sample restrictions

		// keeping events with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25 & n_emp_pos < .
		
	// variable for the heterogeneity analysis: pc_dirindestination
	
	// outcome variables: d_h_o_d_h_sanspc, d_h_o_d_h_sanspc_0
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
		
		// num: total number of hires in destination plant
		// den: total number of employees in destination plant
		gen d_h_d_emp = d_h / d_emp
		
		// number of hirings from origin plant (only poached individuals)
		gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
		
		// number of hirings from origin plant (excluding poached individuals)
		gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc
		
		// num: number of hirings from origin plant (excluding poached individuals) 
		// den: total number of hires in destination plant (excluding poached individuals) 
		gen d_h_o_d_h_sanspc = d_h_o_sanspc / (d_h - d_h_o_pc)
		gen d_h_o_d_h_sanspc_0  = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
	 		
	// collapsing by ym_rel & setting up a panel
	
	collapse (mean) d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0, by(pc_dirindestination ym_rel)
				
	tsset pc_dirindestination ym_rel
	
	// graphing
	
	local vars d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0
	
	local ld_h_o_d_h_sanspc		"0(.01).04"
	local ld_h_o_d_h_sanspc_0	"0(.01).04"	
	
	local td_h_o_d_h_sanspc		""Share of new hires (monthly)" "from same firm as poached manager""
	local td_h_o_d_h_sanspc_0	""Share of new hires (monthly)" "from same firm as poached manager""	
	
	
	foreach var of local vars {
	
	tsline `var' if pc_dirindestination == 0, recast(connect) mcolor(gs8) lcolor(gs8) m(Oh) || ///
	tsline `var' if pc_dirindestination == 1, recast(connect) mcolor(orange_red) lcolor(orange_red) m(Dh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle(`t`var'') ylabel(`l`var'', grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		legend(order(1 "No Longer Manager" 2 "Manager at Destination"))
	
		graph export "output/results/es_dir_dirtodir_`var'.pdf", as(pdf) replace
		
	}
	
