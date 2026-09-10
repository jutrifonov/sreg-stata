# Main command interface

Agreed primary syntax:

```stata
sreg outcome [covariates] [if] [in], treatment(varname) ///
    [strata(varname) cluster(varname) clustersize(varname) ///
     smallstrata k(#) nohc1 level(#)]
```

| Stata input | R argument | Meaning |
| --- | --- | --- |
| outcome | Y | Observed outcome |
| covariates | X | Optional adjustment covariates |
| treatment() | D | Assignment; control coded zero |
| strata() | S | Optional stratum identifier |
| cluster() | G.id | Cluster randomization unit |
| clustersize() | Ng | Population cluster size; preserve R default when omitted |
| smallstrata | small.strata = TRUE | Enable R small/mixed design selection |
| k() | k | Units/clusters per small stratum |
| nohc1 | HC1 = FALSE | Disable correction; default enabled |
| level() | presentation extension | Confidence percentage; default 95 |

Preserve R design selection and numerical conventions. Report the effective
design and adjustment status. `cluster()` changes the assignment design and
must not be treated as a generic sandwich variance option.

Retain the legacy `sreg, y() d() s() x() g_id() ng() hc1(true|false)` interface.
Reject conflicting primary and legacy specifications rather than silently
choosing one. Final option abbreviation rules require parser tests.

Implement as an eclass command, with e(b), the full e(V), e(sample), design and
sample metadata, and replay. Verify lincom/test inference against the intended
asymptotic reference distribution. Do not invent off-diagonal covariances if
R's public result omits them; implement and validate the underlying formulas.

Factor-variable covariates are planned. Sample filtering, missing observations,
empty arms, collinearity and cluster/stratum consistency need explicit rules
and tests before implementation is considered stable. Audit R behavior first;
document any intentional Stata interface differences.
