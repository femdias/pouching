// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: February 2025

// Purpose: Calculate wage growth variables

*--------------------------*
* BUILD
*--------------------------*

	forvalues ym = 552/695 { // no industry variable before 2006 (first month: 2006m1 / 552)
	
		local yymm = `ym' - 12
	
		use "${data}/rais_m/rais_m`ym'", clear
	
		keep plant_id cpf year muni cnae20_class earn_avg_month_nom
		
		// adjusting wages
			
			merge m:1 year using "${input}/auxiliary/ipca_brazil"
			generate index_2017 = index if year == 2017
			egen index_base = max(index_2017)
			generate adj_index = index / index_base		
			generate wage_real = earn_avg_month_nom / adj_index
					
			// in logs
			gen wage_real_ln = ln(wage_real)
					
			drop if _merge == 2
			drop _merge index index_2017 index_base adj_index wage_real
			
			drop earn_avg_month_nom
		
		// merging with previous year's wages
		
		merge 1:1 plant_id cpf using "${data}/rais_m/rais_m`yymm'", keepusing(earn_avg_month_nom)
		keep if _merge == 3 // only who was matched
		drop _merge
		
		// adjusting wages
		
			replace year = year - 1
			
			merge m:1 year using "${input}/auxiliary/ipca_brazil"
			generate index_2017 = index if year == 2017
			egen index_base = max(index_2017)
			generate adj_index = index / index_base		
			generate wage_real_l12 = earn_avg_month_nom / adj_index
					
			// in logs
			gen wage_real_l12_ln = ln(wage_real_l12)
					
			drop if _merge == 2
			drop _merge index index_2017 index_base adj_index wage_real_l12
			
			drop earn_avg_month_nom
			drop year
				
		// calculating delta wages
		gen wage_delta = wage_real_ln - wage_real_l12_ln
		
		// collapsing at the firm level
		
		collapse (mean) mean_wage_delta=wage_delta ///
			(median) median_wage_delta=wage_delta, ///
			by(plant_id muni cnae20_class)
		
		gen ym = `ym'
		format ym %tm
		
		order plant_id ym mean_wage_delta median_wage_delta muni cnae20_class
		sort plant_id
		
		// for some reason, in the same month, some plants do not have unique municipalities and industries
		// i will drop these plants
		
		duplicates tag plant_id ym, generate(dupli)
		
			// listing these firms so I can drop them in the end from all months
			
			preserve
			
				keep if dupli != 0
				keep plant_id
				duplicates drop plant_id, force
				save "${temp}/duplicates_m`ym'", replace
			
			restore
		
		drop if dupli != 0
		drop dupli
		
		save "${data}/wagegrowth_m/wagegrowth_m`ym'", replace
			
	}
	
	// appending all duplicates
	
	clear
	
	forvalues ym=552/695 {
		
		append using "${temp}/duplicates_m`ym'"	
		
	}
	
	egen unique = tag(plant_id)
	keep if unique == 1
	drop unique
	
	save "${temp}/duplicates", replace
	
	// removing duplicates from all years
	
	forvalues ym=552/695 {
	
		use "${data}/wagegrowth_m/wagegrowth_m`ym'", clear
		
		merge 1:1 plant_id using "${temp}/duplicates"
		keep if _merge == 1
		drop _merge
		
		save "${data}/wagegrowth_m/wagegrowth_m`ym'", replace
	
	}
	
	
	// merging with firm size data set
	
	forvalues ym=552/695 {
	
		use "${data}/wagegrowth_m/wagegrowth_m`ym'", clear
		
		// firm size data set
		merge 1:1 plant_id using "${data}/plantsize_m/plantsize_m`ym'", keepusing(n_emp_lavg)
		drop if _merge == 2
		drop _merge
		
		// microregion (RGI) data set
		merge m:1 muni using "${input}/auxiliary/georegions", keepusing(rgi)
		drop if _merge == 2
		drop _merge
		
		// creating 2-digit industry
		tostring cnae20_class, gen(cnae20_class_str) format(%05.0f)
		gen cnae20_2d = substr(cnae20_class_str, 1, 2)
		destring cnae20_2d, replace
		drop cnae20_class_str
		
		// organize
		order plant_id ym n_emp_lavg muni rgi cnae20_class cnae20_2d
		sort plant_id 
		
		// saving
		save "${data}/wagegrowth_m/wagegrowth_m`ym'", replace
		
	}
	
	// collapsing
	
	forvalues ym=552/695 {
	
		use "${data}/wagegrowth_m/wagegrowth_m`ym'", clear

		// 1st collapse: firms with 20+ employees, microregion
		
		preserve
		
			keep if n_emp_lavg >= 20
			collapse (mean) mean_wage_delta_rgi20=mean_wage_delta ///
					median_wage_delta_rgi20=median_wage_delta, by(rgi ym)
			save "${temp}/wagegrowth_m`ym'_rgi20", replace
		
		restore
		
		// 2nd collapse: firms with 20+ employees, LLM
		
		preserve
		
			keep if n_emp_lavg >= 20
			collapse (mean) mean_wage_delta_llm20=mean_wage_delta ///
					median_wage_delta_llm20=median_wage_delta, by(rgi cnae20_2d ym)
			save "${temp}/wagegrowth_m`ym'_llm20", replace
		
		restore
		
		// 3rd collapse: firms with 50+ employees, microregion
		
		preserve
		
			keep if n_emp_lavg >= 50
			collapse (mean) mean_wage_delta_rgi50=mean_wage_delta ///
					median_wage_delta_rgi50=median_wage_delta, by(rgi ym)
			save "${temp}/wagegrowth_m`ym'_rgi50", replace
		
		restore

		// 4th collapse: firms with 50+ employees, LLM
		
		preserve
		
			keep if n_emp_lavg >= 50
			collapse (mean) mean_wage_delta_llm50=mean_wage_delta ///
					median_wage_delta_llm50=median_wage_delta, by(rgi cnae20_2d ym)
			save "${temp}/wagegrowth_m`ym'_llm50", replace
		
		restore
		
	}
	
	// appending
	
	foreach l in rgi20 llm20 rgi50 llm50 {
	
		clear
		forvalues ym=552/695 {
		append using "${temp}/wagegrowth_m`ym'_`l'"		
		}
		save "${data}/wagegrowth_m/wagegrowth_m_`l'", replace
	
	}
	
	// merging back with the firm-level data set
	
	forvalues ym=552/695 {
		
		use "${data}/wagegrowth_m/wagegrowth_m`ym'", clear
					
		merge m:1 rgi ym using "${data}/wagegrowth_m/wagegrowth_m_rgi20"
		drop if _merge == 2
		drop _merge
				
		merge m:1 rgi cnae20_2d ym using "${data}/wagegrowth_m/wagegrowth_m_llm20"
		drop if _merge == 2
		drop _merge
				
		merge m:1 rgi ym using "${data}/wagegrowth_m/wagegrowth_m_rgi50"
		drop if _merge == 2
		drop _merge
		
		merge m:1 rgi cnae20_2d ym using "${data}/wagegrowth_m/wagegrowth_m_llm50"
		drop if _merge == 2
		drop _merge
		
		// calculating "improvers" indicator
		
		foreach l in rgi20 llm20 rgi50 llm50 {
			
			// using mean
			gen improv_mean_`l'  = (mean_wage_delta > mean_wage_delta_`l') 
			replace improv_mean_`l' = . if (mean_wage_delta == . | mean_wage_delta_`l' == .)
			
			// using median
			gen improv_median_`l' = (median_wage_delta > median_wage_delta_`l') 
			replace improv_median_`l' = . if (median_wage_delta == . | median_wage_delta_`l' == .) 
						
		}
		
		// labeling variables
		
		label var ym "Year-Month"
		label var n_emp_lavg "Avg. # Employees (Prev. 3 Years)"
		label var cnae20_2d "Industry Class (CNAE 2.0) - 2 Digits"
		label var mean_wage_delta "Mean Wage Growth of Stayers - Plant"
		label var mean_wage_delta_rgi20 "Mean Wage Growth of Stayers - RGI, 20+ Emp."
		label var mean_wage_delta_llm20 "Mean Wage Growth of Stayers - RGIxInd, 20+ Emp."
		label var mean_wage_delta_rgi50 "Mean Wage Growth of Stayers - RGI, 50+ Emp."
		label var mean_wage_delta_llm50 "Mean Wage Growth of Stayers - RGIxInd, 50+ Emp."
		label var median_wage_delta "Median Wage Growth of Stayers - Plant"
		label var median_wage_delta_rgi20 "Median Wage Growth of Stayers - RGI, 20+ Emp."
		label var median_wage_delta_llm20 "Median Wage Growth of Stayers - RGIxInd, 20+ Emp."
		label var median_wage_delta_rgi50 "Median Wage Growth of Stayers - RGI, 50+ Emp."
		label var median_wage_delta_llm50 "Median Wage Growth of Stayers - RGIxInd, 50+ Emp."
		label var improv_mean_rgi20 "Improver Plant (Mean, RGI, 20+ Emp.)"
		label var improv_mean_llm20 "Improver Plant (Mean, RGIxInd, 20+ Emp.)"
		label var improv_mean_rgi50 "Improver Plant (Mean, RGI, 50+ Emp.)"
		label var improv_mean_llm50 "Improver Plant (Mean, RGIxInd, 50+ Emp.)"
		label var improv_median_rgi20 "Improver Plant (Median, RGI, 20+ Emp.)"
		label var improv_median_llm20 "Improver Plant (Median, RGIxInd, 20+ Emp.)"
		label var improv_median_rgi50 "Improver Plant (Median, RGI, 50+ Emp.)"
		label var improv_median_llm50 "Improver Plant (Median, RGIxInd, 50+ Emp.)"
		
		// saving
		save "${data}/wagegrowth_m/wagegrowth_m`ym'", replace
		
	}
	
*--------------------------*
* EXIT
*--------------------------*	

clear

forvalues ym=552/695 {
	
	cap rm "${temp}/duplicates_m`ym'.dta"
	cap rm "${temp}/wagegrowth_m`ym'_rgi20.dta"
	cap rm "${temp}/wagegrowth_m`ym'_llm20.dta"
	cap rm "${temp}/wagegrowth_m`ym'_rgi50.dta"
	cap rm "${temp}/wagegrowth_m`ym'_llm50.dta"
 	
}	
	
	
		

	
	
	
	
	
