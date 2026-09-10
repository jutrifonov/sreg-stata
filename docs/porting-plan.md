# Native port plan

Estimator/output milestone: implemented and locally verified. See
`tests/results/latest.md` for the results and `tests/parity/coverage.md` for
the per-test mapping. The native generator and its native tests remain
pending before the full package port can be considered complete.

1. Audit pinned R source, all tests, examples, help and exported functionality.
2. Establish a working R baseline and licensed Stata batch test runner.
3. Translate validation and implement the agreed parser/sample handling.
4. Implement large-strata, small-strata and mixed estimators in Mata, for
   individual and cluster assignment, multiple arms, adjustment and HC1.
5. Implement the generator, display/plot equivalents, saved results and
   supported postestimation. Map every public R feature explicitly.
6. Translate every R test's intent, and compare fixed shared inputs against R
   for estimates, variance, statistics, p-values and confidence intervals.
7. Translate examples and documentation into Stata help and do-files; package
   installation files only once the required implementation files exist.
8. Run all native tests and numerical comparisons and record results before
   describing the port as complete.

## Verification contract

Inventory each R test with its location and corresponding Stata test(s).
Include R package checks and examples in the audit, not only testthat files.
R-only object/container checks need documented Stata equivalents or a reason
why they do not apply. No silent coverage exclusions.

Use fixed datasets for numerical comparisons; record and justify tolerances.
Test random generators using design constraints and statistical properties;
equal seeds across R and Stata do not imply identical streams.

Tests must include R warning/error and fallback behavior, singular adjustment,
unequal cluster sizes, multiple treatments, general k-tuples, mixed components,
and Stata-specific parsing, saved results, sample marking and replay.

R is allowed for development fixtures and comparisons. The installed Stata
package must execute entirely in Stata/Mata. Full verification requires a
licensed Stata runner; CI must report unavailable execution honestly.
