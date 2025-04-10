// Poaching Project
// Created by: Felipe Macedo Dias
// (fm469@cornell.edu; fem.dias@hotmail.com)
// Date created: April 2025

// Purpose: Comparing coefficients of 



// Opening Log file
log using "${results}/alternatives_comparing_coeff.log", replace text

*-----------------------------------------*
* RE-ESTIMATE TO TEST PARAMETERS WITH SUEST
*-----------------------------------------*

* For using suest to compare coefficinets, we need the data to be in the same 
* dataset. Therefore, we will append the datasets used to create the "alternatives"
* table, and reestimate the the equations


* Appending the datasets and create the indicator variable
use "${temp}/pred4", clear
gen dataset = 4

append using "${temp}/pred5"
replace dataset = 5 if missing(dataset)

append using "${temp}/pred6"
replace dataset = 6 if missing(dataset)


// log of number of managers pouched			
gen pc_n_ln = ln(pc_n)
la var pc_n_ln "Number of pouched managers"

	
* Globals
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "
global firm_d "d_size_w_ln d_growth_w fe_firm_d_m"

 
 
 
 
********  From code "final_pred4"

// spv-spv
eststo c5_spv_4_alt: reg pc_wage_d d_size_w_ln d_growth_w     ///
		pc_wage_o_l1  $mgr lnraid pc_n_ln ///
		if $raidcond & $spvcond & ///
		dataset == 4
		
	estadd local pred "4"	
		
// spv-emp			
eststo c5_spvs_4_alt: reg pc_wage_d d_size_w_ln d_growth_w     ///
		pc_wage_o_l1 $mgr lnraid pc_n_ln ///
		if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1) & ///
		dataset == 4
	
	estadd local pred "4"
			
// emp-spv
eststo c5_epvs_4_alt: reg pc_wage_d d_size_w_ln d_growth_w    ///
		pc_wage_o_l1 $mgr lnraid pc_n_ln ///
		if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) & ///
		dataset == 4
		
	estadd local pred "4"
		
	
	
	
	


******** From code "final_pred5"
		
// tenure overlap
	
la var tenure_overlap "Manager tenure overlap"

// tenue overlap, ln

gen tenure_overlap_ln = ln(tenure_overlap)
la var tenure_overlap_ln "Manager tenure overlap (ln)"

* Regressions
// spv-spv
eststo c6_spv_5_alt: reg pc_wage_d  c.o_size_w_ln##c.tenure_overlap_ln lnraid pc_n_ln   /// 
	pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & $spvcond ///
	& rd_coworker_n>=1  & rd_coworker_fe_m==0 & ///
	dataset == 5 
	
	estadd local events "All"
	
	
	
eststo c5_spv_5_alt: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker  lnraid pc_n_ln   /// 
	pc_wage_o_l1 $mgr $firm_d pc_n_ln ///
	if pc_ym >= ym(2010,1) & $spvcond ///
	& rd_coworker_n>=1  & rd_coworker_fe_m==0 & ///
	dataset == 5 
		
	estadd local pred "5"
	estadd local events "All"	

	
// spv-emp		
qui eststo c5_spvs_5_alt: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
	pc_wage_o_l1 $mgr $firm_d lnraid pc_n_ln ///
	if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1) ///
	& rd_coworker_n>=1 & rd_coworker_fe_m==0 & ///
	dataset == 5  
	
	estadd local pred "5"

// emp-spv
qui eststo c5_espv_5_alt: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
	pc_wage_o_l1 $mgr $firm_d lnraid pc_n_ln ///
	if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ///
	& rd_coworker_n>=1  & rd_coworker_fe_m==0 & ///
	dataset == 5  
	
	estadd local pred "5"


		
	
******** From code "final_pred6"		
		
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "


// spv-spv
eststo c6_spv_6_alt: reg pc_wage_d d_size_w_ln d_growth_w c.rd_coworker_fe##c.lnraid ///
		pc_wage_o_l1  $mgr pc_n_ln  ///
		if $raidcond & $spvcond & ///
		dataset == 6 
		
		estadd local pred "6"
		
// spv-emp			
eststo c6_spvs_6_alt: reg pc_wage_d d_size_w_ln d_growth_w c.rd_coworker_fe##c.lnraid ///
		pc_wage_o_l1 $mgr pc_n_ln ///
		if $raidcond & (spv==2 & waged_svpemp<10 & waged_svpemp>=1) & ///
		dataset == 6 
		
		estadd local pred "6"

