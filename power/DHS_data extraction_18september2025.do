********************************************************************************
*			HPV Pulse Vx
*			DHS data sourcing
*			HVH, 10 July 2025
*			Last update: EC, 18 September 2025
********************************************************************************

clear
version 18
set more off

*cd "/Users/veryharsh/Desktop/Ongoing projects/HPV-Pulse/"	
cd 	"C:\Users\clarem\switchdrive\BMGF CN pulse\06 Grant Planning\Power calculations"
	
*************************
* Cote d'Ivoire 2021
*************************	
****************************************** Individual recode (IR)
** FOR AGE AT SEXUAL DEBUT WOMEN
use v001 v002 v003 v012 v024 v025 v106 ///        
    v502 v527 v525 v531 v528 v501 v511 ///              
    s732 s735 s736a ///                       
    using "Data/DHS/CIIR81FL.DTA", clear

replace v525=99 if v525==0

tab v525
bys v024: tab v525

****************************************** Men's recode (MR)
** FOR AGE AT SEXUAL DEBUT MEN
use mv001 mv002 mv005 mv012 mv025 mv531 mv024	///
 using "Data/DHS/CIMR81FL.DTA", clear
replace mv531=99 if mv531==0
tab mv531
bys mv024: tab mv531

****************************************** Household member recode (PR)
use hv001 hv002 hvidx hv104 hv105 hv106 hv107 hv024 hv005 hv121 ///
    using "Data/DHS/CIPR81FL.DTA", clear
	
****************** define girls of secondary school age
gen eligible = inrange(hv105, 8, 14) & hv104 == 2

gen wgt = hv005/1000000
svyset [pw=wgt]

/*
gen enrolled_sec = hv106 >= 2 if eligible
svy: mean enrolled_sec if eligible
svy: mean enrolled_sec if eligible, over(hv024)
*/

// Enrolment (any) by age
gen enrolled = (hv121 == 2)
svyset [pw = wgt]
svy: mean enrolled if eligible
svy: mean enrolled if eligible, over(hv024)
svy: mean enrolled if eligible, over(hv105)
svy: mean enrolled if eligible & hv024==5, over(hv105)

loneway enrolled hv024 if eligible 
loneway enrolled hv001 if eligible 
loneway enrolled hv024 if hv105==8
loneway enrolled hv001 if hv105==8 
loneway enrolled hv024 if hv105==9
loneway enrolled hv001 if hv105==9 
loneway enrolled hv024 if hv105==10
loneway enrolled hv001 if hv105==10 
loneway enrolled hv024 if hv105==11
loneway enrolled hv001 if hv105==11 
loneway enrolled hv024 if hv105==12
loneway enrolled hv001 if hv105==12
loneway enrolled hv024 if hv105==13
loneway enrolled hv001 if hv105==13
loneway enrolled hv024 if hv105==14
loneway enrolled hv001 if hv105==14

// % completed primary by age
gen complete_prim = (hv106>=1 & hv106!=8)
replace complete_prim = . if hv106==8
svy: mean complete_prim, over(hv105)

loneway complete_prim hv024 if hv105==10
loneway complete_prim hv001 if hv105==10 
loneway complete_prim hv024 if hv105==11
loneway complete_prim hv001 if hv105==11 
loneway complete_prim hv024 if hv105==12
loneway complete_prim hv001 if hv105==12
loneway complete_prim hv024 if hv105==13
loneway complete_prim hv001 if hv105==13
loneway complete_prim hv024 if hv105==14
loneway complete_prim hv001 if hv105==14

// correlation over time in girls' primary school completion (cluster-level)
keep if hv104==2 
gen wt_prim = wgt*complete_prim 

preserve 
gen age10 = hv105==10
collapse (sum) wt_prim wgt ///
    if age10, by(hv001) 
rename (wt_prim wgt) (num1 den1)
tempfile age10
save `age10', replace
restore 

preserve 
gen age11 = hv105==11
collapse (sum) wt_prim wgt ///
    if age11, by(hv001) 
rename (wt_prim wgt) (num2 den2)
tempfile age11
save `age11', replace
restore 

