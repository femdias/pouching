// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Wage analysis 

*--------------------------*
* BUILD
*--------------------------*

// auxiliary data set: identifying events where the poached director stays in the new firm

	use "output/data/cowork_panel_m_rs_dir", clear
	
	// identifying the poached individuals among the coworkers
	
	bysort event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 1) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
	
		// test: do all events have a poached individual?
		*egen test = max(pc), by(event_id) // yes!
		
	// expanding for the entire individual and only keeping them
	
	egen pc_individual = max(pc), by(event_id cpf)
	keep if pc_individual == 1
	
	// employed in d_plant after the poaching in all months
	gen emp_d_plant = (plant_id == d_plant) & ym_rel >= 0
	egen total_emp_d_plant = sum(emp_d_plant), by(event_id cpf)
	
	// identifying these events
	collapse (max) total_emp_d_plant, by(event_id) 
	
	// saving
	save "temp/total_emp_d_plant", replace
	
// auxiliary data set: identifying events of interest, after imposing all sample restrictions

	use "output/data/evt_panel_m_rs_dir", clear

	// sample restrictions
	
		// dropping outlier events
		drop if event_id == 100 // hire thousands of employees; probably tranfers or reporting issue

		// keeping events with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25 & n_emp_pos < .
		
		// keeping events where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13 & total_emp_d_plant < .
		
	// listing events
	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id d_plant pc_ym
	
	save "temp/events", replace		
	
