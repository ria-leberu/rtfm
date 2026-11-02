"""Build sourced metadata offline; never execute upstream Lua or SQL.

Usage: python tools/build_catalogue.py --source PATH --revision GIT_SHA
Local name resources are optional and used only for display names.
"""
import argparse
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path


def split_arguments(text):
    parts, start, depth, quote, escape = [], 0, 0, None, False
    for i, char in enumerate(text):
        if quote:
            if escape:
                escape = False
            elif char == '\\':
                escape = True
            elif char == quote:
                quote = None
        elif char in "\"'":
            quote = char
        elif char in '({[':
            depth += 1
        elif char in ')}]':
            depth -= 1
        elif char == ',' and depth == 0:
            parts.append(text[start:i].strip())
            start = i + 1
    parts.append(text[start:].strip())
    return parts


def sql_value(value):
    if value.startswith("'") and value.endswith("'"):
        return re.sub(r'\\(.)', r'\1', value[1:-1]).replace("''", "'")
    if value == 'NULL':
        return None
    if value.startswith(('0x', '@')):
        return value
    try:
        return float(value) if '.' in value else int(value)
    except ValueError:
        return value


def read_sql(path, table):
    text = path.read_text(encoding='utf-8-sig')
    schema = re.search(r'CREATE TABLE(?: IF NOT EXISTS)? `' + table + r'`\s*\((.*?)\) ENGINE', text, re.S)
    if not schema:
        raise ValueError(f'Missing schema: {table}')
    columns = re.findall(r'^\s*`(\w+)`', schema[1], re.M)
    rows = []
    for line in text.splitlines():
        match = re.match(r'INSERT INTO `' + table + r'` VALUES?\s*(.*?);\s*(?:--.*)?$', line)
        if not match:
            if line.startswith('INSERT INTO `' + table + '`'):
                raise ValueError(f'Unsupported INSERT format in {table}: {line[:100]}')
            continue
        for row in split_arguments(match[1]):
            values = [sql_value(v) for v in split_arguments(row[1:-1])]
            if len(values) != len(columns):
                raise ValueError(f'Column mismatch in {table}: {row[:80]}')
            rows.append(dict(zip(columns, values)))
    return rows


def local_names(path):
    if not path or not path.exists():
        return {}
    result = {}
    for match in re.finditer(r'\[(\d+)\]\s*=\s*\{[^\n]*?en=("(?:\\.|[^"\\])*")', path.read_text(encoding='utf-8-sig')):
        result[int(match[1])] = json.loads(match[2])
    return result


def status_definitions(path, labels):
    text = path.read_text(encoding='utf-8-sig')
    symbols, definitions = {}, {}
    for match in re.finditer(r'^  ([a-z][a-z0-9_]*):\s*\n(.*?)(?=^  [a-z][a-z0-9_]*:|\Z)', text, re.M | re.S):
        id_match = re.search(r'^    id:\s*(\d+)', match[2], re.M)
        if not id_match:
            continue
        status_id = int(id_match[1])
        symbol = match[1].upper()
        symbols[symbol] = status_id
        definitions[status_id] = {'id': status_id, 'symbol': symbol,
                                  'name': labels.get(status_id, match[1].replace('_', ' ').title())}
        element = re.search(r'^    element:\s*([a-z_]+)', match[2], re.M)
        if element:
            definitions[status_id]['element'] = element[1]
        definitions[status_id]['custom'] = status_id >= 768
        if status_id < 768:
            definitions[status_id]['icon_id'] = status_id
    return symbols, definitions


def lua_calls(code, name):
    for match in re.finditer(r'(?<![\w])' + re.escape(name) + r'\s*\(', code):
        start, depth = match.end(), 1
        quote, escape = None, False
        for i in range(start, len(code)):
            char = code[i]
            if quote:
                if escape:
                    escape = False
                elif char == '\\':
                    escape = True
                elif char == quote:
                    quote = None
            elif char in "\"'":
                quote = char
            elif char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
                if depth == 0:
                    yield split_arguments(code[start:i])
                    break


