# sreg for Stata

Native Stata/Mata implementation of **sreg: Stratified Randomized Experiments**.

**Status: initial development. Estimation is not implemented yet.**

This project ports the R package's estimators, data generator, output, plotting,
examples, documentation, and test coverage. Installed users will not need R or
Python. R is used during development for reference results.

## Planned syntax

```stata
sreg outcome [covariates] [if] [in], treatment(varname) ///
    [strata(varname) cluster(varname) clustersize(varname) ///
     smallstrata k(#) nohc1 level(#)]
```

```stata
sreg earnings baseline_earnings age, treatment(assignment) strata(block)
```

The command remains `sreg`. This repository is `sreg-stata`; the older
[Python-backed implementation](https://github.com/jutrifonov/sreg_stata)
is a separate legacy project. Do not install both implementations on the same
Stata ado-path.

## Development

- [Interface specification](docs/interface.md)
- [Porting plan](docs/porting-plan.md)
- [R reference](reference/r-source.json)
- [Test inventory](tests/parity/r-test-inventory.json)

The R reference is pinned to an exact commit. Test inventory entries start as
pending; they do not claim implemented or passing coverage.

## Layout

- `ado/`: Stata commands and help files
- `mata/`: native numerical routines
- `examples/`: runnable examples
- `tests/stata/`: native tests
- `tests/parity/`: R-to-Stata coverage inventory and numerical comparisons
- `tests/fixtures/`: shared fixed datasets and expected results
- `tools/`: development scripts

## License

MIT; see [LICENSE](LICENSE). Original sreg authors' attribution is retained.