*--------------------------*
* USING PANEL OF COWORKERS
*--------------------------*

	use "output/data/cowork_panel_m_rs_dir", clear
	merge m:1 event_id using "temp/events", keep(match)
	drop _merge
	
	// team size variables
	
		// number of employees in t=-12
		
		bysort event_id ym: gen o_emp = _N
		gen o_emp_l12_temp = o_emp if ym_rel == -12
		egen o_emp_l12 = max(o_emp_l12_temp), by(event_id)
		
		// number of non-directors in t=-12
		
		gen o_emp_l12_nondir_temp = (ym_rel == -12 & dir == 0)
		egen o_emp_l12_nondir = sum(o_emp_l12_nondir_temp), by(event_id)
		
		// number of directors in t=-12
		
		gen o_emp_l12_dir_temp = (ym_rel == -12 & dir == 1)
		egen o_emp_l12_dir = sum(o_emp_l12_dir_temp), by(event_id)
		
		// avg team size
		
		gen o_teamsize_l12 = o_emp_l12_nondir / o_emp_l12_dir
	
	// wages variables
	
			// adjusting wages
			merge m:1 year using "input/Auxiliary/ipca_brazil"
			drop if _merge == 2
			drop _merge
			generate index_2008 = index if year == 2008
			egen index_base = max(index_2008)
			generate adj_index = index / index_base
			
			generate wage_real = earn_avg_month_nom / adj_index
		
			// in logs
			gen wage_real_ln = ln(wage_real)
		
	
		gen wage_0_temp = wage_real_ln if ym_rel == 0
		egen wage_0 = max(wage_0_temp), by(event_id cpf)
		
			// same variable, but not in logs
			gen wage_real_0_temp = wage_real if ym_rel == 0
			egen wage_real_0 = max(wage_real_0_temp), by(event_id cpf)
		
		gen wage_l12_temp = wage_real_ln if ym_rel == -12
		egen wage_l12 = max(wage_l12_temp), by(event_id cpf)
		
			// same variable, but no in logs
			gen wage_real_l12_temp = wage_real if ym_rel == -12
			egen wage_real_l12 = max(wage_real_l12_temp), by(event_id cpf)
			
	
	// identifying the poached individuals among the coworkers
	
	sort event_id cpf ym_rel
	by event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 1) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant) // 187
	egen pc_individual = max(pc), by(event_id cpf)
	
		// identifying the poached directors who continued as directors
		gen pc_dirindestination = (pc ==1) & (dir == 1) // 94
		egen pc_dirindestination_ind = max(pc_dirindestination), by(event_id cpf)
	 
	// only one observaton per poached individual
	keep if pc_individual == 1
	egen unique = tag(event_id cpf)
	keep if unique == 1
	
				// listing the poached directors -- we need this for another analysis
		
				preserve
		
				keep event_id cpf pc_individual pc_dirindestination_ind
				save "temp/poached_directors", replace
		
				restore
	
	// ANALYSIS 1. managers earn more after being poached
	
		twoway (kdensity wage_l12) ///
			(kdensity wage_0) 
			// curve shifts right!
			
		summ wage_l12 wage_0, detail // 18% increase (8.03 vs. 8.21)
		
		gen wage_delta = wage_0 - wage_l12
		summ wage_delta, detail // decreases
		gen wage_delta_pos = (wage_delta >0 & wage_delta < .)
		tab wage_delta_pos
		
				// saving list of wage_delta_pos -- we need this for another analysis
				
				preserve
						
				keep event_id wage_delta_pos
				collapse (max) wage_delta_pos, by(event_id)
				save "temp/wage_delta_pos", replace
						
				restore

	// ANALYSIS 2. the salary of a manager increases in the number of employees she oversaw
	// ANALYSIS 3. the salary of the poached manager is correlated with the quality of the subsequent poached coworkers
	// ANALYSIS 4. the salary of the poached manager increases in the number of poached workers
	
		// adding more variables for this analysis
		
			// controlling for destination plant_size
		
			preserve
			
				use "output/data/evt_panel_m_rs_dir", clear
				keep if ym_rel == 0
				keep event_id d_emp
				save "temp/d_emp", replace
			
			restore
		
			merge m:1 event_id using "temp/d_emp"
			drop if _merge == 2
			drop _merge
			
			// controlling for avg wages
			
			merge m:1 event_id using "temp/avg_wage"
			drop if _merge == 2
			drop _merge
			
			// controlling for experience
			
			gen exp = age - educ_years - 6
			
			// controlling for log firm size
			
			gen d_emp_ln = ln(d_emp)
			
			// team size in log
			
			gen o_teamsize_l12_ln = ln(o_teamsize_l12)
			
		merge m:1 event_id using "temp/wage_real_ln_cw"
		drop if _merge == 2
		drop _merge
		
		gen wage_real_ln_cw_0 = wage_real_ln_cw
		replace wage_real_ln_cw_0 = 0 if wage_real_ln_cw_0 == .
		gen dummy = (wage_real_ln_cw_0 == 0)
		
		replace total_pc_coworkers = 0 if total_pc_coworkers == .
		
		// regressions
		
		eststo clear
		
		// indep variable: team size
		
		binscatter wage_0 o_teamsize_l12_ln if o_teamsize_l12 < 1000 , control(exp avg_wage_plant d_emp_ln)  
		
		binscatter wage_0 wage_real_ln_cw_0 if o_teamsize_l12 < 1000 , control(exp dummy avg_wage_plant d_emp_ln)  
		
		eststo: reg wage_0 o_teamsize_l12_ln exp 			if o_teamsize_l12 < 1000, rob
			
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	""
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		
		/*
		eststo: reg wage_0 o_teamsize_l12_ln exp avg_wage_plant 	if o_teamsize_l12 < 1000, rob
		
			estadd local experience "YES"
			estadd local firmsize	""
			estadd local wagebill	"YES"
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		*/	
		

		eststo: reg wage_0 o_teamsize_l12_ln exp avg_wage_plant d_emp_ln 	if o_teamsize_l12 < 1000, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		
		// indep variable: raided coworkers' wage
		
		eststo: reg wage_0 wage_real_ln_cw_0 dummy exp 				if o_teamsize_l12 < 1000, rob
			
			estadd local experience "YES"
			estadd local firmsize	""
			estadd local wagebill	""
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		
		/*
		eststo: reg wage_0 wage_real_ln_cw_0 dummy exp avg_wage_plant 		if o_teamsize_l12 < 1000, rob
		
			estadd local experience "YES"
			estadd local firmsize	""
			estadd local wagebill	"YES"
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		*/
		

		eststo: reg wage_0 wage_real_ln_cw_0 dummy exp avg_wage_plant d_emp_ln 	if o_teamsize_l12 < 1000, rob
		
			estadd local experience "YES"
			estadd local firmsize	"YES"
			estadd local wagebill	"YES"
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
			
		// indep variable: number of raided coworkers
		
			* in logs...
			*replace total_pc_coworkers = ln(total_pc_coworkers)
			*replace total_pc_coworkers = -99 if total_pc_coworkers == .
			
			* using a dummy...
			replace total_pc_coworker = (total_pc_coworker != -99)
			
			
			
		
		eststo: reg wage_0 total_pc_coworkers dummy exp 			if o_teamsize_l12 < 1000, rob
			
			estadd local experience "YES"
			estadd local firmsize	""
			estadd local wagebill	""
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		
		/*
		eststo: reg wage_0 total_pc_coworkers dummy exp avg_wage_plant 		if o_teamsize_l12 < 1000, rob
		
			estadd local experience "YES"
			estadd local firmsize	""
			estadd local wagebill	"YES"
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'
		*/
		

		eststo: reg wage_0 total_pc_coworkers dummy exp avg_wage_plant d_emp_ln 	if o_teamsize_l12 < 1000, rob
		
		
					reg wage_0 c.total_pc_coworkers##i.dummy exp avg_wage_plant d_emp_ln 	if o_teamsize_l12 < 1000, rob
		
		
		
					reg wage_0   ib1.cw_q exp avg_wage_plant d_emp_ln  , rob
					
					gen total_pc_ln = ln(total_pc_coworkers)
					xtile cw_q = total_pc_coworkers, nq(4)
		
			estadd local experience "YES"
			estadd local firmsize	"YES"
			estadd local wagebill	"YES"
			
			summ wage_real_0 if o_teamsize_l12 < 1000
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_plant if o_teamsize_l12 < 1000
			estadd scalar avg_wage_plant_avg = `r(mean)'	
		
		* build residualized measure
		egen meanwage = mean(wage_real_0)
		reg wage_real_0 exp avg_wage_plant d_emp_ln , rob
		predict resid, resid
		egen _wage = rsum(meanwage resid) 
		graph bar (mean) wage_real_0, over(tookany, relabel(1 "No co-poaching"  2 "At least one co-poaching")) ///
			bar(1, fcolor(gs13) lcolor(black))  blabel(bar) ///
			ytitle("Mean of real wage (R$)") graphregion(lcolor(white)) plotregion(lcolor(white))
		
		/*	
		esttab using "output/results/tab_wage.tex", tex ///
			replace frag compress noconstant nomtitles nogap collabels(none) ///
			keep(o_teamsize_l12_ln wage_real_ln_cw_0) ///
			cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
			coeflabels(o_teamsize_l12_ln "\hline \\ Ln(Team Size)" ///
			wage_real_ln_cw_0 "Avg[Ln(Wage Raided Coworkers)]") ///
			stats(N r2 wage_0_avg avg_wage_plant_avg experience wagebill firmsize , fmt(0 3 3 3 0 0 0) ///
			label("\\ Observations" "R-Squared" "Mean: Ln Wage Poached Mgr" "Mean: Avg. Ln Wage Bill" ///
			"\\ Yrs. Experience" "Avg. Ln Wage Bill"  "Ln Firm Size")) ///
			obslast nolines ///
			starlevels(* 0.1 ** 0.05 *** 0.01)
		*/
		
		esttab using "output/results/tab_wage_alt.tex", tex ///
			replace frag compress noconstant nomtitles nogap collabels(none) ///
			keep(o_teamsize_l12_ln wage_real_ln_cw_0 total_pc_coworkers) ///
			cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
			coeflabels(o_teamsize_l12_ln "\hline \\ Ln(Team Size)" ///
			wage_real_ln_cw_0 "Avg[Ln(Wage Raided Coworkers)]" ////
			total_pc_coworkers "\# Raided Coworkers") ///
			stats(N r2 wage_0_avg avg_wage_plant_avg experience wagebill firmsize , fmt(0 3 3 3 0 0 0) ///
			label("\\ Observations" "R-Squared" "Mean: Ln Wage Poached Mgr" "Mean: Avg. Ln Wage Bill" ///
			"\\ Yrs. Experience" "Avg. Ln Wage Bill"  "Ln Firm Size")) ///
			obslast nolines ///
			starlevels(* 0.1 ** 0.05 *** 0.01)
		
			
		   
		
		
		// salary in destination plant
	
	/*
		gen o_emp_l12_ln = ln(o_emp_l12)
		binscatter wage_0 o_emp_l12_ln
		reg wage_0 o_emp_l12_ln // TRUE BUT NON-SIGNIFICANT
		
		gen o_emp_l12_nondir_ln = ln(o_emp_l12_nondir)
		binscatter wage_0 o_emp_l12_nondir_ln
		reg wage_0 o_emp_l12_nondir_ln // TRUE BUT NON-SIGNIFICANT
		
	*/	
		
		
		binscatter wage_0 o_teamsize_l12_ln
		reg wage_0 o_teamsize_l12_ln // TRUE & SIGNIFICANT ---> FAZER PARA D_PLANT
		
			
		binscatter wage_0 o_teamsize_l12_ln  if o_teamsize_l12 < 1000, control(d_emp_ln avg_wage_plant exp) reportreg
		reg wage_0 o_teamsize_l12_ln d_emp_ln avg_wage_plant exp if o_teamsize_l12 < 1000, rob
		summ o_teamsize_l12 if o_teamsize_l12 < 1000, detail
			
			
		// using destination team size
		gen d_teamsize_0_ln = ln(d_teamsize_0)
		summ d_teamsize_0 , detail
		binscatter wage_0 d_teamsize_0_ln
		binscatter wage_0 d_teamsize_0_ln if o_teamsize_l12 < 1000, control(avg_wage_plant exp d_emp_ln) reportreg
		binscatter wage_0 d_teamsize_0_ln, control(d_emp_ln avg_wage_plant exp) reportreg
		reg wage_0 d_teamsize_0_ln d_emp_ln avg_wage_plant exp, rob	
		
		
		
		
	


		
		binscatter wage_0 wage_real_ln_cw_0, control(avg_wage_plant d_emp_ln exp dummy) reportreg
		
	// 	
		
*--------------------------*
* USING D_PLANT IN T=0
*--------------------------*


/*
	use "output/data/rais_m_rs", clear
	
	rename ym pc_ym
	rename plant_id d_plant
	merge m:1 d_plant pc_ym using "temp/events", keep(match)
	drop _merge
	
	// identify poached directors
	merge 1:1 event_id cpf using "temp/poached_directors"
	drop _merge
	replace pc_individual = 0 if pc_individual == .
	replace pc_dirindestination_ind = 0 if pc_dirindestination_ind == .
	
		// saving temp file
		save "temp/temp_wage_dir", replace
		
		*/
		
		// using the temp file
		use "temp/temp_wage_dir", clear
		
	// adjusting wages
	
		merge m:1 year using "input/Auxiliary/ipca_brazil"
		generate index_2008 = index if year == 2008
		egen index_base = max(index_2008)
		generate adj_index = index / index_base		
		generate wage_real = earn_avg_month_nom / adj_index
		
		// in logs
		gen wage_real_ln = ln(wage_real)
		
		drop if _merge == 2
		drop _merge
		
	// calculating experience
	gen experience = age - educ_years - 6
	
	// sample for this analysis: only those in similar occupations as the poached managers
		
	*gen occup_1digit = substr(occup_cbo2002,1,1)
	gen occup_2digit = substr(occup_cbo2002,1,2)
	*gen occup_3digit = substr(occup_cbo2002,1,3)
		
	*egen sample_1digit = max(pc_individual), by(event_id occup_1digit)
	egen sample_2digit = max(pc_individual), by(event_id occup_2digit)
	*egen sample_3digit = max(pc_individual), by(event_id occup_3digit)
	
	/*
					// calculate average wage
					preserve
					
					egen avg_wage_1digit_t = mean(wage_real_ln) if sample_1digit == 1 & pc_individual == 0, by(event_id)
					egen avg_wage_1digit = max(avg_wage_1digit_t), by(event_id)
					

					egen avg_wage_plant_t = mean(wage_real_ln) if pc_individual == 0, by(event_id)
					egen avg_wage_plant = mean(avg_wage_plant_t) , by(event_id)
					
			
					// include team size variables
					
					// number of employees in t=0
	
					bysort event_id: gen d_emp_0 = _N
				
					// number of non-directors in t=0
					
					gen d_emp_0_nondir_temp = (dir == 0)
					egen d_emp_0_nondir = sum(d_emp_0_nondir_temp), by(event_id)
					
					// number of directors in t=0
					
					gen d_emp_0_dir_temp = (dir == 1)
					egen d_emp_0_dir = sum(d_emp_0_dir_temp), by(event_id)
					
					// avg team size
					
					gen d_teamsize_0 = d_emp_0_nondir / d_emp_0_dir
			
			
			
			
					// saving data set
			
			
					egen unique = tag(event_id)
					keep if unique == 1
					keep event_id avg_wage_1digit avg_wage_plant d_teamsize_0 d_emp_0_nondir d_emp_0_dir
					
					
					
					
					
					save "temp/avg_wage", replace
					
					
					restore
		*/			
					
					
					
					
		
		// regressions
		*areg wage_real_ln pc_individual experience if sample_1digit == 1, absorb(event_id)
		reg wage_real_ln pc_individual if sample_2digit == 1, rob
		areg wage_real_ln pc_individual experience if sample_2digit == 1, absorb(event_id) 
		*areg wage_real_ln pc_individual experience if sample_3digit == 1, absorb(event_id) // they earn 16% more!!!
	
	// column (2)
	
		reg wage_real_ln pc_individual if pc_individual == 1 | dir == 1, rob
		areg wage_real_ln pc_individual exp if pc_individual == 1 | dir == 1, absorb(event_id)
	
	
	// more restrictive sample
	// (those who were directors & continue before being poached and those who are directors now
		
	egen event_dirindestination = max(pc_dirindestination_ind), by(event_id)
	gen sample_dirindest = (event_dirindestination == 1 & dir == 1)
		
		reg wage_real_ln pc_individual if sample_dirindest == 1, rob
		areg wage_real_ln pc_individual experience if sample_dirindest == 1, absorb(event_id) // they earn 20% more
		
		
	// compare with other hired workers
	
			gen hire = (type_of_hire == 2)
			gen hire_ym = ym(hire_year, hire_month)
			gen all_hired = ((pc_ym == hire_ym) & (hire_ym != .) & (hire == 1)) 
			
		areg wage_real_ln pc_individual experience if all_hired ==1 & sample_1digit == 1, absorb(event_id) 
		areg wage_real_ln pc_individual experience if all_hired ==1 & sample_2digit == 1, absorb(event_id)
		areg wage_real_ln pc_individual experience if all_hired ==1 & sample_3digit == 1, absorb(event_id) // they earn 26% more
		
		
		
		
		
		
		
