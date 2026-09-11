version 14.2
set seed 2026
sreg_rgen, n(600) individual strata(5) tau(.5 .8) clear
sreg Y x_1 x_2, treatment(D) strata(S)
sreg_rgen, n(120) tau(.2 .8) smallstrata clear
sreg Y x_1 x_2, treatment(D) strata(S) cluster(G_id) clustersize(Ng) smallstrata k(3)
matrix allocation = (.6,.2,.2 \ .5,.3,.2 \ .34,.33,.33 \ .2,.3,.5 \ .2,.2,.6)
sreg_rgen, n(3000) individual strata(5) tau(.5 .8) allocation(allocation) clear
sreg Y x_1 x_2, treatment(D) strata(S)
