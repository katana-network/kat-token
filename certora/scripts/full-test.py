#!/usr/bin/python3

import argparse
import glob
import json
import logging
import os
import pathlib
import re
import subprocess

# matches a commit hash
re_commit = re.compile('[0-9a-f]{40}')
# matches run links
re_link = re.compile('https://.*\\.certora\\.com/output/[0-9a-zA-Z?=/]+')
# matches alerts that are irrelevant
re_alerts_irrelevant = list(map(re.compile, [
        'will not be accessible in CVL code',
        'Summarization for internal calls .* is unused',
        'Summarization for external calls .* is unused',
        'Type .* has several conflicting declarations',
        'Conflicting types with name',
        'Syntax warning .* Passed `env` argument to an `envfree` method',
]))
# matches alerts to categories
re_alerts_categories = {
    'SLOWDOWN': list(map(re.compile, [
        'Memory partitioning failed while analyzing contract .* longer running times',
    ])),
    'MEMOUT': list(map(re.compile, [
        'Extremely low available memory',
    ])),
    'HARDTIMEOUT': list(map(re.compile, [
        'Reached global timeout',
    ])),
    'ERROR': list(map(re.compile, [
        'An internal Prover error occurred',
    ])),
}

__cleanup_commands = [
    'find ./ -iname "treeView" -exec rm -rf {} \\;',
    'find ./ -iname "*.tar.gz" -exec rm -rf {} \\;',
    'find ./ -iname "*.tac" -exec rm -rf {} \\;',
]

ARGS: argparse.Namespace = None

def __load_links():
    return json.load(open(ARGS.links))

def __execute(conf: pathlib.Path, msg: str, opts=[]):
    cmd = ['certoraRun', str(conf), '--msg', f'{ARGS.msg} {msg}', *opts]
    
    if ARGS.server is not None:
        cmd += ['--server', ARGS.server]
    if ARGS.group_id is not None:
        cmd += ['--group_id', ARGS.group_id]
    if ARGS.version is not None:
        if re_commit.match(ARGS.version) is None:
            cmd += ['--prover_version', ARGS.version]
        else:
            cmd += ['--commit_sha1', ARGS.version]

    logging.debug(f'running {' '.join(cmd)}')
    if ARGS.dry:
        return ''
    try:
        out = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.decode()
        logging.debug(out)
        return out
    except subprocess.CalledProcessError as e:
        logging.error(e)
        raise e

def __links(out: str):
    for m in re_link.finditer(out):
        yield m.group(0)

def __start_run_all(config: dict):
    re_filter = re.compile(ARGS.filter)
    for conf in ARGS.search.rglob('*.conf'):
        if re_filter.search(str(conf)) is None:
            continue
        c = config.get(conf.name, None)
        match c:
            case None:
                logging.info(f'combined for {conf.name}')
                yield from __links(__execute(conf, conf.name))
            case 'skip':
                logging.info(f'skipping {conf.name}')
            case 'individual-rules':
                logging.info(f'individually for {conf.name}')
                yield from __links(__execute(conf, f'{conf.name} individually', ['--split_rules', '*']))
            case _:
                logging.info(f'custom config for {conf.name}')
                for name,opts in c.items():
                    yield from __links(__execute(conf, f'{conf.name} {name}', opts))

def cmd_start():
    search = [
        ARGS.config,
        pathlib.Path(__file__).parent / ARGS.config,
    ]
    found = False
    for s in search:
        if s.exists():
            logging.info(f'loading config from {s}')
            config = json.load(open(s))
            found = True
            break
    if not found:
        logging.warning(f'config file {ARGS.config} does not exist')
        config = {}
    
    links = list(__start_run_all(config))
    if ARGS.keep_links:
        links = __load_links() + links
    if not ARGS.dry:
        json.dump(links, open(ARGS.links, 'w'), indent=4)

def cmd_download():
    links = __load_links()
    logging.info(f'loaded {len(links)} from {ARGS.links}')
    os.makedirs(ARGS.download_dir, exist_ok=True)

    for link in links:
        logging.info(f'downloading from {link} to {ARGS.download_dir}')
        if not ARGS.dry:
            subprocess.run(['fetch-files', link], cwd=ARGS.download_dir)
        for cmd in __cleanup_commands:
            logging.info(f'doing cleanup: {cmd}')
            if not ARGS.dry:
                subprocess.run(cmd, shell=True, cwd=ARGS.download_dir)

def __analyze_is_pattern(msg: str, patterns: list[re.Pattern]) -> bool:
    return any(pat.search(msg) is not None for pat in patterns)

def __analyze_categorize(msg: str):
    for name,patterns in re_alerts_categories.items():
        if __analyze_is_pattern(msg, patterns):
            return name
    return 'UNKNOWN'

def cmd_analyze():
    alerts = set()
    for alert in glob.iglob(f'{ARGS.download_dir}/{ARGS.alert_glob}', recursive=True):
        id = pathlib.Path(alert).parts[1]
        data = json.load(open(alert))
        for d in data:
            msg = d['message']
            if not __analyze_is_pattern(msg, re_alerts_irrelevant):
                alerts.add((id, msg))

    for id,msg in sorted(alerts):
        cat = __analyze_categorize(msg)
        if (not ARGS.verbose) and cat in ['SLOWDOWN']:
            continue
        logging.info(f'{cat} {id}: {msg}')

def parse_args():
    common = { 'formatter_class': argparse.ArgumentDefaultsHelpFormatter }
    parser = argparse.ArgumentParser(**common)
    parser.add_argument('-v', '--verbose', action='store_true', help='be more verbose')
    parser.add_argument('--dry', action='store_true', help='do not actually do anything')

    sub = parser.add_subparsers(required=True)
    
    sub_start = sub.add_parser('start', **common)
    sub_start.add_argument('--filter', type=str, default='.*', help='regex filter for job config files')
    sub_start.add_argument('--version', type=str, help='prover version of commit hash')
    sub_start.add_argument('--server', type=str, help='certora server')
    sub_start.add_argument('--msg', type=str, default='kat-token', help='job message')
    sub_start.add_argument('--group-id', type=str, default=None, help='group id for jobs')
    sub_start.add_argument('--config', type=pathlib.Path, default='.full_test.json', help='path to config file')
    sub_start.add_argument('--search', type=pathlib.Path, default='certora/confs/', help='search path for job config files')
    sub_start.add_argument('--links', type=pathlib.Path, default='.full_test_links.json', help='path for link file')
    sub_start.add_argument('--keep-links', action='store_true', help='append links instead of replace links')
    sub_start.set_defaults(func=cmd_start)

    sub_download = sub.add_parser('download', **common)
    sub_download.add_argument('--links', type=pathlib.Path, default='.full_test_links.json', help='path to link file')
    sub_download.add_argument('--download-dir', type=pathlib.Path, default='current-data', help='path for downloaded job info')
    sub_download.set_defaults(func=cmd_download)

    sub_analyze = sub.add_parser('analyze', **common)
    sub_analyze.add_argument('--download-dir', type=pathlib.Path, default='current-data', help='path to downloaded job info')
    sub_analyze.add_argument('--alert-glob', type=str, default='**/alertReport.json', help='glob pattern for alert reports')
    sub_analyze.set_defaults(func=cmd_analyze)

    global ARGS
    ARGS = parser.parse_args()

    if ARGS.verbose:
        logging.basicConfig(level = logging.DEBUG)
    else:
        logging.basicConfig(level = logging.INFO)

if __name__ == '__main__':
    parse_args()
    ARGS.func()