preserve 
gen age12 = hv105==12
collapse (sum) wt_prim wgt ///
    if age12, by(hv001) 
rename (wt_prim wgt) (num3 den3)
tempfile age12
save `age12', replace
restore 

preserve
use `age10', clear
merge 1:1 hv001 using `age11'
drop _merge
merge 1:1 hv001 using `age12'
drop _merge

* Generate primary school completion by age group
gen prim1 = num1 / den1 // 10-year-olds
gen prim2 = num2 / den2 // 11-year-olds
gen prim3 = num3 / den3 // 12-year-olds

corr prim1 prim2
corr prim2 prim3
regress prim2 prim1 // R-squared = .1898
regress prim3 prim2 // R-squared = .0874
regress prim3 prim1 prim2 // R-squared .1524 
regress prim3 prim1 // R-squared .1025

keep prim1 prim2 prim3 hv001 
tempfile prim_bycluster 
save `prim_bycluster', replace
restore 

use hv001 hv002 hvidx hv104 hv105 hv106 hv107 hv024 hv005 hv121 ///
    using "Data/DHS/CIPR81FL.DTA", clear

merge m:1 hv001 using `prim_bycluster'

gen complete_prim = (hv106>=1 & hv106!=8)
replace complete_prim = . if hv106==8

regress complete_prim prim1 if hv105==11 & hv104==2 // regress 11-year-olds on cluster-level 10-year-olds; R-squared .0505
regress complete_prim prim2 if hv105==12 & hv104==2 // regress 12-year-olds on cluster-level 11-year-olds; R-squared .0506 

// correlation over time in primary school completion at the region level

use hv001 hv002 hvidx hv104 hv105 hv106 hv107 hv024 hv005 hv121 ///
    using "Data/DHS/CIPR81FL.DTA", clear

gen wgt = hv005/1000000
svyset [pw=wgt]
	
keep if hv104==2 

gen complete_prim = (hv106>=1 & hv106!=8)
replace complete_prim = . if hv106==8
gen wt_prim = wgt*complete_prim 

preserve 
gen age10 = hv105==10
collapse (sum) wt_prim wgt ///
    if age10, by(hv024) 
rename (wt_prim wgt) (num1 den1)
tempfile age10
save `age10', replace
restore 

preserve 
gen age11 = hv105==11
collapse (sum) wt_prim wgt ///
    if age11, by(hv024) 
rename (wt_prim wgt) (num2 den2)
tempfile age11
save `age11', replace
restore 

preserve 
gen age12 = hv105==12
collapse (sum) wt_prim wgt ///
    if age12, by(hv024) 
rename (wt_prim wgt) (num3 den3)
tempfile age12
save `age12', replace
restore 

preserve
use `age10', clear
merge 1:1 hv024 using `age11'
drop _merge
merge 1:1 hv024 using `age12'
drop _merge

* Generate primary school completion by age group (region-level)
gen prim1 = num1 / den1 // 10-year-olds
gen prim2 = num2 / den2 // 11-year-olds
gen prim3 = num3 / den3 // 12-year-olds

corr prim1 prim2
corr prim2 prim3
regress prim2 prim1 // R-squared = .6018
regress prim3 prim2 // R-squared = .6364
regress prim3 prim1 prim2 // R-squared .7272 
regress prim3 prim1 // R-squared .6545

keep prim1 prim2 prim3 hv024 
tempfile prim_byregion 
save `prim_byregion', replace
restore

* Regress individual-level primary school completion on region-level from previous 
use hv001 hv002 hvidx hv104 hv105 hv106 hv107 hv024 hv005 hv121 ///
    using "Data/DHS/CIPR81FL.DTA", clear
	
merge m:1 hv024 using `prim_byregion'

gen complete_prim = (hv106>=1 & hv106!=8)
replace complete_prim = . if hv106==8

regress complete_prim prim1 if hv105==11 & hv104==2 // regress 11-year-olds on region-level 10-year-olds; R-squared .0505
regress complete_prim prim2 if hv105==12 & hv104==2 // regress 12-year-olds on region-level 11-year-olds; R-squared .0506 


****************************************** Children's recode (KR)
use v001 v002 bidx b4 b8 b19 v022 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear

