# R-to-Stata coverage

Every original R test is retained unchanged and passes in the reference run.
The table distinguishes replayed estimator calls, direct native helper tests,
and native generator design/distribution translations. It does not
claim a literal Stata translation of every R assertion or output string.

The generated parity suite verifies numerical inference, warnings and output
metadata. Native tests cover parser/container equivalents, replay, factor
variables, sample selection, postestimation and plots. Plot aesthetics use
Stata conventions rather than reproducing ggplot objects or viridis gradients.

| R test file | Test | Native coverage |
| --- | --- | --- |
| `test-cluster-large-variance.R` | cluster large-strata variance includes clusters in other treatment arms | Direct internal-helper translation |
| `test-cluster-mixed-components.R` | mixed cluster weights use supplied cluster population sizes | 1 estimator calls replayed |
| `test-cluster-mixed-components.R` | mixed cluster weights infer cluster sizes from available observations | 1 estimator calls replayed |
| `test-cluster-mixed-components.R` | mixed cluster adjustment is applied to both components | 1 estimator calls replayed |
| `test-cluster-mixed-components.R` | mixed cluster variance uses cluster-level component-share variation | 1 estimator calls replayed |
| `test-cluster-small-correction.R` | small-strata cluster point estimator uses expanded outcomes and a common denominator | Direct internal-helper translation |
| `test-cluster-small-correction.R` | small-strata cluster inference supports multiple arms | 2 estimator calls replayed |
| `test-cluster-small-correction.R` | binary small-strata variance is the multi-arm formula with two arms | Direct internal-helper translation |
| `test-cluster-small-correction.R` | small-strata cluster adjustment works when cluster sizes are inferred | 4 estimator calls replayed |
| `test-core.R` | simulations without clusters work | 22 estimator calls replayed |
| `test-core.R` | simulations with clusters work | 39 estimator calls replayed |
| `test-core.R` | One or more covariates do not vary within one or more stratum-treatment combinations while small.strata = FALSE | 3 estimator calls replayed |
| `test-core.R` | individual level X warning works | 1 estimator calls replayed |
| `test-core.R` | no cluster sizes warning works | 1 estimator calls replayed |
| `test-core.R` | data contains one or more NA (or NaN) values warning works | 8 estimator calls replayed |
| `test-core.R` | skipped values in range of S/D works | 3 estimator calls replayed |
| `test-core.R` | non cluster-level error for S, D, Ng works | 9 estimator calls replayed |
| `test-core.R` | empirical example works | 4 estimator calls replayed |
| `test-core.R` | dgp.po warning work | Native generator design/validation translation |
| `test-core.R` | data: small strata, option: small strata | 19 estimator calls replayed |
| `test-core.R` | data: large strata, option: large strata | 14 estimator calls replayed |
| `test-core.R` | data: small strata, option: large strata | 15 estimator calls replayed |
| `test-core.R` | data: large strata, option: small strata | 9 estimator calls replayed |
| `test-core.R` | data: mixed design, option: small strata | 19 estimator calls replayed |
| `test-core.R` | data: mixed design, option: large strata | 22 estimator calls replayed |
| `test-core.R` | data: small strata, option: small strata | 19 estimator calls replayed |
| `test-core.R` | data: large strata, option: large strata | 14 estimator calls replayed |
| `test-core.R` | data: small strata, option: large strata | 15 estimator calls replayed |
| `test-core.R` | data: large strata, option: small strata | 9 estimator calls replayed |
| `test-core.R` | data: mixed design, option: small strata | 19 estimator calls replayed |
| `test-core.R` | data: mixed design, option: large strata | 22 estimator calls replayed |
| `test-core.R` | print.sreg outputs expected information for large strata | 7 estimator calls replayed |
| `test-core.R` | print.sreg outputs expected information for small strata | 9 estimator calls replayed |
| `test-core.R` | plot.sreg works and returns ggplot object | 1 estimator calls replayed |
| `test-design-classifier-warning.R` | mixed-design warning reports the detected individual-level k | Direct internal-helper translation |
| `test-design-classifier-warning.R` | mixed-design warning detects k from cluster counts | Direct internal-helper translation |
| `test-design-classifier-warning.R` | fewer than 25 percent at one size does not produce a mixed warning | Direct internal-helper translation |
| `test-general-k-mixed.R` | sreg estimates individual-level mixed designs with 4-tuples | 1 estimator calls replayed |
| `test-general-k-mixed.R` | sreg estimates cluster-level mixed designs with 4-tuples | 1 estimator calls replayed |
| `test-general-k-mixed.R` | general k must be supplied when automatic detection cannot identify it | 2 estimator calls replayed |
| `test-general-k-mixed.R` | explicit k works for uniform k-tuple designs and is validated | 3 estimator calls replayed |
| `test-mixed-adjustment-validation.R` | individual mixed adjustment is applied to both components | 1 estimator calls replayed |
| `test-mixed-adjustment-validation.R` | individual mixed adjustment reports unidentified large regressions | 1 estimator calls replayed |
| `test-mixed-adjustment-validation.R` | cluster mixed adjustment reports unidentified large regressions | 1 estimator calls replayed |
| `test-mixed-adjustment-validation.R` | unadjusted mixed estimation remains available after adjustment failure | 2 estimator calls replayed |
| `test-rgen-covariate-output.R` | is.cov controls covariate columns in large-strata cluster designs | Native generator design/validation translation |
| `test-rgen-large-custom.R` | large-strata custom DGP defaults preserve generated data | Native generator design/validation translation |
| `test-rgen-large-custom.R` | large-strata generator accepts stratum-specific allocations | Native generator design/validation translation |
| `test-rgen-large-custom.R` | large-strata generator applies custom outcome effects | Native generator design/validation translation |
| `test-rgen-large-custom.R` | custom large-strata arguments are validated | Native generator design/validation translation |
| `test-rgen-mixed.R` | sreg.rgen generates mixed individual-level designs | 1 estimator calls replayed; native generator design/validation translation |
| `test-rgen-mixed.R` | sreg.rgen generates mixed cluster-level designs | 1 estimator calls replayed; native generator design/validation translation |
| `test-rgen-mixed.R` | mixed sreg.rgen validates its component sizes | Native generator design/validation translation |
| `test-rgen-mixed.R` | existing sreg.rgen calls retain their behavior | Native generator design/validation translation |
| `test-rgen-mixed.R` | mixed sreg.rgen derives an allocation when treat.sizes is omitted | Native generator design/validation translation |
