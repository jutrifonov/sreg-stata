# Native estimator implementation

The numerical implementation is in `ado/sreg_mata.mata`; command parsing,
stored results and printed output are in `ado/sreg.ado`.

## Assignment-unit representation

For individual assignment, each observation is a unit with outcome T=Y and
size N=1. For cluster assignment, there is one row per cluster, T=N times the
sample mean outcome, and covariates are sample cluster means. Supplied N is
the represented population size. When omitted, N is the complete-case sample
count. Cluster IDs are joined explicitly rather than relying on row order.

## Large strata

Each
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
otherwise a warning is issued and the correction is not applied.

## Small strata

To compute the point estimator, regress
stratum treatment-control outcome differences on corresponding covariate
differences, including an intercept. Subtract the estimated covariate
contribution from the arm mean difference, then divide by mean(N).

The variance uses adjacent pairs of numerically ordered strata. Same-arm
moments come from products across paired strata; different-arm moments come
from products within strata. Cluster inference accounts for multiple treatments,
including signed terms for all arms and common-denominator uncertainty.

For cross-treatment covariance, each scalar product in those moments is
replaced with its bilinear counterpart. Same-arm paired products are
symmetrized. This yields the covariance of contrast-specific adjusted scores
even when their adjustment coefficients differ. The diagonal contains the treatment-specific variance estimates. Analytic covariance examples are checked separately in
`tests/stata/test-covariance.do`.

HC1 is B/(B-p-1), with B small strata and p covariates. It applies to the
within-arm component for adjusted individual fits and all cluster fits.
Unadjusted individual small-strata variance does not depend on HC1.

## Mixed designs

The classifier uses the modal stratum size, a 25% threshold and optional k. Both components
receive covariate adjustment when requested. An unidentified large component
is an error. Component estimates use represented population shares:

```
p = sum(N in small component) / sum(N)
b = p*b_small + (1-p)*b_large
V = p^2*V_small + (1-p)^2*V_large + share_variance * delta'*delta
delta = b_small - b_large
share_variance = mean(N^2*(I_small-p)^2) / (n*mean(N)^2)
```

For N=1 this reduces to the individual mixture formula. For clusters it
uses cluster-level component-share variation, not the number of sampled
individuals.

## Stored results and inference

Standard normal inference is displayed as z. The confidence level defaults
to 95% and can be changed with `level()`. The full covariance matrix is
stored in `e(V)`; its off-diagonal elements use the bilinear formulas above.

`e(beta)` records adjustment slopes without intercepts. For large designs,
rows follow strata and then treatment arms, with control first. Small designs
have one row per active treatment. Mixed designs retain both components in
`e(beta_small)` and `e(beta_large)`. Columns follow `e(adjustment_terms)`.

`e(sample)` marks the estimation sample. The dataset and observation order
are preserved. Cluster aggregation is invariant to row order. Small strata
are paired in numeric stratum order; odd counts and invalid variances return
errors. `sregplot` draws a native Stata graph from stored estimates.

## Data generation

See [generator details](generator.md) for `sreg_rgen`.