***************** check for DTP3 coverage levels
keep if inrange(b19, 12, 23)
gen dtp3_covered = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
svyset [pw=wgt], psu(v001) strata(v022)
svy: mean dtp3_covered
svy: mean dtp3_covered, over(v024)

loneway dtp3_covered v001 if inrange(b19, 12, 23)
loneway dtp3_covered v024 if inrange(b19, 12, 23)

****************** check for correlation over time at cluster level
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear
label list V024
*keep if v024==13
gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if inrange(b8, 1, 2)
gen age1 = (b8 == 1)
gen age2 = (b8 == 2)

gen wt_dtp3 = dtp3 * wgt

* Collapse to numerator and denominator per cluster and age group
collapse (sum) wt_dtp3 wgt ///
    if age1, by(v001) 
rename (wt_dtp3 wgt) (num1 den1)

tempfile age1
save `age1', replace

* Repeat for other age groups
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear
*keep if v024==13

gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000

keep if b8 == 2
gen wt_dtp3 = dtp3 * wgt

preserve 
collapse (sum) wt_dtp3 wgt, by(v001)
rename (wt_dtp3 wgt) (num2 den2)
tempfile age2
save `age2', replace

* MERGE
use `age1', clear
merge 1:1 v001 using `age2'
drop _merge

* Generate DTP3 coverage by age group
gen cov1 = num1 / den1
gen cov2 = num2 / den2

corr cov1 cov2 
regress cov1 cov2

keep cov1 cov2 v001 
tempfile coverage_cluster 
save `coverage_cluster', replace  
restore 

use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear

merge m:1 v001 using `coverage_cluster'

gen dtp3 = inlist(h7, 1, 2, 3)

regress dtp3 cov2 if b8==1 // explanatory power of cluster-level coverage among 2-year-olds for coverage among 1-year-olds

****************** check for correlation over time at regional level
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear
gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if inrange(b8, 1, 2)
gen age1 = (b8 == 1)
gen age2 = (b8 == 2)

gen wt_dtp3 = dtp3 * wgt

* Collapse to numerator and denominator per cluster and age group
collapse (sum) wt_dtp3 wgt ///
    if age1, by(v024) 
rename (wt_dtp3 wgt) (num1 den1)

tempfile age1
save `age1', replace

* Repeat for other age groups
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear
gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if b8 == 2
gen wt_dtp3 = dtp3 * wgt
collapse (sum) wt_dtp3 wgt, by(v024)
rename (wt_dtp3 wgt) (num2 den2)
tempfile age2
save `age2', replace

* MERGE
use `age1', clear
merge 1:1 v024 using `age2'
drop _merge

* Generate DTP3 coverage by age group
gen cov1 = num1 / den1
gen cov2 = num2 / den2
tempfile coverage_region

save `coverage_region'

corr cov1 cov2 
regress cov1 cov2 

use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/CIKR81FL.DTA", clear
gen dtp3 = inlist(h7, 1, 2, 3)
merge m:1 v024 using `coverage_region'

regress dtp3 cov2 if b8==1 // explanatory power of region-level coverage for individuals

// Admin coverage 

import delimited "Data/CIV_admin.csv" , varnames(1) clear
corr hpv1 penta3
regress hpv1 penta3 // r-squared .0382 
regress hpv2 penta3 // r-squared .0126 
sum hpv1, detail

*************************
* Zambia 2018
*************************
****************************************** Individual recode (IR)
use v001 v002 v003 v012 v024 v025 v106 ///        
    v502 v527 v525 v531 v528 v501 v511 ///              
    using "Data/DHS/ZMIR71FL.DTA", clear

replace v525=99 if v525==0

tab v525
bys v024: tab v525

save "Data/DHS/ZMIR71FL_cut.dta", replace

****************************************** Men's recode (MR)
** FOR AGE AT SEXUAL DEBUT MEN
use mv001 mv002 mv005 mv012 mv025 mv531 mv024	///
 using "Data/DHS/ZMMR71FL.DTA", clear
replace mv531=99 if mv531==0
tab mv531
bys mv024: tab mv531

