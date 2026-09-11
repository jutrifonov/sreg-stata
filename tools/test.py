#!/usr/bin/env python3
"""Reproducible R baseline and native Stata parity runner (development only)."""
import argparse
import csv
import hashlib
import json
import os
import platform
from pathlib import Path
import shutil
import subprocess
import sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / '.build'


def run(command, log):
    print('+', ' '.join(map(str, command)), flush=True)
    with (BUILD / log).open('w') as stream:
        result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError(f'{command[0]} failed; see .build/{log}')


def stata_run(binary, dofile, marker):
    done = BUILD / marker
    done.unlink(missing_ok=True)
    run([binary, '-b', 'do', dofile], Path(dofile).stem + '-process.log')
    # Stata batch can return zero even when the do-file failed.
    if not done.exists():
        raise RuntimeError(f'Stata did not finish {dofile}; inspect {Path(dofile).stem}.log')


def verify_upstream():
    manifest = json.loads((ROOT / 'reference/upstream-files.json').read_text())
    for relative, digest in manifest['sha256'].items():
        if hashlib.sha256((ROOT / 'tests/upstream' / relative).read_bytes()).hexdigest() != digest:
            raise RuntimeError(f'Upstream reference changed: {relative}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--r-only', action='store_true', help='Run only the R baseline; does not verify Stata')
    parser.add_argument('--reuse-r', action='store_true', help='Reuse local captured R calls for iteration')
    parser.add_argument('--stata', default=os.environ.get('STATA_BIN'))
    args = parser.parse_args()
    BUILD.mkdir(exist_ok=True)
    (BUILD / 'verification.json').unlink(missing_ok=True)
    verify_upstream()
    (BUILD / 'rlib').mkdir(exist_ok=True)
    if not args.reuse_r:
        run(['R', 'CMD', 'INSTALL', '--library=.build/rlib', 'tests/upstream'], 'r-install.log')
        run(['Rscript', 'tools/capture-r-tests.R', '.'], 'r-baseline.log')
    with (BUILD / 'captured/r-tests.csv').open() as f:
        baseline = list(csv.DictReader(f))
    if any(int(r['failed']) or r['error'] == 'TRUE' for r in baseline):
        raise RuntimeError('The upstream R baseline failed')
    verify_upstream()
    report = {'timestamp_utc': datetime.now(timezone.utc).isoformat(),
              'platform': platform.platform(),
              'r_version': (BUILD / 'captured/r-version.txt').read_text().strip(),
              'r_commit': json.loads((ROOT / 'reference/r-source.json').read_text())['commit'],
              'r_tests': len(baseline), 'r_assertions': sum(int(r['passed']) for r in baseline),
              'native_verified': False}
    if args.r_only:
        (BUILD / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
        print('R baseline passed. Native Stata tests were NOT run.')
        return
    binary = args.stata or next((shutil.which(x) for x in ('stata-mp', 'stata-se', 'stata') if shutil.which(x)), None)
    if not binary:
        raise RuntimeError('A licensed Stata executable is required. Set STATA_BIN or --stata.')
    run(['Rscript', 'tools/export-assertion-audit.R'], 'assertion-audit.log')
    run(['Rscript', 'tools/export-stata-fixtures.R', '.'], 'fixture-export.log')
    run(['Rscript', 'tools/export-internal-fixtures.R'], 'internal-export.log')
    run(['Rscript', 'tools/export-generator-fixtures.R'], 'generator-export.log')
    stata_run(binary, '.build/parity.do', 'parity.done')
    with (BUILD / 'parity-results.csv').open() as f:
        parity = list(csv.DictReader(f))
    with (BUILD / 'fixture-manifest.csv').open() as f:
        manifest = list(csv.DictReader(f))
    expected = sum(r['status'] == 'exported' for r in manifest)
    if len(parity) != expected or any(r['passed'] != '1' for r in parity):
        failed = [r['id'] for r in parity if r['passed'] != '1']
        raise RuntimeError(f'Parity failures: {failed}; completed {len(parity)}/{expected}')
    run([sys.executable, 'tools/verify-diagnostics.py'], 'diagnostics.log')
    run([sys.executable, 'tools/test-diagnostic-checker.py'], 'diagnostic-negative-controls.log')
    stata_run(binary, '.build/internal.do', 'internal.done')
    stata_run(binary, 'tests/stata/test-native.do', 'native.done')
    stata_run(binary, 'tests/stata/test-covariance.do', 'covariance.done')
    stata_run(binary, 'tests/stata/test-generator.do', 'generator.done')
    stata_run(binary, 'tests/stata/test-install.do', 'install.done')
    stata_run(binary, 'tests/stata/test-assertions.do', 'assertions.done')
    run([sys.executable, 'tools/verify-assertions.py'], 'assertion-verification.log')
    assertion_report = json.loads((BUILD / 'assertion-results.json').read_text())
    diagnostic_report = json.loads((BUILD / 'diagnostic-results.json').read_text())
    report.update(native_verified=True,
                  original_assertions_accounted=assertion_report['assertions'],
                  assertion_modes=assertion_report['modes'],
                  diagnostic_cases=diagnostic_report['cases'],
                  printed_field_checks=diagnostic_report['printed_field_checks'],
                  assertion_tests='passed', native_cases=len(parity),
                  stata_version=(BUILD / 'stata-version.txt').read_text().strip(),
                  numerical_cases=sum(r['kind'] == 'numerical' for r in parity),
                  error_cases=sum(r['kind'] == 'error' for r in parity),
                  r_container_cases=sum(r['status'] != 'exported' for r in manifest),
                  native_interface_tests='passed', internal_helper_tests='passed',
                  covariance_tests='passed', installation_tests='passed', generator_tests='passed',
                  tolerance='1e-8 * (1 + abs(R value))')
    (BUILD / 'verification.json').write_text(json.dumps(report, indent=2) + '\n')
    run([sys.executable, 'tools/audit-tests.py'], 'test-audit.log')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError) as exc:
        print(f'FAILED: {exc}', file=sys.stderr)
        sys.exit(1)
