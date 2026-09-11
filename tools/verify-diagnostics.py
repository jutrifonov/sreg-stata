#!/usr/bin/env python3
"""Fail-closed verification of native diagnostic reasons and visible output."""
import csv,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
B=ROOT/'.build'
# R fragments map to native diagnostics; unknown reference reasons must be reviewed.
ERRORS=[
('value of HC','hc1() must be true or false.',198),
('Variable S must contain only integer','Strata and treatment must contain only integer values.',498),
('Variable D must contain only integer','Strata and treatment must contain only integer values.',498),
('strata should be indexed','The strata should be indexed by {1, 2, 3, ...}.',498),
('treatments should be indexed','The treatments should be indexed by {0, 1, 2, ...}, with control coded 0.',498),
('Observed outcomes have not been provided','Observed outcomes have not been provided; specify y().',198),
('Treatments have not been provided','Treatments have not been provided; specify treatment().',198),
('Variable Ng must contain only integer','Cluster sizes must contain only integer values.',498),
('Variable G.id must contain only integer','Cluster identifiers must contain only integer values.',498),
('too many covariates relative','There are too many covariates relative to the number of observations, or adjustment regressions are unidentified.',498),
('skipped values in the range','Variables S and D must not contain skipped values within the range.',498),
('must be consistent within each cluster','The values for S, D, and Ng must be consistent within each cluster.',498),
('Strata indicator variable has not been provided','Strata indicator variable has not been provided; smallstrata requires strata().',498),
("too few strata qualify as 'small'",'Invalid input: Either all strata are large or too few strata qualify as small.',498),
('value of small.strata','option invalidsmallstrata not allowed',198),
('does not match the observed stratum size','The supplied small-stratum size k does not match the observed stratum size.',498),
('k must be NULL or a positive integer','k() must be a positive integer.',198),
('large-strata component of the mixed design cannot support','The large-strata component of the mixed design cannot support the requested covariate adjustment.',498),
]
WARNINGS=[('Mixed design detected','mixed'),('Cluster sizes have not been provided','inferred_sizes'),
('ignoring these values','missing'),('covariates do not vary','constant_covariates'),
('individual-level covariates','aggregated_covariates'),('All strata have the same small number','uniform_small'),
('At least 25% of strata','some_small'),('HC1 adjustment unstable','hc1_fallback')]
NATIVE_WARNINGS={
 'inferred_sizes':'Cluster sizes have not been provided; using the number of available observations in every cluster.',
 'missing':'The data contains missing values; proceeding while ignoring these values.',
 'constant_covariates':'One or more covariates do not vary within one or more stratum-treatment combinations. Proceeding with the unadjusted estimator.',
 'aggregated_covariates':'sreg cannot use individual-level covariates for cluster adjustment; covariates have been aggregated to their cluster-level averages.',
 'uniform_small':'All strata have the same small number of assignment units, but smallstrata was not specified.',
 'some_small':'At least 25% of strata are small, but smallstrata was not specified; consider the small/mixed procedure.',
 'hc1_fallback':'HC1 adjustment unstable or undefined due to degenerate strata-treatment structure; reverting to unadjusted estimator.'}
def warn_category(text):
    matches=[name for fragment,name in WARNINGS if fragment in text]
    if len(matches)!=1: raise ValueError(f'Unmapped warning: {text}')
    return matches[0]
def check_case(row, text):
    # Stata log continuation prompts are formatting, not message content.
    text=re.sub(r'\n>\s*',' ',text)
    compact=' '.join(text.split())
    if row['error']:
        matches=[(native,code) for fragment,native,code in ERRORS if fragment in row['error']]
        assert len(matches)==1, (row['id'],row['error'])
        native,code=matches[0]
        assert native in compact, (row['id'],'wrong error reason',native,compact)
        assert re.search(rf'^__SREG_RC__ {code}$',text,re.M), (row['id'],'wrong return code',code)
        return {'id':row['id'],'error_checks':2,'warning_checks':0,'output_checks':0}
    native_warnings=re.findall(r'^Warning: (.*)$',text,re.M)
    for warning in native_warnings:
        category=warn_category(warning)
        if category=='mixed':
            assert re.fullmatch(r'Mixed design detected: at least 25% of all strata have the same size \(k = \d+\). Weighted estimators will be used\.',warning),(row['id'],warning)
        else:
            assert warning==NATIVE_WARNINGS[category],(row['id'],'warning text',warning)
    expected={warn_category(w) for w in row['warnings'].splitlines() if w}
    actual={warn_category(w) for w in native_warnings}
    assert actual==expected,(row['id'],'warning categories',expected,actual)
    for w in row['warnings'].splitlines():
        if 'Mixed design detected' in w:
            kval=re.search(r'k = (\d+)',w).group(1)
            assert any('Mixed design detected' in z and f'k = {kval}' in z for z in native_warnings)
    title='Saturated Model Estimation Results under CAR'
    if row['adjusted']=='TRUE':title+=' with linear adjustments'
    assert re.search('^'+re.escape(title)+'$',text,re.M),(row['id'],'title')
    expected_lines={'Observations':row['n'],'Number of treatments':row['arms'],
        'Number of strata':row['strata'],'Setup':row['design'],
        'Standard errors':'adjusted (HC1)' if row['hc']=='TRUE' else 'unadjusted',
        'Treatment assignment':'cluster level' if int(row['clusters']) else 'individual level',
        'Covariates used in linear adjustments':row['covariates']}
    if int(row['clusters']):expected_lines['Clusters']=row['clusters']
    if int(row['k']):expected_lines['Strata size (k, small strata)']=row['k']
    for label,value in expected_lines.items():
        match=re.search(r'^'+re.escape(label)+r':([^\n]*)$',text,re.M)
        assert match,(row['id'],'missing printed field',label)
        actual=' '.join(match[1].strip().split())
        if label in ('Observations','Number of treatments','Number of strata','Clusters'):actual=actual.replace(',','')
        assert actual==value,(row['id'],label,value,actual)
    return {'id':row['id'],'error_checks':0,'warning_checks':1,'output_checks':len(expected_lines)+1}
def main():
    with (B/'diagnostic-expectations.csv').open() as f:expected=list(csv.DictReader(f))
    results=[]
    for row in expected:
        text=(B/f"call-logs/case-{int(row['id']):04d}.log").read_text()
        results.append(check_case(row,text))
    out={'cases':len(results),'error_cases':sum(r['error_checks']>0 for r in results),
         'successful_cases':sum(r['output_checks']>0 for r in results),
         'error_checks':sum(r['error_checks'] for r in results),
         'warning_set_checks':sum(r['warning_checks'] for r in results),
         'printed_field_checks':sum(r['output_checks'] for r in results),'results':results}
    (B/'diagnostic-results.json').write_text(json.dumps(out,indent=2)+'\n')
    print({k:v for k,v in out.items() if k!='results'})
if __name__=='__main__':main()
