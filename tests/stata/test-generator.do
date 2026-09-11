version 14.2
clear all
set more off
adopath ++ "ado"
set seed 2026
// test-rgen-mixed.R: individual and cluster mixed structure and integration.
foreach cl in individual clustered {
    local opt
    if "`cl'" == "individual" local opt individual
    set seed 2026
    sreg_rgen, n(120) tau(.2 .8) strata(4) mixedstrata nsmall(90) k(3) treatsizes(1 1 1) `opt' clear
    assert r(N_units)==120
    assert r(n_small)==90
    if "`cl'" == "clustered" {
        bysort G_id: assert S==S[1] & D==D[1] & Ng==_N
        egen tag = tag(G_id)
        count if tag
        assert r(N)==120
        bysort S: egen units = total(tag)
        bysort S D: egen arm = total(tag)
        assert arm==1 if S<=30
        assert units==3 if S<=30
        egen stag = tag(S)
        count if stag & units==3
        assert r(N)==30
        count if stag & units>3
        assert r(N)>0
        drop tag units arm stag
        quietly sreg Y, treatment(D) strata(S) cluster(G_id) clustersize(Ng) smallstrata k(3)
    }
    else {
        assert _N==120
        bysort S: assert _N==3 if S<=30
        bysort S D: assert _N==1 if S<=30
        bysort S: gen units=_N
        egen stag = tag(S)
        count if stag & units==3
        assert r(N)==30
        count if stag & units>3
        assert r(N)>0
        drop units stag
        quietly sreg Y, treatment(D) strata(S) smallstrata k(3)
    }
    assert "`e(design)'"=="mixed design"
}
// Default mixed allocation distributes remainder to control first.
sreg_rgen, n(60) strata(3) individual mixedstrata nsmall(42) clear
bysort S D: assert _N==cond(D==0,2,1) if S<=14
// Original validation cases plus native-specific protection.
foreach options in "n(120) nsmall(91)" "n(30) strata(10) nsmall(15)" "n(120) nsmall(90) treatsizes(1 1)" {
    capture sreg_rgen, `options' tau(.2 .8) mixedstrata clear
    assert _rc==198
}
// Identical default path on repeating the same seed (R explicit FALSE / NULL equivalents).
set seed 11
sreg_rgen, n(300) individual tau(.5 .8) strata(5) clear
mata: baseline = st_data(.,.)
set seed 11
sreg_rgen, n(300) individual tau(.5 .8) strata(5) clear
mata: assert(baseline==st_data(.,.))
// test-rgen-large-custom.R: fixed active-arm counts, control remainder.
matrix P = (.6,.2,.2 \ .5,.3,.2 \ .34,.33,.33 \ .2,.3,.5 \ .2,.2,.6)
set seed 30
sreg_rgen, n(3000) individual strata(5) tau(.5 .8) allocation(P) clear
bysort S: gen size = _N
forvalues a=1/2 {
    bysort S: egen na = total(D==`a')
    forvalues s=1/5 {
        assert na==floor(size*P[`s',`a'+1]) if S==`s'
    }
    drop na
}
// Exact outcome shifts with shared within-Stata randomness.
set seed 91
sreg_rgen, n(600) individual strata(5) tau(.5 .8) clear
mata: baseline = st_data(.,("Y","S","D"))
matrix T = (-1.5,2.4 \ -.5,1.6 \ .5,.8 \ 1.5,0 \ 2.5,-.8)
set seed 91
sreg_rgen, n(600) individual strata(5) tau(.5 .8) stratumeffects(-2 -1 0 1 2) treatmenteffects(T) clear
mata: st_addvar("double","original"); st_store(.,"original",baseline[.,1]); assert(baseline[.,2..3]==st_data(.,("S","D")))
gen double shift = S-3
forvalues a=1/2 {
    forvalues s=1/5 {
        replace shift = shift+T[`s',`a']-cond(`a'==1,.5,.8) if S==`s' & D==`a'
    }
}
assert abs(Y-original-shift)<1e-12
matrix bad = J(4,3,1/3)
foreach options in "allocation(bad)" "stratumeffects(1 2 3 4)" "treatmenteffects(bad)" {
    capture sreg_rgen, n(600) individual strata(5) tau(.5 .8) `options' clear
    assert _rc==198
}
capture sreg_rgen, n(600) strata(5) stratumeffects(1 2 3 4 5) clear
assert _rc==198
// Shape checking replaces internal R n.treat/theta/pi length mismatches.
foreach options in "n(0)" "n(30) k(0)" "n(30) strata(0)" "n(30) nmax(15)" "n(31) smallstrata tau(.2 .8)" "n(30) smallstrata" "n(30) tau(.)" "n(30) gamma(1 2)" "n(30) mixedstrata smallstrata" "n(30) nsmall(9)" {
    capture sreg_rgen, `options' clear
    assert _rc!=0
}
// Invalid probability values, missing effects, and zero-count arms.
matrix bad = (0,1 \ .5,.5)
capture sreg_rgen, n(60) strata(2) individual allocation(bad) clear
assert _rc==198
matrix bad = (.5,.4 \ .5,.5)
capture sreg_rgen, n(60) strata(2) individual allocation(bad) clear
assert _rc==198
matrix bad = (.5,.5 \ .5,.)
capture sreg_rgen, n(60) strata(2) individual allocation(bad) clear
assert _rc==198
sreg_rgen, n(60) individual smallstrata tau(.2 .8) treatsizes(0 0 3) clear
assert D==2
// test-rgen-covariate-output.R: hiding cluster X must leave the DGP unchanged.
set seed 20260822
sreg_rgen, n(20) strata(2) tau(.5) clear
mata: baseline = st_data(.,("Y","S","D","G_id","Ng"))
confirm variable x_1 x_2
set seed 20260822
sreg_rgen, n(20) strata(2) tau(.5) nocovariates clear
capture confirm variable x_1
assert _rc==111
mata: assert(baseline==st_data(.,.))
// All six design paths, with and without reported covariates.
foreach cl in individual clustered {
    local opt
    if "`cl'"=="individual" local opt individual
    foreach design in large smallstrata mixedstrata {
        local des `design'
        if "`design'"=="large" local des
        foreach cov in yes no {
            local xc
            if "`cov'"=="no" local xc nocovariates
            sreg_rgen, n(120) strata(4) tau(.2 .8) `opt' `des' `xc' clear
            assert !missing(Y,S,D)
            assert inrange(D,0,2)
            if "`cov'"=="yes" confirm variable x_1 x_2
            else {
                capture confirm variable x_1
                assert _rc==111
            }
        }
    }
}
// General k-tuples and more than two active arms.
foreach opt in individual clustered {
    local cl
    if "`opt'"=="individual" local cl individual
    sreg_rgen, n(100) tau(1 2 3) smallstrata k(5) treatsizes(2 1 1 1) `cl' clear
    if "`cl'"=="" {
        bysort G_id: keep if _n==1
    }
    bysort S: assert _N==5
    bysort S D: assert _N==cond(D==0,2,1)
}
// Empty large-stratum bins and a single cluster remain valid generator outputs.
sreg_rgen, n(1) strata(10) clear
assert S==1 & D==0 & Ng==_N
// Single-stratum custom shifts also require column-preserving indexing.
set seed 18
sreg_rgen, n(60) strata(1) individual clear
mata: baseline = st_data(.,"Y")
set seed 18
sreg_rgen, n(60) strata(1) individual stratumeffects(7) clear
mata: assert(max(abs(st_data(.,"Y")-baseline:-7))<1e-12)
// Independent R-reference binning and allocation multisets.
do .build/generator-reference.do
// Dataset and RNG preservation on rejected commands.
mata: baseline = st_data(.,.)
local rng `c(rngstate)'
capture sreg_rgen, n(10)
assert _rc==4
capture sreg_rgen, n(10) individual allocation(nonexistent) clear
assert _rc!=0
mata: assert(baseline==st_data(.,.))
assert "`rng'"=="`c(rngstate)'"
// Boundary regression: minimum cluster belongs to stratum 1, maximum to last.
mata: assert(sreg_rg_strata((-2\-1\0\1\2),4,1)==(1\1\2\3\4))
mata: assert(sreg_rg_strata(J(3,1,0),4,1)==J(3,1,1))
// Distribution checks: fixed seed, broad bounds, not R/Stata seed equality.
set seed 8721
sreg_rgen, n(30000) individual strata(5) tau(1) clear
quietly summarize x_1
assert abs(r(mean)-5)<.05 & abs(r(Var)-4)<.15
quietly summarize x_2
assert abs(r(mean)-2)<.03 & abs(r(Var)-1)<.06
gen double residual = Y-.2*x_1-x_2-D
quietly summarize residual
assert abs(r(mean))<.04 & abs(r(Var)-1.16)<.06
set seed 1729
sreg_rgen, n(3000) strata(5) tau(1) gamma(0 0 0) clear
bysort G_id: gen byte tag = _n==1
quietly summarize Ng if tag
assert abs(r(mean)-30)<1
forvalues size=10(10)50 {
    quietly count if tag & Ng==`size'
    assert abs(r(N)/3000-.2)<.03
}
quietly summarize Y if D==0
assert abs(r(mean))<.04 & abs(r(Var)-1)<.06
quietly summarize Y if D==1
assert abs(r(mean)-1)<.04 & abs(r(Var)-2)<.1
file open done using ".build/generator.done", write replace
file write done "passed" _n
file close done
