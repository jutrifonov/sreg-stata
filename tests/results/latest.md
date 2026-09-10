# Verification report

Run timestamp (UTC): 2026-09-10T23:19:57.908361+00:00

R reference: `fe1b662c1e0207016eb743d46e7afa47264c5152` (sreg 2.1.0).

Verified using R 4.5.1 and licensed Stata 14.2.
Platform: macOS-26.3-arm64-arm-64bit-Mach-O.

- Original R suite: **55 test cases, 563 assertions passed**.
- R documentation examples: executed and included in captured estimator calls.
- Native replay suite: **235 passed** (161 numerical cases,
  74 expected errors).
- R container/type-specific calls: 11; corresponding native parser checks passed.
- Internal helper translations: passed, including the multi-arm cluster
  variance correction, small-cluster estimators and classifier rules.
- Native interface, stored results, replay, factor variables, sample marking,
  cluster row-order invariance and inferred sizes: passed.
- `lincom`, joint tests and analytic full-covariance examples: passed.
- Native graph creation and preservation of data/results: passed.
- Local `net install` into an isolated ado directory and runnable examples: passed.

Numerical tolerance: `1e-8 * (1 + abs(R value))`. Analytic and equivalence checks
use tighter tolerances. Raw build artifacts are regenerated with
`python3 tools/test.py`; no licensed Stata binary or license metadata is shipped.

## Remaining scope

The native random-data generator is pending. 11 original test cases
exercise generator functionality (some also exercise estimation). Those R
tests pass, but this report does not claim native generator parity. Detailed
coverage is in [the coverage map](../parity/coverage.md). The plotting command
uses native Stata styles instead of reproducing every R styling argument.

This is verification of the estimator/output milestone, not a claim that the
entire R package has already been ported or that hosted CI ran licensed Stata.
