** Analysis of data from the CTC study to estimate ICC in HPV coverage
** Emma Clarke-Deelder
** Version: 28 August 2025

** Set-up

clear
version 18
set more off

cd 	"C:\Users\clarem\switchdrive\BMGF CN pulse\06 Grant Planning\Power calculations"

** Import data file

import delimited "Data/CTC_HPV_CIV_HH_main.csv", bindquote(strict) clear

** Explore variables

tab school 
codebook school // 1146 unique schools
codebook nzd // 149 unique EAs

unique school nzd // 1890 - imperfect overlap

tab vaccinated // 3% unclear?
tab cardseen // what does "YesBut" mean?
tab hpv_nowhy // ask for questionnaire
tab zd // same as nzd
tab nzd 
codebook nhh // 4778 unique households
tab arm 
tab girl918_age_ii // ages 9-18
tab schoolyn // 24% out of school
tab hpv_loc 
codebook hpv_loc // not clean?

** Calculate ICC

// keep youngest child in each HH to remove this level of clustering
sort nhh girl918_age_ii
by nhh: gen n_obs_hh = _n
keep if n_obs_hh ==1

// calculate ICC within age cohorts (zd-level)
gen hpvvx = 0 if vaccinated=="No"
replace hpvvx = 1 if vaccinated=="Yes"
tab hpvvx

mean hpvvx, over(girl918_age_ii)

loneway hpvvx zd  // 0.09 combining all age cohorts
loneway hpvvx zd if girl918_age_ii==9 // 0.14 among 9-year-olds
loneway hpvvx zd if girl918_age_ii==10 // 0.09 among 10-year-olds
loneway hpvvx zd if girl918_age_ii==11 // 0.11 among 11-year-olds
loneway hpvvx zd if girl918_age_ii==12 // 0.07 among 12-year-olds
loneway hpvvx zd if girl918_age_ii==13 // 0.10 among 13-year-olds
loneway hpvvx zd if girl918_age_ii==14 // 0.01 among 14-year-olds
loneway hpvvx zd if girl918_age_ii==15 // 0.24 among 15-year-olds
loneway hpvvx zd if girl918_age_ii==16 // 0.16 among 16-year-olds
loneway hpvvx zd if girl918_age_ii==17 // 0.40 among 17-year-olds
loneway hpvvx zd if girl918_age_ii==18 // 0.53 among 18-year-olds


loneway hpvvx zd if arm=="SCC" // 0.07 combining all age cohorts
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==9 // 0.15 among 9-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==10 // 0.02 among 10-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==11 // 0.07 among 11-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==12 // 0.04 among 12-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==13 // 0.07 among 13-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==14 // 0.00 among 14-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==15 // 0.24 among 15-year-olds
loneway hpvvx zd if arm=="SCC" & girl918_age_ii==16 // 0.00 among 16-year-olds


mean hpvvx, over(girl918_age_ii) cluster(zd)
mean hpvvx if arm=="SCC", over(girl918_age_ii) cluster(zd)