def extract_script(text, effects):
    # Comments are retained only as references/review notes, never effect evidence.
    code = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.S)
    code = re.sub(r'--[^\n]*', '', code)
    result = {'review_status': 'extracted', 'automated': True}
    family = re.search(r'^-- Family:\s*(.+)', text, re.M)
    if family:
        result['family_hint'] = family[1].strip()
    warnings = []
    for field, enum, key in [('attackType', 'attackType', 'attack_types'),
                             ('damageType', 'damageType', 'damage_types'),
                             ('element', 'element', 'elements'),
                             ('shadowBehavior', 'mobskills.shadowBehavior', 'shadow_behavior')]:
        values = sorted(set(re.findall(r'\bparams\.' + field + r'\s*=\s*xi\.' + re.escape(enum) + r'\.([A-Z][A-Z_0-9]*)\b', code)))
        if values:
            result[key] = values
        if len(values) > 1:
            warnings.append('multiple_' + key)
    attack = result.get('attack_types', [])
    elements = result.get('elements', [])
    if attack == ['PHYSICAL']:
        result['damage'] = 'physical'
    elif len(elements) == 1 and elements[0] in {'FIRE', 'ICE', 'WIND', 'EARTH', 'THUNDER', 'WATER', 'LIGHT', 'DARK'}:
        if attack in (['MAGICAL'], ['BREATH']):
            result['damage'] = {'THUNDER': 'lightning'}.get(elements[0], elements[0].lower())
    if re.search(r'TODO[^\n]*(?:element|damage type|damageType)', text, re.I):
        warnings.append('damage_type_needs_review')
        # Do not display a disputed element as settled information.
        result.pop('damage', None)
    statuses, buffs, unresolved = set(), set(), set()
    for function, position, destination in [
        ('xi.mobskills.mobStatusEffectMove', 2, statuses),
        ('xi.mobskills.mobBuffMove', 1, buffs),
        ('target:addStatusEffect', 0, statuses),
        ('target:addStatusEffectEx', 0, statuses),
        ('mob:addStatusEffect', 0, buffs),
        ('mob:addStatusEffectEx', 0, buffs),
    ]:
        for args in lua_calls(code, function):
            if len(args) <= position:
                continue
            expression = args[position]
            match = re.fullmatch(r'xi\.effect\.([A-Z][A-Z_0-9]*)', expression)
            if match and match[1] in effects:
                destination.add(effects[match[1]])
            else:
                unresolved.add(expression)
    if statuses:
        result['statuses'] = sorted(statuses)
    if buffs:
        result['self_statuses'] = sorted(buffs)
    if unresolved:
        result['unresolved_status_expressions'] = sorted(unresolved)
        warnings.append('dynamic_status_effects')
    if re.search(r'\b(?:if|elseif)\b', code) and (statuses or buffs):
        result['effects_conditional'] = True
    if warnings:
        result['review_notes'] = warnings
    if not any(k in result for k in ('damage', 'statuses', 'self_statuses')):
        result['review_status'] = 'needs_review'
    return result


def normalize(name):
    return re.sub(r'\s+', '', re.sub(r'^the\s+', '', name.strip().lower())).replace("'", '').replace('’', '')


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in sorted(value.items(), key=lambda item: str(item[0]))) + '}'


