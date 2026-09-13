# sreg: Stratified Randomized Experiments (Stata® Edition)<br><a href="https://github.com/jutrifonov/sreg-stata"><img src="docs/figures/sreg-logo.png" alt="sreg logo" align="right" height="250" /></a>

![version](https://img.shields.io/badge/sreg-v.0.1.0-green?style=flat&logo=github&labelColor=2A2523)
![Stata](https://img.shields.io/badge/Stata-14.2%2B-blue?style=flat&labelColor=2A2523)
[![License: MIT](https://img.shields.io/badge/License-MIT-orange?style=flat&labelColor=2A2523)](LICENSE)

The `sreg` package for **Stata** estimates average treatment effects (ATEs) in stratified randomized experiments. It supports matched pairs, $k$-tuple designs, large strata of potentially unequal sizes, and designs that combine small and large strata. Estimation accommodates multiple treatments, individual- and cluster-level treatment assignment, and optimal linear covariate adjustment using baseline characteristics.

The package implements the estimators and standard errors available in the [R version of sreg](https://github.com/jutrifonov/sreg), using native Stata and Mata.

**Dependencies:** No additional packages required.

**Stata version required:** 14.2 or newer.

<br clear="right" />

## Authors

- Juri Trifonov — jutrifonov@u.northwestern.edu
- Yuehao Bai — yuehao.bai@usc.edu
- Azeem Shaikh — amshaikh@uchicago.edu
- Max Tabord-Meehan — m.tabordmeehan@utoronto.ca

## Supplementary files

- Command documentation: `help sreg`, `help sregplot`, and `help sreg_rgen` after installation.
- Estimator formulas for large, small, and mixed strata under individual- and cluster-level assignment: [Download PDF](https://github.com/jutrifonov/sreg/raw/main/.github/assets/sreg-estimator-formulas.pdf).

## Installation

Download this repository using **Code → Download ZIP**, then unzip it. In Stata, install from the extracted folder, replacing the path below with its location:

```stata
net install sreg, from("/path/to/sreg-stata") replace
help sreg
```

Access to the repository is currently required to download it. Once installed, the package runs entirely within Stata.

## Command: `sreg`

Estimates treatment effects relative to the control group and reports design-based standard errors and confidence intervals.

### Syntax

```stata
sreg outcome [covariates] [if] [in], treatment(varname) ///
    [strata(varname) cluster(varname) clustersize(varname) ///
     smallstrata k(#) nohc1 level(#)]
```

### Arguments and options

- **`outcome`** — the variable containing observed outcomes.
- **`covariates`** — optional baseline covariates for linear adjustment. Omit them for unadjusted estimation.
- **`treatment(varname)`** — treatment assignment, with `0` denoting control and `1, 2, …` the active treatments.
- **`strata(varname)`** — stratum indicators. Omit for an experiment without stratification.
- **`cluster(varname)`** — cluster identifiers when treatment is assigned at the cluster level. Omit for individual assignment.
- **`clustersize(varname)`** — represented cluster sizes. If omitted, sizes are inferred from the observations used in each cluster.
- **`smallstrata`** — selects estimation for small strata or a mixture of small and large strata.
- **`k(#)`** — the number of assignment units per small stratum. Optional for uniform small strata; specify it for mixed designs with 4-tuples or larger.
- **`nohc1`** — turns off the HC1 finite-sample correction, which is enabled by default.
- **`level(#)`** — confidence level; the default is `95`.

For cluster-randomized experiments, individual-level covariates are averaged within clusters before adjustment. Treatment, stratum, and represented size must be constant within each cluster.

### Example: large strata

Generate a two-treatment experiment and estimate both effects with covariate adjustment:

```stata
set rng mt64
set seed 2026
sreg_rgen, n(1000) individual strata(4) tau(-.3 .2) clear
sreg Y x_1 x_2, treatment(D) strata(S)
```

### Summary

`sreg` displays the estimated effects, standard errors, normal z statistics, p-values, and asymptotic confidence intervals:

```text
Saturated Model Estimation Results under CAR with linear adjustments
Observations:      1,000
Number of treatments: 2
Number of strata: 4
Setup: large strata
Standard errors: adjusted (HC1)
Treatment assignment: individual level
Covariates used in linear adjustments:  x_1 x_2
------------------------------------------------------------------------------
             |            Design-based
           Y |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
        tau1 |  -.2476206   .0775952    -3.19   0.001    -.3997044   -.0955369
        tau2 |   .2347557   .0855676     2.74   0.006     .0670464     .402465
------------------------------------------------------------------------------
```

### Stored results

Treatment effects are named `tau1`, `tau2`, and so on. Estimates are stored in `e(b)` and their covariance matrix in `e(V)`. Use standard Stata commands to inspect results or estimate contrasts:

```stata
matrix list e(b)
matrix list e(V)
lincom tau2 - tau1
```

Run `sreg` without arguments to display the estimation table again. See `help sreg` for the complete list of stored results.

### Example: small strata

Generate matched triplets with one control and two active treatments per stratum:

```stata
set seed 2026
sreg_rgen, n(300) individual tau(1.2 .8) ///
    smallstrata k(3) treatsizes(1 1 1) clear

sreg Y x_1 x_2, treatment(D) strata(S) smallstrata
```

Because all strata have the same size, `sreg` identifies the triplets directly. Adding `k(3)` to the estimation command is an optional validation check.

### Example: mixed small and large strata

Here, 80 observations form 20 small strata of size four, and the remaining 40 observations are assigned to four large-stratum bins:

```stata
set seed 2026
sreg_rgen, n(120) individual tau(.5) ///
    mixedstrata nsmall(80) k(4) treatsizes(2 2) strata(4) clear

sreg Y, treatment(D) strata(S) smallstrata k(4)
```

Use `smallstrata` for estimation of the mixed design and specify `k(4)` to identify its small component. At least 25% of the strata must have the selected small-stratum size. Without `k()`, automatic detection covers conventional pairs and triplets.

### Example: cluster-level treatment assignment

Generate 300 clusters and estimate the effects with covariate adjustment:

```stata
set seed 2026
sreg_rgen, n(300) strata(4) tau(.5 .8) clear

sreg Y x_1 x_2, treatment(D) strata(S) ///
    cluster(G_id) clustersize(Ng)
```

For clustered small or mixed designs, also supply `smallstrata` and, where appropriate, `k()` to the estimation command.

## Command: `sregplot`

Plots estimated treatment effects and their confidence intervals after `sreg`.

### Syntax

```stata
sregplot [, treatmentlabels("label 1" "label 2" ...) ///
    level(#) title(string) xtitle(string)]
```

### Example

```stata
set rng mt64
set seed 2026
sreg_rgen, n(1000) individual strata(4) tau(-.3 .2) clear
sreg Y x_1 x_2, treatment(D) strata(S)

sregplot, treatmentlabels("Treatment 1" "Treatment 2") ///
    title("Estimated ATEs with 95% confidence intervals") ///
    xtitle("Average treatment effect") bgcolor(white)
```

![Estimated treatment effects and 95% confidence intervals from Stata](docs/figures/example-plot.svg)

Use `help sregplot` for color, marker, label, and graph-saving options.

## Command: `sreg_rgen`

Generates outcomes, treatment assignments, strata, covariates, and, for cluster designs, cluster identifiers and sizes.

### Syntax

```stata
sreg_rgen, n(#) [individual strata(#) nmax(#) tau(numlist) ///
    gamma(numlist) nocovariates smallstrata mixedstrata ///
    k(#) treatsizes(numlist) nsmall(#) clear]
```

### Main options

- **`n(#)`** — number of clusters by default, or number of individuals with `individual`.
- **`individual`** — generates individual-level treatment assignment.
- **`strata(#)`** — number of large-stratum bins; default `10`.
- **`nmax(#)`** — maximum cluster size; default `50`, in multiples of `10`.
- **`tau(numlist)`** — true effects for the active treatments; default `0` for one treatment.
- **`gamma(numlist)`** — three outcome-model coefficients; default `.4 .2 1`.
- **`smallstrata`** / **`mixedstrata`** — generates small strata or a mixture of small and large strata.
- **`k(#)`** — number of assignment units per small stratum.
- **`treatsizes(numlist)`** — assignment counts within each small stratum, control first; counts must sum to `k()`.
- **`nsmall(#)`** — assignment units in the small component of a mixed design.
- **`nocovariates`** — omits the generated covariates.
- **`clear`** — allows replacement of the data currently in memory.

### Generated variables

| Variable | Description |
|---|---|
| `Y` | Observed outcome |
| `S` | Stratum identifier |
| `D` | Treatment assignment; control is `0` |
| `x_1`, `x_2` | Baseline covariates, unless omitted |
| `G_id` | Cluster identifier, for cluster designs |
| `Ng` | Cluster size, for cluster designs |

### Example: matched pairs

```stata
set seed 2026
sreg_rgen, n(100) individual tau(1.2) ///
    smallstrata k(2) treatsizes(1 1) clear

sreg Y x_1 x_2, treatment(D) strata(S) smallstrata
```

For custom treatment allocations and stratum-specific effects, see `help sreg_rgen`.

## References

The estimators follow Bugni, Canay, and Shaikh (2018); Bugni, Canay, Shaikh, and Tabord-Meehan; Jiang, Linton, Tang, and Zhang; Bai, Jiang, Romano, Shaikh, and Zhang (2024); Bai (2022); Bai, Romano, and Shaikh (2022); Liu (2024); and Cytrynbaum (2024).

See the [R package references](https://github.com/jutrifonov/sreg#references) and the [estimator formulas](https://github.com/jutrifonov/sreg/raw/main/.github/assets/sreg-estimator-formulas.pdf) for bibliographic details and mathematical expressions.

## License

MIT. See [LICENSE](LICENSE).
