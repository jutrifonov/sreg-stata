#!/usr/bin/env python3
"""Executable disposition for every original R expectation; unknown cases fail."""
import csv,json,re,importlib.util
from collections import Counter
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
B=ROOT/'.build'
def read(name):
    with (B/name).open() as f:return list(csv.DictReader(f))
def require(condition, detail):
    if not condition:raise AssertionError(detail)
def main():
    for name in ('parity','internal','native','covariance','generator','install','assertions'):
        require((B/f'{name}.done').exists(),f'Missing {name} completion')
    diagnostic=json.loads((B/'diagnostic-results.json').read_text())
    checked={str(r['id']):r for r in diagnostic['results']}
    manifest={r['id']:r for r in read('fixture-manifest.csv')}
    expected={r['id']:r for r in read('diagnostic-expectations.csv')}
    values={}
    for r in read('numerical-values.csv'):
        values.setdefault((r['id'],r['metric']),[]).append(r)
    # Exact native diagnostics for all generator errors in the original tests.
    reasons=['allocation() must have strata() rows and one column per arm including control.',
        'stratumeffects() must contain one finite value per stratum.',
        'Custom allocations and effects require individual large strata.',
        'nsmall() must be positive, smaller than n(), and divisible by k().',
        'The large component must contain more than strata()*k() units.',
        'treatsizes() must contain one nonnegative integer per arm, including control, summing to k().']
    for i,reason in enumerate(reasons,1):
        require(reason in (B/f'generator-error-{i}.log').read_text(),('generator diagnostic',i))
    for variable in ('Y','S','D','G_id','Ng','x1'):
        require(f'{variable} is a string variable' in (B/f'container-{variable}.log').read_text(),('container diagnostic',variable))
    require('too few strata qualify as small' in (B/'classifier-error.log').read_text(),'classifier reason')
    rows=read('r-assertion-audit.csv')
    require(all(x['result']=='expectation_success' for x in rows),'R expectation failure')
    ledger=[]
    for row in rows:
        case=int(row['test_id']); source=row['source']; kind=row['expectation']; call=row['call_id']
        record={'test_id':case,'assertion':int(row['assertion']),'r_file':row['file'],
            'r_line':int(row['line']),'expectation':kind,'call_id':int(call) if call in manifest and int(manifest[call]['test_id'])==case else None,
            'status':'passed','mode':'native-semantic','check':''}
        if row['file']=='test-core.R' and case<32 and case!=19:
            require(call in manifest and int(manifest[call]['test_id'])==case,(case,call,'assertion link'))
            if kind=='expect_equal':
                match=re.search(r'round\(result\$(tau\.hat|se\.rob),\s*(\d+)\),\s*c\(([^)]*)\)',source)
                require(match,(case,source))
                metric='estimate' if match[1]=='tau.hat' else 'se'
                actual=sorted(values[(call,metric)],key=lambda x:int(x['index']))
                target=[float(x.strip()) for x in match[3].split(',')]
                require(len(actual)==len(target),(case,call,'length'))
                for got,want in zip(actual,target):
                    require(abs(round(float(got['stata']),int(match[2]))-want)<1e-12,(case,call,got,want))
                record.update(mode='direct-original-expectation',check='Original hard-coded rounded vector checked against measured Stata output')
            elif kind=='expect_error':
                if manifest[call]['status']=='exported':
                    require(checked[call]['error_checks']==2,(case,call))
                    record['check']='Per-call native diagnostic reason and exact return code'
                else:
                    record.update(mode='native-interface-adaptation',check='R list/character rejection mapped to numeric-variable rejection; six argument-specific logs and rc=109')
            elif kind in ('expect_warning','expect_silent','expect_true'):
                require(checked[call]['warning_checks']==1,(case,call))
                record['check']='Complete expected warning-category set, exact native message text, detected k, and no unexpected warning categories'
                if kind=='expect_silent' or 'regexp = NA' in source:
                    record['mode']='native-interface-adaptation'
                    record['check']+='; R capture/muffle wrappers mapped to native command boundary'
            else:raise AssertionError((case,kind,source))
        elif case in (32,33):
            require(call in checked and checked[call]['output_checks']>0,(case,call))
            if kind=='expect_warning':
                record['check']='Printed-case estimator warning set and exact native messages'
            else:
                require(kind=='expect_true' and 'grepl(' in source,(case,source))
                literal=re.search(r'grepl\(("(?:\\.|[^"\\])*")',source)
                require(literal,(case,source))
                pattern=json.loads(literal[1])
                if pattern.startswith('Signif. codes:'):
                    require((call,'p') in values,(case,call))
                    record.update(mode='native-format-adaptation',check='R star-code legend intentionally omitted; native continuous p-values and inference table verified')
                elif pattern.startswith('Covariates used in linear adjustments:'):
                    record.update(mode='native-format-adaptation',check='Exact printed Stata covariate list verified; exported column names replace R display names')
                elif pattern.startswith('Strata size'):
                    digits=re.search(r': (\d+)',pattern)
                    require(digits and digits[1]==expected[call]['k'],(case,call,pattern))
                    record.update(mode='native-format-adaptation',check='Original k value checked against native printed Strata size (k, small strata) field')
                elif pattern.startswith('Setup: mixed design'):
                    require(expected[call]['design']=='mixed design',(case,call))
                    record.update(mode='native-format-adaptation',check='Native mixed-design label checked; R explanatory suffix omitted')
                else:
                    text=(B/f'call-logs/case-{int(call):04d}.log').read_text()
                    text=re.sub(r'(?<=\d),(?=\d{3}\b)','',text)
                    text=' '.join(text.split())
                    require(re.search(pattern,text),(case,call,pattern))
                    record.update(mode='direct-original-expectation',check='Original R printed-output pattern checked against native output with numeric spacing normalized')
        elif case==34:
            require((B/'sreg-test.gph').stat().st_size>0 and (B/'sreg-test.svg').stat().st_size>0,'native graph')
            record.update(mode='native-interface-adaptation',check='R ggplot class replaced by native saved graph and SVG, with dataset/results preservation tests')
        elif case==19:
            record.update(mode='native-interface-adaptation',check='R internal n.treat mismatch cannot be supplied; native arm count is derived from tau and explicitly tested')
        elif case in (1,6,8):
            record['check']='Direct helper fixtures: reference values, positive finite variance, shuffled cluster rows, and corrected variance greater than legacy formula'
        elif case in (35,36,37):
            record['check']='Actual estimation classifier: exact small/large flags, exact k-specific warning text, and failure reason with rc=498'
        elif case in (2,3,4,5,7,9,38,39,40,41,42,43,44,45):
            # Multiple fits inside one source test are all replayed and checked.
            cases=[c for c in manifest.values() if int(c['test_id'])==case and c['status']=='exported']
            require(cases and all(c['id'] in checked for c in cases),(case,'missing native cases'))
            if kind=='expect_error':record['check']='Expected native diagnostic reason and return code for the source-case failures'
            elif kind in ('expect_warning','expect_silent'):record['check']='Exact native warning text and expected warning set for all source-case fits'
            else:record['check']='All source-case fits: numerical vectors, finite SEs, adjustment-matrix dimensions, component counts, detected k, and population share checked against R'
        elif 46<=case<=55:
            record['mode']='native-generator-adaptation'
            record['check']={46:'Covariate column presence/absence and required cluster output columns',
                47:'Seed reproducibility and explicit native defaults; R NULL options represented by omission',
                48:'Exact floor(p*n_s) treatment counts in each of five strata',
                49:'Shared-seed S and D identities and exact custom outcome shifts to 1e-12',
                50:'Matching allocation/effect validation reason and rc=198',
                51:'120 individuals, exactly 30 small strata, at least one large stratum, all arms, and mixed estimator integration',
                52:'120 unique consistent clusters, exactly 30 small strata, at least one large stratum, and mixed estimator integration',
                53:'Matching component-size/treatment-count validation reason and rc=198',
                54:'Default path and explicit native defaults are seed-identical; mixed=FALSE is native option omission',
                55:'Every small stratum has three units, two controls and one treated unit'}[case]
        else:raise AssertionError(('Unmapped original expectation',row))
        require(record['check'],record)
        ledger.append(record)
    require(len(ledger)==563 and len({x['test_id'] for x in ledger})==55,'Reference inventory changed; review required')
    out={'assertions':len(ledger),'r_cases':55,'passed':len(ledger),
         'modes':dict(Counter(x['mode'] for x in ledger)),
         'note':'Every expectation has an executed check or explicit native semantic/format adaptation. This does not claim identical R objects, formatting, RNG streams, or internal API.',
         'assertions_detail':ledger}
    (B/'assertion-results.json').write_text(json.dumps(out,indent=2)+'\n')
    print({k:v for k,v in out.items() if k!='assertions_detail'})
if __name__=='__main__':main()
