// Poaching Project
// Created by: Felipe Macedo Dias
// (fm469@cornell.edu; fem.dias@hotmail.com)
// Date created: April 2025

// Purpose: Classify firms according to AKM FE of periods 2003-08 and 2009-2017


* Opening first dataset (2003-2008) and renaming fe_firm column
use "${AKM}/AKM_2003_2008_Firm.dta", clear
rename fe_firm fe_firm_03_08

* Merging with second dataset (2009-2017)
merge 1:1 firm_id using "${AKM}/AKM_2009_2017_Firm.dta", keep(match) nogenerate

* Rename fe_firm in 2009-2017 dataset
rename fe_firm fe_firm_09_17

* Calculating medians for both periods
sum fe_firm_03_08, detail
local median_03_08 = r(p50)

sum fe_firm_09_17, detail
local median_09_17 = r(p50)

* Creating indicators for high/low classification in each period
gen high_03_08 = (fe_firm_03_08 > `median_03_08') if !missing(fe_firm_03_08)
gen high_09_17 = (fe_firm_09_17 > `median_09_17') if !missing(fe_firm_09_17)

* Creating AKM classification
gen AKM_classification = .
replace AKM_classification = 1 if high_03_08 == 1 & high_09_17 == 1 // high-high
replace AKM_classification = 2 if high_03_08 == 1 & high_09_17 == 0 // high-low
replace AKM_classification = 3 if high_03_08 == 0 & high_09_17 == 1 // low-high
replace AKM_classification = 4 if high_03_08 == 0 & high_09_17 == 0 // low-low

// must be 50/50
tab high_03_08, missing
tab high_09_17, missing

* Adding value labels
label define akm_class 1 "High-High" 2 "High-Low" 3 "Low-High" 4 "Low-Low"
label values AKM_classification akm_class

* Creating variable label
label variable AKM_classification "AKM firm FE classification (2003-08 / 2009-17)"

* Displaying distribution
tab AKM_classification, missing

* Dropping dummies not used
drop high_03_08 high_09_17

* Saving merged dataset
save "${data}/AKM_merged_classified.dta", replace


