version 14.2
clear all
set more off
set linesize 255
adopath ++ "ado"
quietly do ado/sreg_mata.mata
// Same helper as estimation: check both classification and diagnostic content.
local sreg_warnings
mata: assert(sreg_classify((2\4\5\6),.)==(1\0\0\0))
assert "`sreg_warnings'"=="Mixed design detected: at least 25% of all strata have the same size (k = 2). Weighted estimators will be used. | "
local sreg_warnings
mata: assert(sreg_classify((3\3\3\3\8),.)==(1\1\1\1\0))
assert "`sreg_warnings'"=="Mixed design detected: at least 25% of all strata have the same size (k = 3). Weighted estimators will be used. | "
quietly log using ".build/classifier-error.log", text replace name(classifier)
capture noisily mata: sreg_classify((2\4\5\6\7),.)
local rc = _rc
quietly log close classifier
assert `rc'==498
// R generator diagnostic assertions: require both the reason and return code.
matrix badallocation = J(4,3,1/3)
local cases `""n(100) strata(5) individual tau(.5 .8) allocation(badallocation)" "n(100) strata(5) individual tau(.5 .8) stratumeffects(1 2 3 4)" "n(100) strata(5) tau(.5 .8) stratumeffects(0 0 0 0 0)" "n(120) mixedstrata nsmall(91)" "n(30) strata(10) tau(.2 .8) mixedstrata nsmall(15)" "n(120) tau(.2 .8) mixedstrata nsmall(90) treatsizes(1 1)""'
local j 0
foreach opts of local cases {
    local ++j
    quietly log using ".build/generator-error-`j'.log", text replace name(generator)
    capture noisily sreg_rgen, `opts' clear
    local rc = _rc
    quietly log close generator
    assert `rc'==198
}
// Numeric inputs replace R list/data-frame containers; reject wrong native types.
foreach variable in Y S D G_id Ng x1 {
    clear
    set obs 12
    gen double Y=_n
    gen double S=ceil(_n/6)
    gen double D=mod(_n,2)
    gen double G_id=_n
    gen double Ng=10
    gen double x1=_n^2
    drop `variable'
    gen str8 `variable'="bad"
    quietly log using ".build/container-`variable'.log", text replace name(container)
    capture noisily sreg Y x1, treatment(D) strata(S) cluster(G_id) clustersize(Ng)
    local rc = _rc
    quietly log close container
    assert `rc'==109
}
// Native API derives arm count, eliminating R's inconsistent n.treat argument.
sreg_rgen, n(60) individual tau(.2 .8) clear
assert r(N_treatments)==2
// Explicit native defaults reproduce the default generator path.
set seed 11
sreg_rgen, n(30) individual clear
mata: defaults=st_data(.,.)
set seed 11
sreg_rgen, n(30) individual strata(10) nmax(50) tau(0) gamma(.4 .2 1) clear
mata: assert(defaults==st_data(.,.))
file open done using ".build/assertions.done", write replace
file write done "passed"
file close done