def write_lua(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('-- Generated by tools/build_catalogue.py; see data/reference/manifest.json.\nreturn {\n' +
                    ''.join('[' + lua(k) + ']=' + lua(v) + ',\n' for k, v in sorted(data.items(), key=lambda item: (type(item[0]).__name__, item[0]))) + '}\n', encoding='utf-8')


def build(source, revision, output, client_resources=None):
    enum_text = (source / 'data/enums/mob_type.yaml').read_text(encoding='utf-8-sig')
    notorious_flag = int(re.search(r'^  notorious:\s*(0x[0-9a-fA-F]+|\d+)', enum_text, re.M)[1], 0)
    tables = {name: read_sql(source / 'sql' / (name + '.sql'), name)
              for name in ('mob_skills', 'mob_skill_lists', 'mob_pools', 'mob_groups', 'mob_spell_lists')}
    move_names = local_names(client_resources / 'monster_abilities.lua') if client_resources else {}
    status_names = local_names(client_resources / 'buffs.lua') if client_resources else {}
    spell_names = local_names(client_resources / 'spells.lua') if client_resources else {}
    symbols, statuses = status_definitions(source / 'data/status_effects.yaml', status_names)
    skill_lists = {}
    for row in tables['mob_skill_lists']:
        entry = skill_lists.setdefault(row['skill_list_id'], {'name': row['skill_list_name'], 'moves': []})
        entry['moves'].append(row['mob_skill_id'])
    spell_lists = {}
    for row in tables['mob_spell_lists']:
        entry = spell_lists.setdefault(row['spell_list_id'], {'name': row['spell_list_name'], 'spells': []})
        entry['spells'].append({'id': row['spell_id'], 'name': spell_names.get(row['spell_id'], 'Spell ' + str(row['spell_id'])),
                               'min_level': row['min_level'], 'max_level': row['max_level']})
    moves = {}
    for row in tables['mob_skills']:
        move_id, script = row['mob_skill_id'], row['mob_skill_name']
        if move_id < 257:
            continue
        path = source / 'scripts/actions/mobskills' / (script + '.lua')
        entry = extract_script(path.read_text(encoding='utf-8-sig'), symbols) if path.exists() else {'review_status': 'missing_script', 'automated': True}
        entry.update({'id': move_id, 'name': move_names.get(move_id, script.replace('_', ' ').title()),
                      'source': script, 'area_code': row['mob_skill_aoe'],
                      'radius': row['mob_skill_aoe_radius'], 'range': row['mob_skill_distance'],
                      'prepare_ms': row['mob_prepare_time'], 'animation_ms': row['mob_anim_time'],
                      'target_flags': row['mob_valid_targets']})
        # SQL numeric targeting is preserved verbatim; only well-established
        # radial code 1 is rendered automatically. Other shapes need review.
        if row['mob_skill_aoe'] == 1:
            entry['area'] = 'AoE'
        moves[move_id] = entry
    zones = defaultdict(set)
    aliases = defaultdict(set)
    for row in tables['mob_groups']:
        zones[row['poolid']].add(row['zoneid'])
        aliases[row['poolid']].add(row['name'].replace('_', ' '))
    monsters, monster_index = {}, defaultdict(set)
    for row in tables['mob_pools']:
        names = sorted(aliases[row['poolid']] | {row['name'].replace('_', ' '), row['packet_name'].replace('_', ' ')})
        skills = skill_lists.get(row['skill_list_id'], {}).get('moves', [])
        monsters[row['poolid']] = {'pool_id': row['poolid'], 'name': row['name'].replace('_', ' '), 'aliases': names,
            'species_id': row['speciesid'], 'skill_list_id': row['skill_list_id'],
            'mob_type': row['mobType'], 'notorious': bool(row['mobType'] & notorious_flag),
            'skill_list_name': skill_lists.get(row['skill_list_id'], {}).get('name'),
            'moves': sorted(set(skills)), 'spell_list_id': row['spellList'],
            'zones': sorted(zones[row['poolid']]), 'review_status': 'sql_base_list'}
        for name in names:
            monster_index[normalize(name)].update(id for id in skills if id in moves)
    runtime_moves = {}
    runtime_fields = ('name', 'damage', 'area', 'statuses', 'self_statuses', 'source', 'automated')
    for id, entry in moves.items():
        runtime_moves[id] = {key: entry[key] for key in runtime_fields if key in entry}
    write_lua(output / 'generated/moves.lua', runtime_moves)
    write_lua(output / 'generated/monsters.lua', {k: sorted(v) for k, v in monster_index.items() if v})
    write_lua(output / 'generated/statuses.lua', {id: entry['name'] for id, entry in statuses.items()})
    write_lua(output / 'generated/spells.lua', spell_names)
    browser_monsters = {}
    group_members = defaultdict(set)
    for monster in monsters.values():
        key = normalize(monster['name'])
        entry = browser_monsters.setdefault(key, {'name': monster['name'], 'aliases': set(), 'moves': set(), 'pool_ids': set(), 'notorious': False})
        entry.setdefault('spells', set()).update(spell['id'] for spell in spell_lists.get(monster['spell_list_id'], {}).get('spells', []))
        entry['notorious'] = entry['notorious'] or monster['notorious']
        entry['aliases'].update(monster['aliases'])
        entry['moves'].update(id for id in monster['moves'] if id in moves)
        entry['pool_ids'].add(monster['pool_id'])
        group_members[monster['skill_list_id']].update(monster['aliases'])
    targets = []
    for key, entry in sorted(browser_monsters.items()):
        targets.append({k: sorted(v) if isinstance(v, set) else v for k, v in entry.items()})
    families = [{'name': entry['name'].replace('_', ' '), 'family_id': id,
                 'moves': sorted(set(m for m in entry['moves'] if m in moves)),
                 'members': sorted(group_members[id])}
                for id, entry in sorted(skill_lists.items())]
    write_lua(output / 'generated/browser.lua', {'monsters': targets, 'families': families})
    reference = output / 'reference'
    reference.mkdir(parents=True, exist_ok=True)
    for name, data in [('moves', moves), ('monsters', monsters), ('statuses', statuses), ('skill_lists', skill_lists), ('spell_lists', spell_lists)]:
        (reference / (name + '.json')).write_text(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    def cell(value):
        return str(value).replace('|', '/').replace('\n', ' ')
    monster_lines = ['# Monster base skill lists\n\nGenerated from pinned upstream SQL. Scripted additions/overrides are not included.\n\n',
                     '| Monster | Pool ID | Skill list | Moves |\n|---|---:|---:|---|\n']
    for id, entry in sorted(monsters.items(), key=lambda item: (item[1]['name'].lower(), item[0])):
        labels = [moves[m]['name'] if m in moves else ('Skill ' + str(m)) for m in entry['moves']]
        monster_lines.append('| ' + ' | '.join(map(cell, [entry['name'], id, entry['skill_list_id'], ', '.join(labels) or 'No explicit SQL list'])) + ' |\n')
    (reference / 'MONSTERS.md').write_text(''.join(monster_lines), encoding='utf-8')
    move_lines = ['# Move catalogue\n\nAutomated upstream extraction; possible effects, not guaranteed hits or private-server verification.\n\n',
                  '| ID | Move | Damage | Target effects | Self effects | Review status |\n|---:|---|---|---|---|---|\n']
    for id, entry in sorted(moves.items()):
        labels = lambda key: ', '.join(statuses[s]['name'] for s in entry.get(key, []))
        move_lines.append('| ' + ' | '.join(map(cell, [id, entry['name'], entry.get('damage', 'Unknown / none recorded'),
            labels('statuses'), labels('self_statuses'), entry['review_status']])) + ' |\n')
    (reference / 'MOVES.md').write_text(''.join(move_lines), encoding='utf-8')
    source_hashes = {}
    for path in sorted(source.rglob('*')):
        if path.is_file() and (path.suffix in ('.lua', '.sql', '.yaml')):
            source_hashes[path.relative_to(source).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    counts = {'moves': len(moves), 'monsters': len(monsters), 'skill_lists': len(skill_lists),
              'spell_lists': len(spell_lists), 'statuses': len(statuses),
              'moves_with_damage': sum('damage' in m for m in moves.values()),
              'moves_with_target_statuses': sum('statuses' in m for m in moves.values()),
              'moves_with_self_statuses': sum('self_statuses' in m for m in moves.values()),
              'moves_missing_script': sum(m['review_status'] == 'missing_script' for m in moves.values())}
    review_queue = [{'id': id, 'name': entry['name'], 'reasons': entry.get('review_notes', []) +
                     ([] if entry['review_status'] == 'extracted' else [entry['review_status']])}
                    for id, entry in sorted(moves.items())
                    if entry['review_status'] != 'extracted' or entry.get('review_notes')]
    (reference / 'review_queue.json').write_text(json.dumps(review_queue, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    coverage = '# Catalogue coverage\n\nPinned LandSandBoat revision: `' + revision + '`.\n\n'
    coverage += '| Record / field | Count |\n|---|---:|\n'
    coverage += ''.join('| ' + key.replace('_', ' ') + ' | ' + str(value) + ' |\n' for key, value in counts.items())
    coverage += '\nThese are upstream records and static extraction counts, not verified private-server coverage.\n'
    coverage += '\nThe review queue contains ' + str(len(review_queue)) + ' records with missing/dynamic/uncertain fields.\n'
    (reference / 'COVERAGE.md').write_text(coverage, encoding='utf-8')
    manifest = {'source': 'https://github.com/LandSandBoat/server', 'revision': revision,
        'checked_date': '2026-11-02', 'counts': counts, 'source_hashes': source_hashes,
        'table_rows': {name: len(rows) for name, rows in tables.items()},
        'limitations': ['Static extraction, not in-game verification.', 'Statuses are possible applications; conditional branches may differ.',
            'Monster SQL lists omit scripted additions and overrides.', 'No damage estimates.', 'Not verified against CatsEyeXI or a customized private server.']}
    if client_resources:
        manifest['client_name_resources'] = {name: hashlib.sha256((client_resources / name).read_bytes()).hexdigest()
            for name in ('monster_abilities.lua', 'buffs.lua', 'spells.lua') if (client_resources / name).exists()}
    (reference / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(json.dumps(counts, indent=2))
    return counts


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--revision', required=True)
    parser.add_argument('--output', type=Path, default=Path('data'))
    parser.add_argument('--client-resources', type=Path)
    options = parser.parse_args()
    build(options.source, options.revision, options.output, options.client_resources)
