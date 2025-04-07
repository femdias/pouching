// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing alternative explanations

*--------------------------*
* PREPARE
*--------------------------*

	// this table uses results that were generated along with other predictions
	do "${analysis}/final_pred4"
	do "${analysis}/final_pred5"
	do "${analysis}/final_pred6"
	
	// display table
	
	/*
	esttab  c5_spv_4 c5_spvs_4 c5_epvs_4 c5_spv_5 c5_spvs_5 c5_espv_5 c6_spv_6 c6_spvs_6 c6_epvs_6,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("4: spv-spv" "4: spv-emp" "4: emp-spv" "5: spv-spv" "5: spv-emp" "5: emp-spv" "6: spv-spv" "6: spv-emp" "6: emp-spv") ///
		keep(d_size_w_ln d_growth_w o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker  lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
		
	*/	
	 
	// save table

	esttab c5_spv_4 c5_spvs_4 c5_epvs_4 c5_spv_5 c5_spvs_5 c5_espv_5 c6_spv_6 c6_spvs_6 c6_epvs_6 using "${results}/alternatives.tex", booktabs  /// 
		replace compress noconstant nogap collabels(none) label /// 
		mlabel("Mgr-Mgr" "Mgr-Wkr" "Wkr-Mgr" "Mgr-Mgr" "Mgr-Wkr" "Wkr-Mgr" "Mgr-Mgr" "Mgr-Wkr" "Wkr-Mgr") ///
		refcat(d_size_w_ln "\midrule", nolabel) ///
		mgroups("Prediction 4" "Prediction 5" "Prediction 6",  /// 
		pattern(1 0 0 1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker  lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		coeflabels(d_size_w_ln "Destination firm size (ln)" ///
			d_growth_w "Destination firm empl. growth rate" ///
			o_size_w_ln "\\ Orig. firm size (ln)" ///
			o_avg_fe_worker "Orig. firm avg worker quality" ///
			c.o_size_w_ln#c.o_avg_fe_worker "Orig. firm size (ln) $\times$ orig. firm avg worker quality" ///
			rd_coworker_fe "\\ Quality of raided workers" ///
			lnraid "\# raided workers (ln)" ///
			c.rd_coworker_fe#c.lnraid "Quality of raided workers $\times$ \# raided workers (ln)") ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		, labels("\cmark" ""))
		
	esttab c5_spv_4 c5_spv_5 c6_spv_6 c5_spvs_4 c5_spvs_5 c6_spvs_6 c5_epvs_4 c5_espv_5 c6_epvs_6 using "${results}/alternatives.tex", booktabs  /// 
		replace compress noconstant nogap collabels(none) nomtitles label /// 
		refcat(d_size_w_ln "\midrule", nolabel) ///
		mgroups("Mgr to Mgr" "Mgr to Non-Mgr" "Non-Mgr to Mgr",  /// 
		pattern(1 0 0 1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker  lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		coeflabels(d_size_w_ln "Destination firm size (ln)" ///
			d_growth_w "Destination firm empl. growth rate" ///
			o_size_w_ln "\\ Orig. firm size (ln)" ///
			o_avg_fe_worker "Orig. firm avg worker quality" ///
			c.o_size_w_ln#c.o_avg_fe_worker "Orig. firm size (ln) $\times$ orig. firm avg worker quality" ///
			rd_coworker_fe "\\ Quality of raided workers" ///
			lnraid "\# raided workers (ln)" ///
			c.rd_coworker_fe#c.lnraid "Quality of raided workers $\times$ \# raided workers (ln)") ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 pred, fmt(0 3 0) label(" \\ Obs" "R-Squared" "Prediction")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager quality = pc_fe" ///
		, labels("\cmark" ""))	
