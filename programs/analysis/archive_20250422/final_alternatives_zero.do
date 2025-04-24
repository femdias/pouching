// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing alternative explanations

*--------------------------*
* PREPARE
*--------------------------*

	// this table uses results that were generated along with other predictions
	do "${analysis}/final_pred4_zero"
	do "${analysis}/final_pred5_zero"
	
	// save table

	esttab c5_spv_4 c5_spv_5 c5_spvs_4 c5_spvs_5 c5_epvs_4 c5_espv_5 using "${results}/alternatives_zero.tex", booktabs  /// 
		replace compress noconstant nogap collabels(none) nomtitles label /// 
		refcat(d_size_w_ln "\midrule", nolabel) ///
		mgroups("Mgr to Mgr" "Mgr to Non-Mgr" "Non-Mgr to Mgr",  /// 
		pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker) ///
		coeflabels(d_size_w_ln "Destination firm size (ln)" ///
			d_growth_w "Destination firm empl. growth rate" ///
			o_size_w_ln "\\ Orig. firm size (ln)" ///
			o_avg_fe_worker "Orig. firm avg worker quality" ///
			c.o_size_w_ln#c.o_avg_fe_worker "Orig. firm size (ln) $\times$ orig. firm avg worker quality") ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 pred, fmt(0 3 0) label(" \\ Obs" "R-Squared" "Prediction")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		, labels("\cmark" ""))	
