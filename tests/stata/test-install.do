version 14.2
clear all
set more off
capture mkdir ".build/install"
sysdir set PLUS ".build/install"
net install sreg, from("`c(pwd)'") replace
which sreg
findfile sreg.ado
assert strpos(`"`r(fn)'"',".build/install")>0
which sregplot
findfile sreg_mata.mata
do examples/estimation.do
file open done using ".build/install.done", write replace
file write done "PASS"
file close done
exit, clear
