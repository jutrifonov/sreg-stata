# Main command interface

Agreed primary syntax:

```stata
sreg outcome [covariates] [if] [in], treatment(varname) ///
    [strata(varname) cluster(varname) clustersize(varname) ///
     smallstrata k(#) nohc1 level(#)]
```

| Stata input | Meaning |
| --- | --- |
| outcome | Observed outcome |
| covariates | Optional adjustment covariates |
| treatment() | Assignment; control coded zero |
| strata() | Optional stratum identifier |
| cluster() | Cluster randomization unit |
| clustersize() | Population cluster size; inferred from available observations when omitted |
| smallstrata | Enable small/mixed design selection |
| k() | Units/clusters per small stratum |
| nohc1 | Disable correction; default enabled |
| level() | Confidence percentage; default 95 |

Report the effective
design and adjustment status. `cluster()` changes the assignment design and
must not be treated as a generic sandwich variance option.

Retain the legacy `sreg, y() d() s() x() g_id() ng() hc1(true|false)` interface.
Reject conflicting primary and legacy specifications rather than silently
choosing one. Final option abbreviation rules require parser tests.

Implemented as an eclass command, with e(b), the full e(V), e(sample), design
and sample metadata, and replay. lincom/test use standard normal inference.
Off-diagonal covariances use the bilinear versions of the underlying formulas
and are checked in analytic covariance tests; see estimators.md.

Factor-variable covariates are implemented. Sample filtering, missing
observations, empty arms, collinearity and cluster/stratum consistency have
native tests. Interface behavior are documented in
estimators.md, including undefined-inference errors and cluster row-order
invariance.
