# sreg for Stata

Native Stata/Mata implementation of **sreg: Stratified Randomized Experiments**.

**Status: estimator and output milestone implemented and tested on Stata/MP 14.2.**

Native estimators cover large, small and mixed strata, individual and cluster
assignment, multiple treatment arms, covariate adjustment and HC1. The package
provides estimation tables, full covariance matrices, stored results,
`lincom`/`test` support and native coefficient plots. Installed users need
Stata 14.2 or newer, with no R or Python dependency.

The native random-data generator remains pending. Its R tests are retained
and run as part of the reference suite; they are not native generator tests.

## Syntax

```stata
sreg outcome [covariates] [if] [in], treatment(varname) ///
    [strata(varname) cluster(varname) clustersize(varname) ///
     smallstrata k(#) nohc1 level(#)]
```

```stata
sreg earnings baseline_earnings age, treatment(assignment) strata(block)
lincom tau2 - tau1
sregplot, xtitle("ATE relative to control")
```

The command remains `sreg`. This repository is `sreg-stata`; the older
[Python-backed implementation](https://github.com/jutrifonov/sreg_stata)
is a separate legacy project. Do not install both implementations on the same
Stata ado-path.

## Installation

From a local checkout, in Stata:

```stata
net install sreg, from("/absolute/path/to/sreg-stata") replace
help sreg
```

The repository is private during development. A public installation URL will
be provided when a public release is available. See
[runnable examples](examples/estimation.do).

## Verification and development

```sh
python3 tools/test.py
```

The runner executes all 55 unchanged upstream R tests (563 assertions),
the R documentation examples, and the native comparison suites. It replays
235 transferable estimator calls: 161 numerical cases and 74 expected errors.
Eleven R container/type cases are covered by native interface checks.
Internal-helper, analytic covariance, plotting and installation checks are
recorded in the [verification report](tests/results/latest.md).

- [Interface specification](docs/interface.md)
- [Porting plan](docs/porting-plan.md)
- [Estimator details and adaptations](docs/estimators.md)
- [Testing instructions](docs/testing.md)
- [Coverage mapping](tests/parity/coverage.md)
- [R reference](reference/r-source.json)
- [Test inventory](tests/parity/r-test-inventory.json)

The R reference is pinned to an exact commit and vendored source checksums
are verified by the test runner. No tests are silently removed from the
upstream suite. The coverage mapping distinguishes native estimator checks
from generator-only tests that currently run against R.

## Layout

- `ado/`: Stata commands and help files
- `ado/sreg_mata.mata`: native numerical routines loaded by the command
- `examples/`: runnable examples
- `tests/stata/`: native tests
- `tests/parity/`: R-to-Stata coverage inventory and numerical comparisons
- `tests/upstream/`: unchanged R reference source, tests and documentation
- `.build/fixtures/`: generated shared fixed datasets and expected results
- `tools/`: development scripts

## License

MIT; see [LICENSE](LICENSE). Original sreg authors' attribution is retained.
