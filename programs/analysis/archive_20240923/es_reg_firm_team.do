// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Event study around poaching events -- SUPERVISORS ONLY
// Hires from team and not from team			
	
*--------------------------*
* ANALYSIS
*--------------------------

use "output/data/evt_panel_m_spv", clear

	// sample restrictions
	merge m:1 event_id using "temp/sample_selection_spv", keep(match) nogen
	
	// additional: drop the events with supervisors poached from more than 1 team
	merge m:1 event_id using "temp/list_morethan1spv", keep(master) nogen
	
// outcome variable: percentage of hires from origin firm

	// total number of hires in destination plant
	gen d_h = d_h_dir + d_h_spv + d_h_emp
		
	// number of hirings from origin plant (only poached individuals)
	gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
		
	// number of hirings from origin plant (excluding poached individuals)
	gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc			
		
	// num: number of hirings from origin plant (excluding poached individuals) 
	// den: total number of hires in destination plant (excluding poached individuals) 
	gen d_h_o_d_h_sanspc = d_h_o_sanspc / (d_h - d_h_o_pc)
	
		// version where missing points are replaced with a 0
		gen d_h_o_d_h_sanspc_0 = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
		
	// team/not team variable
	
		merge 1:1 event_id ym using "temp/spvteam"
		drop if _merge == 2
		drop _merge
	
		// from team
		gen d_h_o_team_d_h_sanspc = d_h_o_team / (d_h - d_h_o_pc)
		
		// not from team
		gen d_h_o_notteam_d_h_sanspc = d_h_o_notteam / (d_h - d_h_o_pc)
	
		// versions where missing points are replaced with a 0
		
		gen d_h_o_team_d_h_sanspc0 = d_h_o_team_d_h_sanspc
		replace d_h_o_team_d_h_sanspc0 = 0 if d_h_o_team_d_h_sanspc0 == .
		
		gen d_h_o_notteam_d_h_sanspc0 = d_h_o_notteam_d_h_sanspc
		replace d_h_o_notteam_d_h_sanspc0 = 0 if d_h_o_notteam_d_h_sanspc0 == .
			
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
					
// now for the regressions

	// present different versions, modifying the baseline period!!!				

	eststo team: reghdfe d_h_o_team_d_h_sanspc0 $evt_vars if ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id) 
	eststo notteam: reghdfe d_h_o_notteam_d_h_sanspc0 $evt_vars if ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)		
	coefplot (team, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) ///
		 (notteam, recast(connected) keep(${evt_vars}) msymbol(Dh) mcolor(navy) mlcolor(navy) msize(small) ///
		  levels(95) lcolor(navy%60) ciopts(lcolor(navy%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Same Team" 4 "Different Team") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).06)
		 
		graph export "output/results/es_reg_firm_team.pdf", as(pdf) replace
		
// further exploring this result

	gen team_rel = team / (team + notteam)
	
	hist team_rel if ym_rel == -12, plotregion(lcolor(white))  ///
		xtitle("Percentage of Coworkers in Supervisor Team") ///
		color(gs8) lcolor(black%30)
		
		graph export "output/results/es_reg_firm_team_hist.pdf", as(pdf) replace
	
	// how many workers are hired (total) from the team after the poaching event?
	
	egen team_total = sum(d_h_o_team) if ym_rel >= 0, by(event_id)
	egen notteam_total = sum(d_h_o_notteam) if ym_rel >= 0, by(event_id)
	
	gen team_total_rel = team_total / (team_total + notteam_total)	
	
	binscatter team_total_rel team_rel if ym_rel == 0,  line(none) leg(off) ///
		xtitle("Percentage of Coworkers in Supervisor Team") ///
		ytitle("Percentage of Hires from Supervisor Team") ///
		text(.02 .17 "% Hires = % Coworkers", size(small) color(black)) ///
		plotregion(lcolor(white)) ///
		msymbol(T) mcolor(maroon)
		graph addplot line team_rel team_rel, lcolor(gs12) lpattern(dash)
		
		graph export "output/results/es_reg_firm_team_bins.pdf", as(pdf) replace
	
	


	
	
	

