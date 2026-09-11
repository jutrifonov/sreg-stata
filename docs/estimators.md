# Native estimator implementation

Reference: R sreg 2.1.0 at `fe1b662c1e0207016eb743d46e7afa47264c5152`.
The unchanged source is under `tests/upstream/R`. The implementation is
`ado/sreg_mata.mata`; the public parser and output are in `ado/sreg.ado`.

## Assignment-unit representation

For individual assignment, each observation is a unit with outcome T=Y and
size N=1. For cluster assignment, there is one row per cluster, T=N times the
sample mean outcome, and covariates are sample cluster means. Supplied N is
the represented population size. When omitted, N is the complete-case sample
count. Cluster IDs are joined explicitly rather than relying on row order.

## Large strata

The implementation follows `lm.iter.*`, `tau.hat.*` and `as.var.*`. Each
treatment/stratum regression includes an intercept; only its slopes enter
the adjustment function. Empirical assignment proportions are calculated
within strata. The adjusted inverse-probability score includes covariate
add-back terms for observations assigned to other treatment arms.

For each treatment contrast d, let W_d denote the centered within-stratum
score and B_d the stratum treatment-control outcome difference centered by
the fitted population effect. With n assignment units:

```
V[d,e] = (hc * sum(W_d * W_e) + sum(B_d * B_e)) / (n^2 * mean(N)^2).
```

For cluster assignment the within score includes the common-denominator
correction `-tau_d * (N - mean(N | stratum))`, including on other-arm rows.
The between score is the expanded-outcome mean difference minus
`tau_d * mean(N | stratum)`. The HC1 factor is `n/(n-S*(A+1))` when defined;
otherwise the R warning/fallback is preserved.

## Small strata

The point estimator follows `tau.hat.sreg.ss` / `tau.hat.creg.ss`: regress
stratum treatment-control outcome differences on corresponding covariate
differences, including an intercept. Subtract the estimated covariate
contribution from the arm mean difference, then divide by mean(N).

The variance uses adjacent pairs of numerically ordered strata. Same-arm
moments come from products across paired strata; different-arm moments come
from products within strata. The individual formula follows `as.var.sreg.ss`.
Cluster inference follows the corrected multi-arm `as.var.creg.ss` formula,
including signed terms for all arms and common-denominator uncertainty.

For cross-treatment covariance, each scalar product in those moments is
replaced with its bilinear counterpart. Same-arm paired products are
symmetrized. This yields the covariance of contrast-specific adjusted scores
even when their adjustment coefficients differ. The diagonal reproduces the
R formula. Analytic covariance examples are checked separately in
`tests/stata/test-covariance.do`.

HC1 is B/(B-p-1), with B small strata and p covariates. It applies to the
within-arm component for adjusted individual fits and all cluster fits.
Unadjusted individual small-strata variance does not depend on HC1, as in R.

## Mixed designs

The classifier follows R's modal-size/25% rule and optional k. Both components
receive covariate adjustment when requested. An unidentified large component
is an error. Component estimates use represented population shares:

```
p = sum(N in small component) / sum(N)
b = p*b_small + (1-p)*b_large
V = p^2*V_small + (1-p)^2*V_large + share_variance * delta'*delta
delta = b_small - b_large
share_variance = mean(N^2*(I_small-p)^2) / (n*mean(N)^2)
```

For N=1 this reduces to the R individual mixture formula. For clusters it
uses cluster-level component-share variation, not the number of sampled
individuals.

## Output and deliberate Stata adaptations

- Standard normal inference is displayed as z, not Student t. `level()` is
  a Stata extension; the default 95% intervals match R.
- R exposes standard errors, not the full covariance matrix. Off-diagonal
  `e(V)` elements are the bilinear extensions above, not invented zeros.
- `e(beta)` records slopes, without intercepts. For large fits its rows are
  stratum-major, then arm-major (control first); small fits have one row per
  active arm. In mixed fits `e(beta_small)` and `e(beta_large)` retain both
  components. Columns follow `e(adjustment_terms)`.
  Mixed large-component rows follow sorted original large-stratum IDs;
  R instead numbers that component by first appearance.
- `e(sample)` and design/covariate metadata replace R's returned data frames.
  The original dataset is preserved. R container classes have no Stata
  equivalent; native numeric-variable and factor-variable checks cover that
  interface instead.
- Cluster aggregation is invariant to row order. Some R large-cluster paths
  combine sorted cluster means with first-appearance IDs; this port joins
  them correctly rather than reproducing that ordering defect.
- Small components are renumbered internally in sorted stratum order.
  An odd count, negative variance or nonfinite inference returns an error;
  R's individual small-strata path can instead propagate undefined values.
- Primary `clustersize()` requires `cluster()`. Legacy `ng()` without
  `g_id()` is accepted and included in missing-data selection, then ignored
  by the individual estimator, matching the old/R calling convention.
- `sregplot` returns a native graph. Styling uses Stata options; the R
  viridis/gradient scale is not reproduced. No prediction command is exposed.

## Generator and documentation

The native generator is available as `sreg_rgen`; see [generator details](generator.md)
for its tests and explicit adaptations from R. Original R vignettes and help
remain unchanged as references; native Stata help and examples cover the
implemented commands.