****************************************** Household member recode (PR)
use hv001 hv002 hvidx hv104 hv105 hv106 hv107 hv024 hv005 hv121  ///
    using "Data/DHS/ZMPR71FL.DTA", clear
	
* define girls of secondary school age
gen eligible = inrange(hv105, 8, 14) & hv104 == 2
gen enrolled_sec = hv106 >= 2 if eligible
gen wgt = hv005/1000000
svyset [pw=wgt]
svy: mean enrolled_sec if eligible
svy: mean enrolled_sec if eligible, over(hv024)


// Enrolment by age
gen enrolled = (hv121 == 2)
svyset [pw = wgt]
svy: mean enrolled if eligible
svy: mean enrolled if eligible, over(hv024)
svy: mean enrolled if eligible, over(hv105)
svy: mean enrolled if eligible & hv024==4, over(hv105)


****************************************** Children's recode (KR)
use v001 v002 bidx b4 b8 b19 v022 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear

***************** check for DTP3 coverage levels
keep if inrange(b19, 12, 23)
gen dtp3_covered = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
svyset [pw=wgt], psu(v001) strata(v022)
svy: mean dtp3_covered
svy: mean dtp3_covered, over(v024)


****************** check for correlation at cluster level
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear
label list V024
	* keep only values for worst-performing region (Muchinga)
	*keep if v024==6

gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if inrange(b8, 1, 2)
gen age1 = (b8 == 1)
gen age2 = (b8 == 2)

gen wt_dtp3 = dtp3 * wgt

* Collapse to numerator and denominator per cluster and age group
collapse (sum) wt_dtp3 wgt ///
    if age1, by(v001) 
rename (wt_dtp3 wgt) (num1 den1)

tempfile age1
save `age1', replace

* Repeat for other age groups
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear
	*keep if v024==6

gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if b8 == 2
gen wt_dtp3 = dtp3 * wgt

preserve
collapse (sum) wt_dtp3 wgt, by(v001)
rename (wt_dtp3 wgt) (num2 den2)
tempfile age2
save `age2', replace

* MERGE
use `age1', clear
merge 1:1 v001 using `age2'
drop _merge

* Generate DTP3 coverage by age group
gen cov1 = num1 / den1
gen cov2 = num2 / den2

corr cov1 cov2 
regress cov1 cov2 // R-squared: .1301

keep cov1 cov2 v001 
tempfile coverage_cluster 
save `coverage_cluster', replace  
restore 

use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear

merge m:1 v001 using `coverage_cluster'

gen dtp3 = inlist(h7, 1, 2, 3)

regress dtp3 cov2 if b8==1 // R-squared: .0933

****************** check for correlation at regional level
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear
gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if inrange(b8, 1, 2)
gen age1 = (b8 == 1)
gen age2 = (b8 == 2)

gen wt_dtp3 = dtp3 * wgt

* Collapse to numerator and denominator per cluster and age group
collapse (sum) wt_dtp3 wgt ///
    if age1, by(v024) 
rename (wt_dtp3 wgt) (num1 den1)

tempfile age1
save `age1', replace

* Repeat for other age groups
use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear
gen dtp3 = inlist(h7, 1, 2, 3)
gen wgt = v005 / 1000000
keep if b8 == 2
gen wt_dtp3 = dtp3 * wgt
collapse (sum) wt_dtp3 wgt, by(v024)
rename (wt_dtp3 wgt) (num2 den2)
tempfile age2
save `age2', replace


* MERGE
use `age1', clear
merge 1:1 v024 using `age2'
drop _merge

* Generate DTP3 coverage by age group
gen cov1 = num1 / den1
gen cov2 = num2 / den2

tempfile coverage_region
save `coverage_region', replace

corr cov1 cov2 // .8694

regress cov1 cov2 // .7559

use v001 v002 bidx b4 b8 b19 v024 v005 h7  ///
    using "Data/DHS/ZMKR71FL.DTA", clear
gen dtp3 = inlist(h7, 1, 2, 3)
merge m:1 v024 using `coverage_region'

regress dtp3 cov2 if b8==1 // explanatory power of region-level coverage for individuals
