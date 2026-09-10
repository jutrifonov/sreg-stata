version 14.2
clear all
set more off
set seed 20260910
set obs 240
generate block=ceil(_n/60)
generate assignment=mod(_n,3)
generate double baseline=rnormal()
generate double earnings=.5*(assignment==1)+.9*(assignment==2)+baseline+rnormal()
sreg earnings baseline, treatment(assignment) strata(block)
estimates store large
lincom tau2-tau1
test tau1 tau2
sregplot, treatmentlabels("Program A" "Program B") xtitle("ATE relative to control")

* Uniform triplets: 80 small strata, each containing all three arms.
generate triplet=ceil(_n/3)
sreg earnings baseline, treatment(assignment) strata(triplet) smallstrata
sreg, level(90)

* Mixed design: 60 triplets followed by one large stratum of 60 units.
generate mixedblock=cond(_n<=180,ceil(_n/3),61)
sreg earnings baseline, treatment(assignment) strata(mixedblock) smallstrata
matrix list e(b_small)
matrix list e(b_large)

* Cluster assignment. The cluster's population may exceed the sampled count.
clear
set obs 240
generate village=_n
generate block=ceil(_n/60)
generate assignment=mod(_n,3)
generate double baseline=rnormal()
generate population=10+mod(_n,7)
expand 3
generate double earnings=.5*(assignment==1)+.9*(assignment==2)+baseline+rnormal()
sreg earnings baseline, treatment(assignment) strata(block) ///
    cluster(village) clustersize(population)
