
// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: October 2024

// Purpose: Compare quality of raided workers to moveable workers in origin firm - CDF	
// Considering only events that have at least one raided and one moveable

*--------------------------*
* ANALYSIS
*--------------------------*

// created datasets come from quality_origin
	
set seed 12345	

/*

// We want to select only events that have at least one raided individual and at least one moveable individual
use "${temp}/quality_origin_spv", clear
collapse (sum) raid_individual moveable_worker_changed_firm, by(event_id) // 13,907 obs. 
keep if moveable_worker_changed_firm >=1 & raid_individual >= 1 // 7,174 obs.
save "${temp}/events_raided_moveable_spv", replace

use "${temp}/quality_origin_dir", clear
collapse (sum) raid_individual moveable_worker_changed_firm, by(event_id) // 11,638 obs. 
keep if moveable_worker_changed_firm >=1 & raid_individual >= 1 // 3,851 obs.
save "${temp}/events_raided_moveable_dir", replace

use "${temp}/quality_origin_emp", clear
collapse (sum) raid_individual moveable_worker_changed_firm, by(event_id) // 86,078 obs. 
keep if moveable_worker_changed_firm >=1 & raid_individual >= 1 // 33,490 obs.
save "${temp}/events_raided_moveable_emp", replace

sample 5775, count
save "${temp}/events_raided_moveable_emp_placebo", replace

*/


// THE PART THAT FOLLOWS SHOULD ALWAYS BE RUN!
// spv -- > spv
use "${temp}/quality_origin_spv", clear
// keep only events that have at least 1 raided and 1 moveable worker -- 7,174 distinct event id (ok)	
merge m:1 event_id using "${temp}/events_raided_moveable_spv", keep(match) nogen 	
keep if type_spv == 1
save "${temp}/quality_origin_sel_evts_final_spv", replace

// dir -- > spv
use "${temp}/quality_origin_dir", clear
merge m:1 event_id using "${temp}/events_raided_moveable_dir", keep(match) nogen // 3,851 obs (ok)
keep if type_spv == 1
save "${temp}/quality_origin_sel_evts_final_dir", replace

// emp --> spv
use "${temp}/quality_origin_sel_evts_emp", clear
merge m:1 event_id using "${temp}/events_raided_moveable_emp", keep(match) nogen // 33,490 obs (ok)
keep if type_spv == 1
save "${temp}/quality_origin_sel_evts_final_emp", replace

// emp --> emp
use "${temp}/quality_origin_emp", clear
merge m:1 event_id using "${temp}/events_raided_moveable_emp", keep(match) nogen 
keep if type_emp == 1
save "${temp}/quality_origin_sel_evts_final_emp_placebo", replace
	
// emp --> emp (placebo)
use "${temp}/quality_origin_emp", clear
merge m:1 event_id using "${temp}/events_raided_moveable_emp_placebo", keep(match) nogen // subset of events here
keep if type_emp == 1
save "${temp}/quality_origin_sel_evts_final_emp_placebo_sample", replace

// spv --> spv + dir --> spv	
use "${temp}/quality_origin_sel_evts_final_spv", clear
append using "${temp}/quality_origin_sel_evts_final_dir"
save "${temp}/quality_origin_sel_evts_final_spv_dir", replace

// spv -- > emp
use "${temp}/quality_origin_spv", clear
keep if type_emp == 1
save "${temp}/quality_origin_sel_evts_final_spv_emp", replace
	
	
	
	foreach e in spv dir emp spv_dir emp_placebo spv_emp emp_placebo_sample {
	
	use "${temp}/quality_origin_sel_evts_final_`e'", clear
	
	// distribution of AKM FE of origin firm non-raided "leftover people"

	// CDF: raided new hires vs non-raided leftover people
	
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) 
		//replace group = 2 if raid_individual == 0 & (spv == 0 & dir == 0) 
		//replace group = 3 if raid_individual == 0 & (spv == 0 & dir == 0)  & moveable_worker == 1
		replace group = 4 if raid_individual == 0 & (spv == 0 & dir == 0) & moveable_worker_changed_firm == 1
		label define group_l 1 "Raided New Hires" 2 "Non-Raided 'Leftover People'" ///
			3 "Non-Raided Moveable Workers" 4 "Non-Raided Moveable Across Firms Workers", replace
		label define group_l 1 "Raided New Hires" 4 "Moveable Stayers", replace // 2 "Non-Raided 'Leftover People'" 3 "Non-Raided Moveable Workers"///
		label values group group_l
		
		bysort event_id: gen has_raided = (group == 1)
		bysort event_id: gen has_moveable = (group == 4)

		egen raided_any = max(has_raided)
		egen moveable_any = max(has_moveable)
		
		gen stay = (raided_any == 1 & moveable_any == 1)
		
		bysort event_id: gen unique_event = _n == 1
		
		count if stay == 1 & unique_event == 1
		count if stay == 0 & unique_event == 1
		
		distplot fe_worker, over(group) xtitle("Worker FE") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white)) ///
			lcolor(emerald maroon) lpattern(solid dash) ///
			legend(region(lstyle(none)))
			
			graph export "${results}/quality_origin_sel_evts_`e'_sel_evts.pdf", as(pdf) replace
			graph export "${results}/quality_origin_sel_evts_`e'_sel_evts.png", as(png) replace
			
	// Winsorize the wage data (top and bottom 1%)
	winsor fe_worker, gen (fe_worker_winsor) p(0.01)

	ksmirnov fe_worker_winsor, by(group)
	

distplot fe_worker_winsor, over(group) xtitle("Worker Quality (AKM worker fixed effect)") ///
    ytitle("Cumulative Probability") plotregion(lcolor(white)) ///
    lcolor(emerald maroon) lpattern(solid dash) ///
    legend(region(lstyle(none)))
			
			graph export "${results}/quality_origin_sel_evts_winsor_`e'_sel_evts.pdf", as(pdf) replace
			graph export "${results}/quality_origin_sel_evts_winsor_`e'_sel_evts.png", as(png) replace
			
	// CDF: by group instead of by individual
		
		collapse (mean) fe_worker, by(event_id group e_type)
			
		distplot fe_worker, over(group) xtitle("Worker FE") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white)) ///
			lcolor(emerald maroon) lpattern(solid dash) ///
			legend(region(lstyle(none)))
			
			graph export "${results}/quality_origin_sel_evts_`e'_by_evt_id_sel_evts.pdf", as(pdf) replace
			graph export "${results}/quality_origin_sel_evts_`e'_by_evt_id_sel_evts.png", as(png) replace
			
	
	}
