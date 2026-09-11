# R-to-Stata test audit

Audit snapshot: 2026-09-11 UTC, verification run 2026-09-11T04:49:05.191704+00:00.

The R reference is sreg 2.1.0 at fe1b662c1e0207016eb743d46e7afa47264c5152.
The full reference and native suites were rerun on Stata/MP 14.2 and R 4.5.1.
See `verification.json` for the run timestamp and `test-audit.json` for all
measured numerical discrepancies and expectation counts.

## Counts and coverage limits

| Unit | Count | Meaning |
| --- | ---: | --- |
| Original R test cases | 55 | Executed `test_that` blocks, including repeated descriptions |
| Original R expectations | 563 | All passed; original files unchanged |
| Stata estimator replay cases | 235 | 161 successful numerical cases and 74 expected rejections |
| Of those, original-test replays | 229 | Documentation contributes another 6 |
| Additional native suites | 5 | Internal helpers; interface/plots; covariance; generator; installation |
| Recorded scalar numerical comparisons | 4,070 | Estimates, inference, slopes, and mixed-component results |

All 55 R cases have a case-level native mapping: 40 contain estimator replays,
6 map to helper checks, and 9 to generator/interface adaptations. Two of the
40 also have generator tests. **This is not certification that all 563 R
expectations have an individually equivalent native assertion.** The native
suite is organized differently, so 235 replay cases plus five supplementary
suites must not be presented as a comparable count of R `test_that` blocks.
The scalar comparison count is also not a count of independent test scenarios.

The audit corrected a mapping defect: six pairs of R tests have duplicate
names, and the old report merged their call IDs by name. The executed 235
replays were already distinct; their count and results did not change. The
mapping now uses unique execution-order IDs, with names checked for consistency.

Concrete remaining assertion-level gaps/adaptations:

- 153 expectations inspect printed R output strings. Native stored-result and
  inference checks do not constitute a literal test of those printed strings.
- The 74 expected-error replays require a nonzero return code, not the exact
  expected diagnostic. This can miss an error raised for the wrong reason.
- Warning checks cover selected categories; they do not verify every full
  warning string or prove that no unexpected warnings were issued. In
  particular, the classifier helper translations check k and failure behavior,
  not all original warning-text and returned-data classification assertions.
- R's ggplot-class expectation is replaced by native graph creation and data/
  result preservation. R container checks use native parser equivalents.
- Generator tests compare design constraints, effects, and distributions rather
  than seed-identical datasets. R's internal n.treat/theta mismatch is impossible
  through the native API, which derives arm count from tau.
- The full Stata covariance matrix is an extension beyond R's exposed standard
  errors. Its off-diagonal entries have analytic checks, not direct R output
  parity for every case.

The assertion inventory can be regenerated as `.build/r-assertion-audit.csv`,
with each executed expectation's source location and expression. A complete
assertion-by-assertion disposition review is still required before claiming
that every original expectation has been ported.

## Actual numerical discrepancies on identical inputs

R runs the original tests, including their seeded generators and hard-coded
expectations. The harness then exports those actual datasets, so Stata uses
the same Y, D, S, covariates, cluster IDs, and population sizes. It does not
regenerate test inputs using a Stata seed. Passing R's original expectations
and then matching those R results gives two stages of verification.

| Quantity | Scalar comparisons | Largest absolute difference |
| --- | ---: | ---: |
| Treatment estimates | 333 | 1.3323e-14 |
| Standard errors | 333 | 9.8532e-16 |
| z statistics | 333 | 2.4336e-13 |
| p-values | 333 | 8.7708e-15 |
| Lower CI endpoint | 333 | 1.3600e-14 |
| Upper CI endpoint | 333 | 1.2990e-14 |
| Adjustment coefficients, main beta matrix | 1,612 | 6.9456e-13 |

Additional mixed-component comparisons are recorded in `test-audit.json`.
The largest absolute discrepancy across all 4,070 comparisons is 6.9456e-13;
the largest error scaled by (1+abs(R value)) is 6.3313e-14. These measured
errors are much smaller than the suite's 1e-8 scaled tolerance and are
consistent with floating-point arithmetic and fixture serialization.
Relative percentage errors are not useful for quantities near zero.

These results apply to the tested inputs. They do not establish equivalence
for arbitrary ill-conditioned inputs or the deliberate R edge-case fixes
listed in `docs/estimators.md` and `docs/generator.md`.

## Independent random-data generation

A separate diagnostic generated 100 experiments per language for each of two
large-strata designs: individual n=1200 and cluster G=200, four strata, one
active effect of 0.5, with covariate-adjusted estimation. Equal numerical seeds
select different R/Stata random streams. Results:

| Design | Mean R estimate | Mean Stata estimate | Stata minus R | MC standard error of difference |
| --- | ---: | ---: | ---: | ---: |
| Individual | 0.500417 | 0.497058 | -0.003360 | 0.007805 |
| Cluster | 0.488104 | 0.481901 | -0.006203 | 0.013068 |

Approximate Monte Carlo 95% intervals for the differences are [-0.01866,
0.01194] and [-0.03182, 0.01941], respectively. The observed differences are
small relative to simulation uncertainty. This is supportive evidence, not
an equivalence proof or a comprehensive calibration study. The empirical
95% interval coverage was 94%/99% for R/Stata individual designs and 96%/92%
for cluster designs; 100 replications are insufficient to assess small
coverage differences precisely. Small and mixed designs were not included
in this additional Monte Carlo diagnostic, although their native structural
checks and shared-input estimator comparisons pass.

R and Stata cluster generators intentionally differ at the excluded-minimum
boundary in R. Consequently, even distributional identity is not claimed for
that defect. See `generator-monte-carlo.json` for full sampling diagnostics.

## Reproduction

```sh
python3 tools/test.py
Rscript tools/export-assertion-audit.R
python3 tools/audit-tests.py
python3 tools/report-coverage.py

# Optional independent-stream diagnostic; these runs are additional to the suite.
Rscript tools/generator-monte-carlo.R
rm -f .build/generator-mc.done
stata-mp -b do tools/generator-monte-carlo.do
python3 tools/summarize-generator-monte-carlo.py
```

The numerical implementation has strong evidence on the shared fixtures.
Complete assertion parity, diagnostic specificity, and broad multi-seed
calibration are separate claims that the current suite does not establish.
