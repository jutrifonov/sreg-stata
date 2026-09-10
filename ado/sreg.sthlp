{smcl}
{* *! version 0.1.0 10sep2026}{...}
{title:Title}

{p 4 4 2}
{cmd:sreg} {hline 2} Treatment effects in stratified randomized experiments

{title:Syntax}

{p 8 12 2}
{cmd:sreg} {it:outcome} [{it:covariates}] {ifin},
{opt treatment(varname)} [{opt strata(varname)} {opt cluster(varname)}
{opt clustersize(varname)} {opt smallstrata} {opt k(#)} {opt nohc1}
{opt level(#)}]

{p 4 4 2}
Covariates may include factor variables and interactions. The outcome and
assignment/design variables must be numeric. Treatment is coded 0, 1, ..., A;
0 is control. Strata are coded 1, 2, ..., S. Gaps are not allowed in these
codes in the estimation sample. Cluster IDs may be arbitrary integers.

{title:Description}

{p 4 4 2}
{cmd:sreg} estimates each active treatment's average effect relative to control.
It is a native Stata/Mata port of R sreg 2.1.0, reference commit fe1b662.
No R or Python installation is required to use the command.

{p 4 4 2}
Supported procedures are large-strata, small-strata and mixed-design
estimators, under individual or cluster assignment, with multiple treatments,
optional linear covariate adjustment and the design-specific HC1 correction.
Inference uses the standard normal distribution. Stata therefore labels
the test statistic z, although the R result calls it t.stat.

{title:Options}

{phang}
{opt treatment(varname)} specifies randomized treatment assignment, not an
adjustment covariate. It is required.

{phang}
{opt strata(varname)} specifies randomization strata. If omitted, one stratum
is used. Every arm must be present in every stratum used by an estimator.

{phang}
{opt cluster(varname)} specifies the randomization unit. It changes the
estimator as well as its variance and is not a generic clustered standard
error option. Outcomes are averaged over available observations in a cluster;
covariates are replaced with cluster means. Treatment, stratum and represented
cluster size must be constant within cluster.

{phang}
{opt clustersize(varname)} specifies represented population sizes, one positive
integer value repeated within each cluster. These can differ from the number
sampled. If omitted, the number of complete observations per cluster is used,
with a warning. Cluster expanded outcomes equal size times mean outcome.

{phang}
{opt smallstrata} enables small/mixed design selection. Without this option,
the large-strata estimator is used. A common observed stratum size selects
the small-strata estimator. With varying sizes, at least 25% of strata must
share a qualifying size; that modal size defines the small component.
The default qualifying sizes are at most 3. Supply {opt k()} for larger tuples.
Ties select the smaller size. The remaining strata form the large component.

{phang}
{opt k(#)} specifies units per small stratum, or clusters per small stratum
under cluster assignment. In uniform designs it validates the observed size.
It does not itself enable {opt smallstrata}. Adjacent strata, in numeric
stratum order, are paired for small-strata variance estimation. An even
number of small strata is required. This ordering must correspond to the
design's intended pairing; row sorting does not define the pairs.

{phang}
{opt nohc1} disables the R design-specific finite-sample correction. HC1 is
enabled by default. For large strata it scales the within-stratum variance
by n/[n-S(A+1)], using assignment-unit counts. For small strata it uses
B/[B-p-1], where B is the number of small strata and p the adjustment dimension;
the unadjusted individual small-strata estimator does not apply that factor.
The cluster small-strata estimator does apply it, including when p=0.

{phang}
{opt level(#)} sets the confidence percentage; the default is 95.
{cmd:sreg, level(90)} replays stored estimates with 90% intervals.

{title:Adjustment, missing data and diagnostics}

{p 4 4 2}
In large-strata estimation, covariate slopes are estimated separately for each
treatment-by-stratum cell. As in R, lack of variation in any requested
covariate in a cell causes a warning and fallback to the unadjusted estimator.
Unidentified regressions produce an error. Small-strata adjustment regresses
within-stratum treatment-control outcome differences on covariate differences.
Mixed-design adjustment is applied to both components; an unidentified large
component is an error rather than a silent fallback.

{p 4 4 2}
Complete-case selection is applied to outcome, covariates and supplied design
variables after {cmd:if}/{cmd:in}. It can change observed stratum and cluster
sizes. Use {cmd:e(sample)} to inspect the selected sample. The dataset and
observation order are preserved. Negative or nonfinite variance estimates
and odd small-stratum counts are reported as errors rather than valid inference.

{title:Saved results}

{p 4 4 2}
{cmd:e(b)} contains {cmd:tau1}, ..., {cmd:tauA}. {cmd:e(V)} contains their full
covariance matrix. {cmd:lincom}, {cmd:test}, {cmd:estimates store} and
{cmd:estimates restore} are supported. Prediction and {cmd:margins} are not
implemented. The off-diagonal covariance extends R's public output using the
same influence terms and paired-strata moments; see docs/estimators.md.

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(N)}}number of complete individual observations{p_end}
{synopt:{cmd:e(N_units)}}number of assignment units{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters, for cluster assignment{p_end}
{synopt:{cmd:e(N_strata)}}number of strata{p_end}
{synopt:{cmd:e(N_treatments)}}number of active treatment arms{p_end}
{synopt:{cmd:e(HC1)}}requested HC1 setting{p_end}
{synopt:{cmd:e(adjusted)}}whether adjustment was used{p_end}
{synopt:{cmd:e(smallstrata)}}requested small-strata setting{p_end}
{synopt:{cmd:e(k)}}detected small-stratum size{p_end}
{synopt:{cmd:e(beta)}}adjustment slopes when used{p_end}
{synopt:{cmd:e(design)}}large strata, small strata or mixed design{p_end}
{synopt:{cmd:e(warnings)}}diagnostic messages from estimation{p_end}
{synopt:{cmd:e(sample)}}estimation sample indicator{p_end}

{p 4 4 2}
Mixed fits additionally save {cmd:e(b_small)}, {cmd:e(V_small)},
{cmd:e(b_large)}, {cmd:e(V_large)}, {cmd:e(p_small)}, {cmd:e(N_small)} and
{cmd:e(N_large)}. The counts are assignment units, while {cmd:e(p_small)} is
the represented individual population share. {cmd:e(beta)} is the small
component's slopes for mixed fits. Component-share uncertainty is included
in the combined covariance.

{p 4 4 2}
Adjusted mixed fits also save {cmd:e(beta_small)} and {cmd:e(beta_large)}.
For large-component slopes, rows are ordered by stratum, then treatment arm
(control first). Columns follow {cmd:e(adjustment_terms)}.

{title:Examples}

{phang2}{cmd:. sreg earnings baseline age, treatment(assignment) strata(block)}{p_end}
{phang2}{cmd:. sreg earnings baseline, treatment(assignment) strata(block) cluster(village) clustersize(population)}{p_end}
{phang2}{cmd:. sreg earnings baseline, treatment(assignment) strata(pair) smallstrata}{p_end}
{phang2}{cmd:. sreg earnings, treatment(assignment) strata(block) smallstrata k(4)}{p_end}
{phang2}{cmd:. lincom tau2 - tau1}{p_end}
{phang2}{cmd:. sregplot, xtitle("ATE relative to control")}{p_end}

{title:Legacy syntax}

{p 4 4 2}
Existing {cmd:sreg, y(Y) d(D) s(S) x(X1 X2) g_id(G) ng(Ng) hc1(true)}
calls remain supported. Do not mix the two syntaxes. Legacy {cmd:ng()} without
{cmd:g_id()} is included in complete-case selection but otherwise ignored,
matching R. Primary {cmd:clustersize()} requires {cmd:cluster()}.

{title:References and authors}

{p 4 4 2}
Original sreg authors: Juri Trifonov, Yuehao Bai, Azeem Shaikh and Max
Tabord-Meehan. See the pinned R reference documentation for the full
bibliography: Bugni et al. (2018); Bugni et al. (2024+); Jiang et al. (2023+);
Bai et al. (2024); Bai (2022); Bai et al. (2022); Liu (2024); Cytrynbaum (2024).

{p 4 4 2}
{browse "https://github.com/jutrifonov/sreg-stata":Native Stata repository}
{break}
{browse "https://github.com/jutrifonov/sreg":R reference repository}

{title:Also see}
{p 4 4 2}{help sregplot}, {help lincom}, {help test}, {help estimates}{p_end}
