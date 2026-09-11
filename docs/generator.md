# Native random-data generation

`sreg_rgen` implements the public R 2.1.0 `sreg.rgen` generator entirely in
Stata/Mata. See `help sreg_rgen` and `examples/generation.do`.

| R argument | Stata option | Default |
| --- | --- | --- |
| n | n() | required |
| Nmax | nmax() | 50 |
| n.strata | strata() | 10 |
| tau.vec | tau() | 0 |
| gamma.vec | gamma() | .4 .2 1 |
| cluster = FALSE | individual | cluster assignment |
| is.cov = FALSE | nocovariates | report covariates |
| small.strata | smallstrata | off |
| mixed.strata | mixedstrata | off |
| k | k() | 3 |
| treat.sizes | treatsizes() | 1 1 1 in uniform small designs; balanced in mixed designs |
| n.small | nsmall() | floor(n/(2*k))*k in mixed designs |
| allocation.probs | allocation(matrix) | equal probabilities |
| stratum.effects | stratumeffects(numlist) | zero |
| treatment.effects.by.stratum | treatmenteffects(matrix) | tau in every stratum |

Use `set seed` for reproducibility. Random-number streams differ between R
and Stata, so matching numerical seeds is not a cross-language parity test.
Custom effects leave the assignment and random draws unchanged when the seed
and other options are held fixed. Treatment-effect matrices replace tau;
stratum shifts add to every potential outcome.

## Data-generating process

The latent matching variable is sqrt(20)*(Beta(2,2)-.5). Individual covariates
are independent N(5,4) and N(2,1), where the second parameter is variance.
Individual potential-outcome errors are independent N(0,1). Cluster
covariates are independent standard normals; control errors have variance 1
and active-arm errors variance 2. Covariates and the latent variable are
constant within clusters; outcome errors are independent across people.
Cluster sizes are uniform on 10,20,...,Nmax, the same distribution as the R
Beta-binomial construction with shape parameters 1 and 1.

Small strata sort assignment units by the latent variable and form consecutive
k-tuples, with exact specified arm counts. Large individual strata use fixed
bounds from -2.25 to 2.25; cluster bounds use the observed minimum and maximum.
Active-arm counts are floor(n_s*p_sa), with control receiving the remainder.
Assignment is a random permutation of these fixed counts. Mixed components
are generated independently and use disjoint stratum and cluster IDs.

As in R, hiding individual covariates removes their contribution to potential
outcomes; hiding cluster covariates only changes the reported columns.

## Deliberate adaptations

- `G.id` becomes the valid Stata name `G_id`; Ng is reported once, including
  small-cluster designs where R can report a redundant `Ng.1` column.
- The minimum cluster matching value belongs to the first stratum. R excludes
  it from all bins, randomly labels the all-zero membership row, and leaves
  its treatment at control. The native generator assigns every cluster.
- Individual small-strata generation works with `nocovariates`; R's helper
  attempts to select absent covariate columns in that case.
- Singleton assignment vectors retain their arm code, without R's scalar
  `sample()` interpretation.
- Invalid dimensions, missing parameters, and incompatible design options are
  rejected before replacing data. `clear` is required to replace existing data.
- Arm count is derived from tau, so R's internal disagreement between n.treat
  and the theta vector cannot be expressed. Allocation/effect/count dimensions
  are checked against this derived count instead.

The R uniform-small default `treat.sizes=c(1,1,1)` is retained. With the default
one active treatment, use `treatsizes(2 1)` explicitly. A generated experiment
can have empty or sparse large-stratum cells, and some mixed designs can
accidentally produce additional k-sized strata. Generation does not guarantee
that the estimator's cell-size or paired-strata requirements hold.

## Verification

`tests/stata/test-generator.do` translates the intent of all ten tests in the
three upstream `test-rgen-*.R` files, plus the internal arm-count error case
in `test-core.R`. It checks mixed component sizes and estimator integration,
cluster IDs, exact treatment allocations, defaults and repeated seeds,
custom-effect identities, validation, and covariate output. Additional native
checks cover all six designs with/without covariates, preservation on errors,
zero-count arms, cluster boundary handling, and fixed-seed distribution moments.
`tools/export-generator-fixtures.R` also compares stratum membership and
allocation multisets with the original R helpers on shared fixed inputs,
with the excluded minimum explicitly repaired for cluster binning.
The original R files continue to run unchanged in the reference environment.
These are design and distribution comparisons, not identical random draws or
a literal translation of R object/container assertions.
