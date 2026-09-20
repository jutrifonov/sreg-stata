# Native random-data generation

`sreg_rgen` generates data entirely in Stata/Mata. See `help sreg_rgen`
and `examples/generation.do` for syntax and options.

Use `set seed` for reproducibility.

## Data-generating process

The latent matching variable is sqrt(20)*(Beta(2,2)-.5). Individual covariates
are independent N(5,4) and N(2,1), where the second parameter is variance.
Individual potential-outcome errors are independent N(0,1). Cluster
covariates are independent standard normals; control errors have variance 1
and active-arm errors variance 2. Covariates and the latent variable are
constant within clusters; outcome errors are independent across people.
Cluster sizes are uniform on 10,20,...,nmax().

Small strata sort assignment units by the latent variable and form consecutive
k-tuples, with exact specified arm counts. Large individual strata use fixed
bounds from -2.25 to 2.25; cluster bounds use the observed minimum and maximum.
Active-arm counts are floor(n_s*p_sa), with control receiving the remainder.
Assignment is a random permutation of these fixed counts. Mixed components
are generated independently and use disjoint stratum and cluster IDs.

Hiding individual covariates removes their contribution to potential
outcomes; hiding cluster covariates only changes the reported columns.

## Validation and output

Cluster designs report `G_id` and `Ng`. Every cluster is assigned to a
stratum, including the cluster with the minimum matching value.
Individual small-strata generation supports `nocovariates`.

Invalid dimensions, missing parameters and incompatible design options are
rejected before replacing data. `clear` permits replacing existing data.
The number of active treatments is determined by `tau()`.

The uniform-small default is `treatsizes(1 1 1)`. With one active treatment,
specify compatible counts, such as `treatsizes(2 1)`.
Generated experiments may have empty or sparse cells; generation does not
guarantee that estimator cell-size or paired-strata requirements hold.

## Verification

`tests/stata/test-generator.do` checks component sizes, estimator integration,
cluster identifiers, exact allocations, reproducibility, custom effects,
validation, covariate output, preservation on errors and distribution moments.
