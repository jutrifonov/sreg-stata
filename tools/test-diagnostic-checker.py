#!/usr/bin/env python3
"""Negative controls: prove the log checker rejects the former false positives."""
import csv,importlib.util,json,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
build=root/'.build'
spec=importlib.util.spec_from_file_location('diagnostics',root/'tools/verify-diagnostics.py')
d=importlib.util.module_from_spec(spec);spec.loader.exec_module(d)
with (build/'diagnostic-expectations.csv').open() as f: rows=list(csv.DictReader(f))
success=next(x for x in rows if not x['error'] and x['warnings'])
error=next(x for x in rows if x['error'])
def log(row):return (build/f"call-logs/case-{int(row['id']):04d}.log").read_text()
base=log(success);failure=log(error)
checks=[]
def rejects(name,row,text):
    try:d.check_case(row,text)
    except (AssertionError,ValueError):checks.append(name)
    else:raise AssertionError(f'Checker accepted mutation: {name}')
d.check_case(success,base);d.check_case(error,failure)
rejects('wrong error reason with original nonzero code',error,failure.replace('hc1() must be true or false.','Unrelated failure.'))
rejects('wrong error return code',error,failure.replace('__SREG_RC__ 198','__SREG_RC__ 498'))
rejects('wrong printed sample count',success,re.sub(r'^(Observations:\s*)[\d,]+',r'\g<1>999999',base,flags=re.M))
rejects('wrong adjusted/unadjusted title',success,base.replace('Saturated Model Estimation Results under CAR','Unrelated title'))
rejects('missing required warning',success,'\n'.join(line for line in base.splitlines() if not line.startswith('Warning:')))
rejects('unexpected warning category',success,base+'\nWarning: unknown warning\n')
rejects('wrong warning wording with correct category',success,base.replace('Weighted estimators will be used.','Incorrect explanation.'))
rejects('wrong detected k',success,base.replace('(k = 3)','(k = 99)'))
(build/'diagnostic-negative-controls.json').write_text(json.dumps({'rejected_mutations':checks},indent=2)+'\n')
print(f'{len(checks)} deliberately broken outputs rejected')
