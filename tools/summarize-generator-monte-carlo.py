#!/usr/bin/env python3
"""Summarize the optional independent-stream sampling diagnostic."""
import csv,json,math,statistics
from pathlib import Path
root=Path(__file__).resolve().parents[1]
build=root/'.build'
if not (build/'generator-mc.done').exists():
    raise SystemExit('Native Monte Carlo completion marker is missing')
x={}
for language in ('r','stata'):
    with (build/f'generator-mc-{language}.csv').open() as f:rows=list(csv.DictReader(f))
    assert len(rows)==200
    x[language]={}
    for design in ('individual','cluster'):
        rr=[r for r in rows if r['design']==design]
        estimates=[float(r['estimate']) for r in rr]
        ses=[float(r['se']) for r in rr]
        assert len(rr)==100 and {int(r['replicate']) for r in rr}==set(range(1,101))
        assert all(math.isfinite(v) for v in estimates+ses) and min(ses)>0
        x[language][design]={'replicates':len(rr),'mean_estimate':statistics.mean(estimates),
            'empirical_sd':statistics.stdev(estimates),'mean_reported_se':statistics.mean(ses),
            'coverage_95':sum(abs(v-.5)<=1.95996398454*se for v,se in zip(estimates,ses))/len(rr)}
comparisons={}
for design in ('individual','cluster'):
    r,s=x['r'][design],x['stata'][design]
    se=math.sqrt((r['empirical_sd']**2+s['empirical_sd']**2)/100)
    difference=s['mean_estimate']-r['mean_estimate']
    comparisons[design]={'stata_minus_r_mean':difference,'mc_standard_error_of_difference':se,
        'mc_95_interval':[difference-1.96*se,difference+1.96*se]}
out={'true_effect':.5,'replicates_per_language_per_design':100,'large_strata':4,
     'individual_n':1200,'cluster_n':200,'adjusted':True,'results':x,'comparison':comparisons,
     'scope':'Exploratory sampling diagnostic for two large-strata designs, not a complete distributional proof or a zero-difference assertion.'}
(build/'generator-mc-summary.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
