#!/usr/bin/env python3
"""Audit measured numerical differences; counts are not inferred from tolerance."""
import csv,json,math,statistics
from pathlib import Path
from collections import Counter,defaultdict
root=Path(__file__).resolve().parents[1]
build=root/'.build'
def read(name):
    with (build/name).open() as f:return list(csv.DictReader(f))
rows=read('numerical-values.csv')
groups=defaultdict(list)
for row in rows:
    r,s=float(row['reference']),float(row['stata'])
    if not math.isfinite(r) or not math.isfinite(s):raise ValueError(row)
    row.update(reference=r,stata=s,absolute_error=abs(s-r),scaled_error=abs(s-r)/(1+abs(r)))
    groups[row['metric']].append(row)
metrics={}
for name,rr in groups.items():
    worst=max(rr,key=lambda x:x['absolute_error'])
    metrics[name]={'comparisons':len(rr),'max_absolute_error':worst['absolute_error'],
        'max_scaled_error':max(r['scaled_error'] for r in rr),
        'median_absolute_error':statistics.median(r['absolute_error'] for r in rr),
        'worst_call':int(worst['id']),'worst_index':worst['index'],
        'reference_at_worst':worst['reference'],'stata_at_worst':worst['stata']}
manifest=read('fixture-manifest.csv')
parity=read('parity-results.csv')
expectations=read('r-assertion-audit.csv')
verification=json.loads((build/'verification.json').read_text())
report={'verification_timestamp':verification['timestamp_utc'],
        'r_cases':verification['r_tests'],'r_assertions':len(expectations),
        'r_expectation_types':dict(Counter(x['expectation'] for x in expectations)),
        'stata_replay_cases':len(parity),'stata_replay_kinds':dict(Counter(x['kind'] for x in parity)),
        'stata_additional_suites':['internal helpers','native interface and plots','analytic covariance','generator','installation'],
        'scalar_numerical_comparisons':len(rows),'numerical_metrics':metrics,
        'r_print_text_expectations':sum(x['test'].startswith('print.sreg') and 'grepl(' in x['source'] for x in expectations),
        'case_mapping_note':'R cases are uniquely identified by execution order; repeated descriptions do not merge cases.',
        'coverage_limit':'A case-level mapping is not a one-to-one implementation of every R expectation. Error replay checks nonzero return codes; print-text, ggplot class and R containers have partial or native equivalents.',
        'rng_note':'Estimator replay uses identical R-generated inputs in Stata. Independently generated R/Stata samples are not expected to match numerically.'}
assert all(x['passed']=='1' for x in parity)
assert all(r['scaled_error']<=1e-8 for r in rows)
r_cases=read('captured/r-tests.csv')
for call in manifest:
    case_id=int(call['test_id'])
    if case_id:
        assert call['file']==r_cases[case_id-1]['file'] and call['test']==r_cases[case_id-1]['test']
assert len(groups['estimate'])==len(groups['se'])
assert len(set(r['id'] for r in rows))==sum(x['kind']=='numerical' for x in parity)
assert len(expectations)==verification['r_assertions']
# Every exported call must belong to exactly one source case, or documentation.
assert all(0<=int(x['test_id'])<=verification['r_tests'] for x in manifest)
(build/'test-audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
