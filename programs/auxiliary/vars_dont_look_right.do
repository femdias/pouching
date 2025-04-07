// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: November 2024

// Purpose: Review creation of variables that don't look right

*--------------------------*
* PREPARE
*--------------------------*

/*
// o_size
use "${data}/poach_ind_spv", clear 
append using "${data}/poach_ind_dir"
append using "${data}/poach_ind_emp"
summ o_size, detail

use "${data}/cowork_panel_m_spv/cowork_panel_m_spv_620", clear
keep cpf ym_rel event_id pc
keep if event_id == 74 // only obs. for testing
egen o_size_temp = count(cpf) if ym_rel == -12, by(event_id) // counts number of cpfs per event_id
egen o_size = max(o_size_temp), by(event_id) // extends that to all rows, not only ym_rel = -12
drop o_size_temp
keep if pc == 1 // keeps only 1 row
collapse (mean) o_size, by(event_id d_plant pc_ym o_plant) // takes mean across equal rows (there will only be more than 1 row if more than 1 pc)

// Let's test with this event where o_size = 1 (also looks right)
use "${data}/cowork_panel_m_emp/cowork_panel_m_emp_626", clear
keep cpf ym_rel event_id pc d_plant pc_ym o_plant
keep if event_id == 77061 // in fact there is only 1 individual, the poached one
egen o_size_temp = count(cpf) if ym_rel == -12, by(event_id)
egen o_size = max(o_size_temp), by(event_id)
drop o_size_temp
keep if pc == 1
collapse (mean) o_size, by(event_id d_plant pc_ym o_plant)


// d_size
use "${data}/poach_ind_spv", clear 
append using "${data}/poach_ind_dir"
append using "${data}/poach_ind_emp"
summ d_size, detail


*/

use "${data}/evt_m_spv", clear
		
egen unique = tag(d_plant pc_ym)
keep if unique == 1 // nothing changes in the case of spv
keep event_id d_plant pc_ym
		
*save "${temp}/events_t0", replace	
		
use "${data}/rais_m/rais_m620", clear // monthly rais
	
// keeping t=0 (ym == pc_ym) for the destination plants
rename ym pc_ym
rename plant_id d_plant
merge m:1 d_plant pc_ym using "${temp}/events_t0", keep(match) // keep only firms that had poaching event
			
drop _merge
order event_id d_plant pc_ym
sort event_id cpf
		
gen count = 1 
collapse (sum) d_size=count, by(event_id) // count everybody by event id


// d_growth
// 1. Count of number of emp. is different here compared to d_size, but yields same result
// a.
use "${data}/poach_ind_spv", clear 
*append using "${data}/poach_ind_dir"
*append using "${data}/poach_ind_emp"
summ d_size, detail

// b.
use "${data}/evt_panel_m_spv", clear
gen d_emp_l0_temp = d_emp if ym_rel == 0
egen d_emp_l0 = max(d_emp_l0_temp), by(event_id)
drop d_emp_l0_temp
misstable summ d_emp_l0 // no missing obs.

keep if pc_ym >= ym(2011,1) 
			
egen unique = tag(event_id)
keep if unique == 1
keep event_id d_emp_l0
summ d_emp_l0, detail

// 2. Sometimes d_emp_l12 and d_emp_l1 are missing because d_emp is missing
use "${data}/evt_panel_m_spv", clear
gen d_emp_l12_temp = d_emp if ym_rel == -12
egen d_emp_l12 = max(d_emp_l12_temp), by(event_id)
drop d_emp_l12_temp
			
gen d_emp_l1_temp = d_emp if ym_rel == -1
egen d_emp_l1 = max(d_emp_l1_temp), by(event_id)
drop d_emp_l1_temp

misstable summ d_emp_l12 
misstable summ d_emp_l1
			
gen d_growth = d_emp_l1 / d_emp_l12 - 1
misstable summ d_growth
			
egen unique = tag(event_id)
keep if unique == 1
keep event_id d_emp_l12 d_emp_l1 d_growth


// why may d_emp be missing?
// this is how d_emp is created within evt_type_m

// o_size_ratio
use "${data}/poach_ind_spv", clear 
append using "${data}/poach_ind_dir"
append using "${data}/poach_ind_emp"
summ o_size_ratio, detail

use "${data}/cowork_panel_m_spv/cowork_panel_m_spv_620", clear

sort event_id cpf ym_rel

// size of the origin firm
egen o_size_temp = count(cpf) if ym_rel == -12, by(event_id)
egen o_size = max(o_size_temp), by(event_id)
drop o_size_temp
			
// number of mgrs at origin firm -- we need this to calculate # emp / # mgr
egen o_size_mgr_temp = sum(spv) if ym_rel == -12, by(event_id)
egen o_size_mgr = max(o_size_mgr_temp), by(event_id)
drop o_size_mgr_temp
		
// calculate # emp / # mgr
gen o_size_ratio = o_size / o_size_mgr

keep if pc == 1
collapse (mean) o_size o_size_mgr o_size_ratio, ///
		by(event_id d_plant pc_ym o_plant)
