# Assertion-level verification

Every one of the pinned R suite's **563 executed expectations in 55 test cases**
now has an executable disposition in `assertion-results.json`. The standard
`python3 tools/test.py` command requires these checks to pass. This is a native
semantic port: it deliberately distinguishes literal checks from adaptations
of R's containers, printed formatting, warning machinery, and random streams.

| Disposition | Expectations | Verification |
| --- | ---: | --- |
| Direct original expectation | 245 | 134 original rounded numerical vectors and 111 original printed-output patterns checked against Stata output |
| Native semantic equivalent | 197 | Estimation, diagnostics, classifier, components, and helper checks |
| Native interface adaptation | 44 | Numeric-variable validation, graph outputs, derived arm count, and R capture/muffle wrappers |
| Native format adaptation | 42 | Covariate names, k/mixed labels, and the R significance-code legend |
| Native generator adaptation | 35 | Design counts, reproducibility, custom effects, validation, and output columns using Stata's RNG |

These are counts of **original R expectations accounted for**, not a claim that
563 independent Stata scenarios exist or that all 563 execute verbatim R text.
The machine-readable ledger gives each expectation's source file, line, ordinal,
linked estimator call where applicable, mode, and native verification method.
An unknown expectation or changed inventory fails rather than receiving an
unreviewed coverage label. Original R tests and source remain unmodified.

## Diagnostics and printed output

All 235 estimator replay cases now produce separate native text logs. The
checker verifies the specific native error reason and exact return code for
all 74 expected failures. For all 161 successful cases it verifies the complete
expected set of warning categories, exact native warning sentences, detected k,
and absence of unexpected warning categories. It also performs **1,439 printed
field checks**, including titles, sample and cluster counts, treatment count,
stratum count, design, HC1 setting, covariate list, and small-stratum k.

The 153 original print-string expectations are accounted for by 111 direct
pattern checks and 42 explicit format adaptations. Stata's numeric spacing and
thousands separators are normalized. The original R tests check rounded
constants; those constants are now checked directly against the measured Stata
values, in addition to the existing full-precision R/Stata comparisons.

Native warning wording uses Stata option names. Repeated R warnings from
recursive/per-arm calculations are compared as distinct semantic categories;
warning multiplicity and order are not required to match. Two overlapping R
constant-covariate warnings map to the same native fallback message. R's
`capture.output`/`muffleWarning` wrappers are caller-side behavior, so their
native equivalent checks the command's expected diagnostic set rather than
requiring a normally displayed Stata estimation command to print nothing.

The checker has eight negative controls: intentionally wrong error reason,
return code, sample count, title, missing warning, unexpected warning,
wrong warning explanation, and wrong detected k must all be rejected. These
controls guard against the former “any nonzero code passes” weakness.

## Additional structural checks

- The classifier tests now call the same helper used by estimation and verify
  exact small/large membership flags, k-specific warning text, and rejection
  reason. This supplements the earlier modal-size checks.
- Mixed fits check assignment-unit counts in both components and the population
  share against R, alongside component estimates, variances, and slope matrices.
- The cluster-variance regression checks explicitly require the native corrected
  result to exceed the original legacy formula. Small-cluster variance checks
  require positive finite standard errors.
- Generator tests require exactly 30 small strata and at least one larger
  stratum in the original mixed scenarios. Original generator failures now
  require their specific native reason and return code.
- Native wrong-type checks cover every numeric input argument separately.
  Explicit defaults reproduce the default generator path under a fixed seed.

## Deliberate adaptations that remain

R list/data-frame/S3 classes do not exist in the Stata API. The ggplot-class
assertion maps to native graph creation and data/result preservation. R's
internal n.treat/theta mismatch cannot be supplied because native arm count
is derived from tau; this derivation is tested explicitly. R's star-code legend
is omitted in favor of Stata's continuous p-value table, which is checked.
Exported fixture covariates have native column names rather than R display names.

Generator checks use exact design constraints and same-runtime reproducibility;
identical numeric seeds do not imply identical R/Stata datasets. Deliberate
estimator/generator bug fixes remain documented in `docs/estimators.md` and
`docs/generator.md`. None of these adaptations is labeled a verbatim R check.

The optional Monte Carlo study remains a limited sampling diagnostic. Passing
this suite does not prove correctness for every possible dataset or provide
multi-platform/version certification.
