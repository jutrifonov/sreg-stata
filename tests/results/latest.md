# Verification report

Run timestamp (UTC): 2026-09-11T15:14:06.817853+00:00

R reference: `fe1b662c1e0207016eb743d46e7afa47264c5152` (sreg 2.1.0).

Verified using R 4.5.1 and licensed Stata 14.2.
Platform: macOS-26.3-arm64-arm-64bit-Mach-O.

- Original expectation dispositions: **563 passed**, including direct checks and explicit native adaptations.
- Error reasons/codes, warning text/sets, printed fields, and eight negative controls: passed.
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
- Native generator design, allocation, effects, reproducibility, validation,
  covariate output and distribution checks: passed.
- Local `net install` into an isolated ado directory and runnable examples: passed.

Numerical tolerance: `1e-8 * (1 + abs(R value))`. Analytic and equivalence checks
use tighter tolerances. Raw build artifacts are regenerated with
`python3 tools/test.py`; no licensed Stata binary or license metadata is shipped.

## Remaining scope

Native generator tests now cover the intentions of the 11 generator-related
R cases. R and Stata use different random streams; no identical-seed parity
is claimed. See [generator adaptations](../../docs/generator.md) for intentional
edge-case fixes and [the coverage map](../parity/coverage.md) for the mapping.
The plotting command uses native Stata styles instead of reproducing every
R styling argument. See [assertion-level verification](assertion-parity.md)
for the per-expectation checks and the explicit native adaptations. This local report does not claim that hosted CI ran
licensed Stata or that every R-specific object assertion has a literal port.