// emp-spv
eststo c6_epvs_6_alt: reg pc_wage_d d_size_w_ln d_growth_w c.rd_coworker_fe##c.lnraid ///
		pc_wage_o_l1 $mgr pc_n_ln ///
		if $raidcond & (spv==3 & waged_empspv<10 & waged_empspv>=1) & ///
		dataset == 6 
		
		estadd local pred "6"
		
	

	
	

******************************************
* 	Comparing coefficients		 *	
******************************************
	
* Seemingly unrelated estimation: sutest	
suest 	c5_spv_4_alt  c5_spv_5_alt  c6_spv_6_alt ///
	c5_spvs_4_alt c5_spvs_5_alt c6_spvs_6_alt ///
	c5_epvs_4_alt c5_espv_5_alt c6_epvs_6_alt, vce(robust)


	
di "###================ Destination Firm Size (d_size_w_ln) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Destination Firm Size (d_size_w_ln), 1st column"
test [c5_spv_4_alt_mean]d_size_w_ln = [c5_spvs_4_alt_mean]d_size_w_ln

di "Mgt-Mgt X NonMgt-Mgt, Destination Firm Size (d_size_w_ln), 1st column" 
test [c5_spv_4_alt_mean]d_size_w_ln = [c5_epvs_4_alt_mean]d_size_w_ln


di "Mgt-Mgt X Mgt-NonMgt, Destination Firm Size (d_size_w_ln), 2nd column" 
test [c5_spv_5_alt_mean]d_size_w_ln = [c5_spvs_5_alt_mean]d_size_w_ln

di "Mgt-Mgt X NonMgt-Mgt, Destination Firm Size (d_size_w_ln), 2nd column" 
test [c5_spv_5_alt_mean]d_size_w_ln = [c5_espv_5_alt_mean]d_size_w_ln


di "Mgt-Mgt X Mgt-NonMgt, Destination Firm Size (d_size_w_ln), 3rd column" 
test [c6_spv_6_alt_mean]d_size_w_ln = [c6_spvs_6_alt_mean]d_size_w_ln

di "Mgt-Mgt X NonMgt-Mgt, Destination Firm Size (d_size_w_ln), 3rd column" 
test [c6_spv_6_alt_mean]d_size_w_ln = [c6_epvs_6_alt_mean]d_size_w_ln



di "###================ Destination Firm Employment growth rate (d_growth_w) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Destination Firm Employment growth rate (d_growth_w), 1st column"
test [c5_spv_4_alt_mean]d_growth_w = [c5_spvs_4_alt_mean]d_growth_w

di "Mgt-Mgt X NonMgt-Mgt, Destination Firm Employment growth rate (d_growth_w), 1st column" 
test [c5_spv_4_alt_mean]d_growth_w = [c5_epvs_4_alt_mean]d_growth_w


di "Mgt-Mgt X Mgt-NonMgt, Destination Firm Employment growth rate (d_growth_w), 2nd column" 
test [c5_spv_5_alt_mean]d_growth_w = [c5_spvs_5_alt_mean]d_growth_w

di "Mgt-Mgt X NonMgt-Mgt, Destination Firm Employment growth rate (d_growth_w), 2nd column" 
test [c5_spv_5_alt_mean]d_growth_w = [c5_espv_5_alt_mean]d_growth_w


di "Mgt-Mgt X Mgt-NonMgt, Destination Firm Employment growth rate (d_growth_w), 3rd column" 
test [c6_spv_6_alt_mean]d_growth_w = [c6_spvs_6_alt_mean]d_growth_w

di "Mgt-Mgt X NonMgt-Mgt, Destination Firm Employment growth rate (d_growth_w), 3rd column" 
test [c6_spv_6_alt_mean]d_growth_w = [c6_epvs_6_alt_mean]d_growth_w




di "###================ Origin Firm Size (o_size_w_ln) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Origin Firm Size (o_size_w_ln), 2nd column" 
test [c5_spv_5_alt_mean]o_size_w_ln = [c5_spvs_5_alt_mean]o_size_w_ln

di "Mgt-Mgt X NonMgt-Mgt, Origin Firm Size (o_size_w_ln), 2nd column" 
test [c5_spv_5_alt_mean]o_size_w_ln = [c5_espv_5_alt_mean]o_size_w_ln


