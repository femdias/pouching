
// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: October 2024

// Purpose: Compare quality of raided workers to moveable workers in origin firm - regression	

*--------------------------*
* ANALYSIS
*--------------------------*

// created datasets come from quality_origin
	
// looks like there are some events that have both type spv and type emp == 1
use "${temp}/quality_origin_final_spv_dir", clear
append "${temp}/quality_origin_final_emp_placebo"

	
// Create dummy for raided workers
gen group = .
replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) 
replace group = 4 if raid_individual == 0 & (spv == 0 & dir == 0) & moveable_worker_changed_firm == 1
			
gen group_dummy = .
replace group_dummy = 1 if group == 1
replace group_dummy = 0 if group == 4
	
// Create 2d and 3d CBO
gen cbo_2d = substr(occup_cbo2002, 1, 2)
	
// create id variable, because event_id is specific to each type
egen id = group(event_id e_type)

gen interaction_raid_spv = group_dummy * type_spv
	
// AKMfe_worker = a + b_1 (raided=1) + b_2 (SPV event = 1) + b_3 (raided x SVP event) + controls
eststo c1: reghdfe fe_worker group_dummy type_spv interaction_raid_spv tenure_ym tenure_overlap age  ///
		if pc_ym >= ym(2010,1), vce(robust) absorb(cbo2d=cbo_2d)
		estadd local cbo2d "\cmark"
			
eststo c1w: reghdfe fe_worker group_dummy type_spv interaction_raid_sp tenure_ym tenure_overlap age wage_real_ln ///
		if pc_ym >= ym(2010,1), vce(robust) absorb(cbo2d)
		estadd local cbo2d "\cmark"
			
eststo c3: reghdfe fe_worker group_dummy type_spv interaction_raid_spv tenure_ym tenure_overlap age  ///
		if pc_ym >= ym(2010,1), vce(robust) absorb(cbo2d new_id=id) 
		estadd local cbo2d "\cmark"
		estadd local new_id "\cmark"
		
eststo c3w: reghdfe fe_worker group_dummy type_spv interaction_raid_spv tenure_ym tenure_overlap age  wage_real_ln ///
		if pc_ym >= ym(2010,1), vce(robust) absorb(cbo2d new_id) 
		estadd local cbo2d "\cmark"
		estadd local new_id "\cmark"
	
	
	* DISPLAY
esttab c1 c1w c3 c3w ///
    using "${results}/reg_quality_origin.tex", tex /// 
    replace frag compress nomtitles noconstant nogap /// 
    mgroups("\textbf{Outcome var:} AKM Worker FE (at origin)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(group_dummy tenure_overlap tenure_ym age wage_real_ln type_spv interaction_raid_spv) /// 
    cells(b(star fmt(3)) se(par fmt(3))) ///  // Only standard errors, no p-values
    coeflabels(group_dummy "\hline \\ Raided individual" /// 
	tenure_ym "Tenure at origin" ///
        tenure_overlap "Overlap tenure with pc. mgr." ///
	age "Age" ///
	wage_real_ln "Wage (ln)" ///
	type_spv "Spv. event" ///
	interaction_raid_spv "Spv. event # Raided individual") ///
    stats(N r2 cbo2d new_id, fmt(0 3 0 0) label(" \\ Obs" "R-Squared" "\\ CBO (2 dig.)" "Firm FE")) ///
    obslast nolines ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
 
			
	

