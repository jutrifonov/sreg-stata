# Implementation and validation plan

The package implements large-, small- and mixed-strata estimators for
individual and cluster assignment, multiple treatments, covariate adjustment
and finite-sample variance corrections.

Validation covers fixed-data numerical results, analytic covariance examples,
warnings and errors, singular adjustment, unequal cluster sizes, general
k-tuples, sample marking, saved results, replay, plotting and installation.
Generator validation checks design constraints and distributional properties.

The installed package executes entirely in Stata/Mata. Full native validation
requires licensed Stata; unavailable execution must not be reported as passing.
