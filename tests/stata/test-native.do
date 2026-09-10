version 14.2
clear all
set more off
set type double
adopath ++ "ado"

* Primary syntax, legacy equivalence, replay, covariates and normal inference.
import delimited using ".build/fixtures/case-0011.csv", clear case(preserve) asdouble
sreg Y x1 x2, treatment(D) strata(S)
matrix b0=e(b)
matrix v0=e(V)
matrix t0=r(table)
assert e(N)==_N
assert e(adjusted)==1
assert "`e(design)'"=="large strata"
assert "`e(cmd)'"=="sreg"
assert e(HC1)==1
assert colsof(b0)==2
assert e(sample)==1
estimates store original
lincom tau2-tau1
assert abs(r(estimate)-(b0[1,2]-b0[1,1]))<1e-12
assert abs(r(se)^2-(v0[1,1]+v0[2,2]-2*v0[1,2]))<1e-12
test tau1 tau2
assert r(df)==2
sreg, level(90)
matrix t90=r(table)
assert abs(t90[5,1]-(b0[1,1]-invnormal(.95)*sqrt(v0[1,1])))<1e-12
sreg, l(90)
sreg, y(Y) d(D) s(S) x(x1 x2) hc1(true)
mata: assert(mreldif(st_matrix("b0"),st_matrix("e(b)"))<1e-12)
mata: assert(mreldif(st_matrix("v0"),st_matrix("e(V)"))<1e-12)
sreg Y x1 x2, treatment(D) strata(S) nohc1
assert e(HC1)==0
mata: assert(mreldif(st_matrix("b0"),st_matrix("e(b)"))<1e-12)
assert _se[tau1]^2<v0[1,1]

* Expanded factor-variable basis is equivalent to explicit regressors.
gen byte category=mod(_n,2)
gen double x1sq=x1^2
sreg Y i.category c.x1##c.x1, treatment(D) strata(S)
matrix bf=e(b)
matrix vf=e(V)
sreg Y category x1 x1sq, treatment(D) strata(S)
mata: assert(mreldif(st_matrix("bf"),st_matrix("e(b)"))<1e-10)
mata: assert(mreldif(st_matrix("vf"),st_matrix("e(V)"))<1e-10)

* Complete cases, if/in and sample marking do not change the dataset.
replace Y=. in 1
replace x1=. in 2
sreg Y x1 x2 if _n<=900 in 1/950, treatment(D) strata(S)
assert e(N)==898
assert !e(sample) in 1/2
assert !e(sample) in 901/1000
assert strpos(`"`e(warnings)'"',"Missing observations omitted")>0
assert _N==1000
matrix bm=e(b)
preserve
keep if _n>=3 & _n<=900
sreg Y x1 x2, treatment(D) strata(S)
mata: assert(mreldif(st_matrix("bm"),st_matrix("e(b)"))<1e-12)
restore

* Native type/parser validation, corresponding to R container/type tests.
gen str8 bad="text"
foreach command in "sreg bad, treatment(D)" "sreg Y, treatment(bad)" ///
    "sreg Y bad, treatment(D)" "sreg Y, treatment(D) strata(bad)" ///
    "sreg Y, treatment(D) cluster(bad)" "sreg Y, treatment(D) cluster(S) clustersize(bad)" ///
    "sreg Y, treatment(D) k(0)" "sreg Y, treatment(D) k(2.5)" ///
    "sreg Y, treatment(D) clustersize(S)" "sreg Y, treatment(D) y(Y)" ///
    "sreg, d(D) x(x1)" "sreg Y" {
    capture `command'
    assert _rc!=0
}

* Cluster observation ordering and inferred sizes.
import delimited using ".build/fixtures/case-0003.csv", clear case(preserve) asdouble
sreg Y x1 x2, treatment(D) strata(S) cluster(G_id) clustersize(Ng) smallstrata
matrix bc=e(b)
matrix vc=e(V)
assert "`e(design)'"=="mixed design"
assert e(N_units)==600
assert e(N_small)==360
assert e(N_large)==240
assert e(p_small)>0 & e(p_small)<1
matrix cb=e(b_small)
matrix cl=e(b_large)
assert abs(_b[tau1]-(e(p_small)*cb[1,1]+(1-e(p_small))*cl[1,1]))<1e-12
set seed 183
gen double ordering=runiform()
sort ordering
sreg Y x1 x2, treatment(D) strata(S) cluster(G_id) clustersize(Ng) smallstrata
mata: assert(mreldif(st_matrix("bc"),st_matrix("e(b)"))<1e-10)
mata: assert(mreldif(st_matrix("vc"),st_matrix("e(V)"))<1e-10)
sreg Y x1 x2, treatment(D) strata(S) cluster(G_id) smallstrata
mata: assert(mreldif(st_matrix("bc"),st_matrix("e(b)"))<1e-10)
mata: assert(mreldif(st_matrix("vc"),st_matrix("e(V)"))<1e-10)

* Cluster consistency, positive sizes, and odd paired-stratum diagnostics.
replace D=99 in 1
capture sreg Y, treatment(D) strata(S) cluster(G_id) smallstrata
assert _rc!=0
clear
set obs 6
gen S=ceil(_n/2)
gen D=mod(_n,2)
gen Y=_n^2
capture sreg Y, treatment(D) strata(S) smallstrata
assert _rc!=0

* Plot output preserves data and stored estimation results.
estimates restore original
local before=_N
sregplot, treatmentlabels("Program A" "Program B") level(90) ///
    title("Native Stata sreg") xtitle("ATE relative to control") ///
    name(sreg_test, replace) saving(".build/sreg-test.gph", replace)
assert _N==`before'
mata: assert(mreldif(st_matrix("b0"),st_matrix("e(b)"))<1e-12)
mata: assert(mreldif(st_matrix("v0"),st_matrix("e(V)"))<1e-12)
graph export ".build/sreg-test.svg", replace
capture sregplot, treatmentlabels("Only one label")
assert _rc==198
sregplot, nogrid nozeroline cicolor(navy) mcolor(navy) mfcolor(white) ///
    msymbol(O) msize(small) labcolor(navy) labsize(small) bgcolor(white)

file open done using ".build/native.done", write replace
file write done "PASS"
file close done
file open info using ".build/stata-version.txt", write replace
file write info "`c(stata_version)'"
file close info
exit, clear
