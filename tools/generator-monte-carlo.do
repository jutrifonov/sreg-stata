version 14.2
clear all
set more off
adopath ++ "ado"
file open mc using ".build/generator-mc-stata.csv", write replace
file write mc "design,replicate,estimate,se" _n
foreach design in individual cluster {
    local opt individual
    local n 1200
    local clusteropts
    if "`design'"=="cluster" {
        local opt
        local n 200
        local clusteropts cluster(G_id) clustersize(Ng)
    }
    forvalues i=1/100 {
        local seed = 70000+`i'
        set seed `seed'
        quietly sreg_rgen, n(`n') strata(4) tau(.5) `opt' clear
        quietly sreg Y x_1 x_2, treatment(D) strata(S) `clusteropts'
        file write mc "`design',`i'," %24.17g (_b[tau1]) "," %24.17g (_se[tau1]) _n
    }
}
file close mc
file open done using ".build/generator-mc.done", write replace
file write done "passed"
file close done