di "###================ Origin Firm Avg worker ability (AKM FE) (o_avg_fe_worker) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Origin Firm Avg worker ability (AKM FE) (o_avg_fe_worker), 2nd column" 
test [c5_spv_5_alt_mean]o_avg_fe_worker = [c5_spvs_5_alt_mean]o_avg_fe_worker

di "Mgt-Mgt X NonMgt-Mgt, Origin Firm Avg worker ability (AKM FE) (o_avg_fe_worker), 2nd column" 
test [c5_spv_5_alt_mean]o_avg_fe_worker = [c5_espv_5_alt_mean]o_avg_fe_worker


di "###================ Origin Firm Size X Avg worker ability (c.o_size_w_ln#c.o_avg_fe_worker) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Origin Firm Size X Avg worker ability (c.o_size_w_ln#c.o_avg_fe_worker), 2nd column" 
test [c5_spv_5_alt_mean]c.o_size_w_ln#c.o_avg_fe_worker  = [c5_spvs_5_alt_mean]c.o_size_w_ln#c.o_avg_fe_worker 

di "Mgt-Mgt X NonMgt-Mgt, Origin Firm Size X Avg worker ability (c.o_size_w_ln#c.o_avg_fe_worker), 2nd column" 
test [c5_spv_5_alt_mean]c.o_size_w_ln#c.o_avg_fe_worker  = [c5_espv_5_alt_mean]c.o_size_w_ln#c.o_avg_fe_worker 





di "###================ Raided workers Avg ability (AKM FE) (lnraid) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Raided workers Avg ability (AKM FE) (lnraid), 1st column"
test [c5_spv_4_alt_mean]lnraid = [c5_spvs_4_alt_mean]lnraid

di "Mgt-Mgt X NonMgt-Mgt, Raided workers Avg ability (AKM FE) (lnraid), 1st column" 
test [c5_spv_4_alt_mean]lnraid = [c5_epvs_4_alt_mean]lnraid


di "Mgt-Mgt X Mgt-NonMgt, Raided workers Avg ability (AKM FE) (lnraid), 2nd column" 
test [c5_spv_5_alt_mean]lnraid = [c5_spvs_5_alt_mean]lnraid

di "Mgt-Mgt X NonMgt-Mgt, Raided workers Avg ability (AKM FE) (lnraid), 2nd column" 
test [c5_spv_5_alt_mean]lnraid = [c5_espv_5_alt_mean]lnraid


di "Mgt-Mgt X Mgt-NonMgt, Raided workers Avg ability (AKM FE) (lnraid), 3rd column" 
test [c6_spv_6_alt_mean]lnraid = [c6_spvs_6_alt_mean]lnraid

di "Mgt-Mgt X NonMgt-Mgt, Raided workers Avg ability (AKM FE) (lnraid), 3rd column" 
test [c6_spv_6_alt_mean]lnraid = [c6_epvs_6_alt_mean]lnraid




di "###================ Raided workers Quantity raided workers (rd_coworker_fe) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Raided workers Quantity raided workers rd_coworker_fe), 3rd column" 
test [c6_spv_6_alt_mean]rd_coworker_fe = [c6_spvs_6_alt_mean]rd_coworker_fe

di "Mgt-Mgt X NonMgt-Mgt, Raided workers Quantity raided workers (rd_coworker_fe), 3rd column" 
test [c6_spv_6_alt_mean]rd_coworker_fe = [c6_epvs_6_alt_mean]rd_coworker_fe


di "###================ Raided workers Avg ability X Quantity (c.rd_coworker_fe#c.lnraid) ================###"

di "Mgt-Mgt X Mgt-NonMgt, Raided workers Avg ability X Quantity (c.rd_coworker_fe#c.lnraid), 3rd column" 
test [c6_spv_6_alt_mean]c.rd_coworker_fe#c.lnraid = [c6_spvs_6_alt_mean]c.rd_coworker_fe#c.lnraid 

di "Mgt-Mgt X NonMgt-Mgt, Raided workers Avg ability X Quantity (c.rd_coworker_fe#c.lnraid), 3rd column" 
test [c6_spv_6_alt_mean]c.rd_coworker_fe#c.lnraid = [c6_epvs_6_alt_mean]c.rd_coworker_fe#c.lnraid 




// Closing log
log close



