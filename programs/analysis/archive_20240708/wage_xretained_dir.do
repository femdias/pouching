// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Wage analysis (poached workers vs. retained workers) 

*--------------------------*
* ANALYSIS
*--------------------------*

use "output/data/evt_work_m_rs_dir", clear

	// selecting sample of interest
	merge m:1 event_id using "output/data/sample_selection_dir", keep(match) nogen

	// regresions
	
	eststo clear
	
		// columns (1) and (2)
		// comparison group: workers in same occupation as poached director
	
		eststo: areg wage_real_ln pc_individual 	   if sample_2digit == 1, ///
			absorb(event_id) vce(cluster event_id)
			
			estadd local eventfe	"\cmark" 	
			estadd local experience ""
			estadd local sample	"All"
			estadd local comp	"Same Occ"
				
		eststo: areg wage_real_ln pc_individual experience if sample_2digit == 1, ///
			absorb(event_id) vce(cluster event_id) 
			
			estadd local eventfe	"\cmark" 	
			estadd local experience "\cmark"
			estadd local sample	"All"
			estadd local comp	"Same Occ"

		// columns (3) and (4)
		// comparison group: directors + analysis restricted to events where poached director is hired as a director
		
		egen event_dirindestination = max(pc_dirindestination_ind), by(event_id)
		gen sample_dirindest = (event_dirindestination == 1 & dir == 1)
		
		eststo: areg wage_real_ln pc_individual 	   if sample_dirindest == 1, ///
			absorb(event_id) vce(cluster event_id)
			
			estadd local eventfe	"\cmark" 	
			estadd local experience ""
			estadd local sample	"Still Mgrs"
			estadd local comp	"Mgrs Dest"
			
		eststo: areg wage_real_ln pc_individual experience if sample_dirindest == 1, ///
			absorb(event_id) vce(cluster event_id)
			
			estadd local eventfe	"\cmark" 	
			estadd local experience "\cmark"
			estadd local sample	"Still Mgrs"
			estadd local comp	"Mgrs Dest"
			
		// columns (5) and (6)
		// comparison group: directors + analysis restricted to events where poached director is NOT hired as a director
		
		gen sample_nodirindest = (event_dirindestination == 0 & pc_individual == 1) | ///
			(event_dirindestination == 0 & pc_individual == 0 & dir == 1)
		
		eststo: areg wage_real_ln pc_individual            if sample_nodirindest == 1, ///
			absorb(event_id) vce(cluster event_id)
			
			estadd local eventfe	"\cmark" 	
			estadd local experience ""
			estadd local sample	"Not Mgrs"
			estadd local comp	"Mgrs Dest"
			
		eststo: areg wage_real_ln pc_individual experience if sample_nodirindest == 1, ///
			absorb(event_id) vce(cluster event_id) 
		
			estadd local eventfe	"\cmark" 	
			estadd local experience "\cmark"
			estadd local sample	"Not Mgrs"
			estadd local comp	"Mgrs Dest"
			
	// table
	
	esttab using "output/results/tab_wage_xretained_dir.tex", tex ///
		replace frag compress noconstant nomtitles nogap collabels(none) ///
		mgroups("\textbf{Outcome var:} ln(wage) at destination", ///
		pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
		erepeat(\cmidrule(lr){@span})) ///
 		keep(pc_individual) ///
		cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
		coeflabels(pc_individual "\hline \\ Poached Manager") ///
		stats(N r2 eventfe experience sample comp , fmt(0 3 0 0 0 0) ///
		label("\\ Obs" "R-Squared" "\\ \textbf{Controls}: \\ \textit{Event FE}" "\textit{Experience (yrs)}" ///
		"\\ \textbf{Events}" "\textbf{Comparison}"  )) ///
		obslast nolines ///
		starlevels(* 0.1 ** 0.05 *** 0.01)
				
		
			
	        
	
