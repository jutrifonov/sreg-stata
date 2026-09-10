version 14.2
clear all
set more off
adopath ++ "ado"

* Analytic three-arm, one-stratum covariance. The shared control variance
* contributes 1.25/4 = .3125 to the off-diagonal under HC0.
input double Y D
1 0
2 0
3 0
4 0
2 1
4 1
6 1
8 1
1 2
4 2
7 2
10 2
end
sreg Y, treatment(D) nohc1
matrix actual=e(V)
matrix expected=(1.5625,.3125\.3125,3.125)
assert mreldif(actual,expected)<1e-12
assert abs(_b[tau1]-2.5)<1e-12
assert abs(_b[tau2]-3)<1e-12
sreg Y, treatment(D)
matrix actual=e(V)
matrix expected=expected*(12/9)
assert mreldif(actual,expected)<1e-12

* Analytic paired-strata cross-arm covariance. For this fixed dataset:
* V = C [diag(3*(sigma-diag(rho-mu*mu'))) + rho-mu*mu'] C'/12,
* C = (-1,1,0 \ -1,0,1), with same-arm rho from adjacent strata
* and different-arm rho from within-stratum products.
clear
input double S D Y
1 0 1
1 1 3
1 2 2
2 0 2
2 1 5
2 2 4
3 0 3
3 1 4
3 2 7
4 0 4
4 1 8
4 2 10
end
sreg Y, treatment(D) strata(S) smallstrata nohc1
matrix actual=e(V)
matrix expected=(1.0208333333333333,.15625\.15625,.9322916666666666)
assert mreldif(actual,expected)<1e-12
lincom tau2-tau1
assert abs(r(se)^2-(expected[1,1]+expected[2,2]-2*expected[1,2]))<1e-12

file open done using ".build/covariance.done", write replace
file write done "PASS"
file close done
exit, clear
