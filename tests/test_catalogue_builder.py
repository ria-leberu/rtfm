import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('builder', ROOT / 'tools/build_catalogue.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class CatalogueTests(unittest.TestCase):
    def test_sql_comments_aliases_and_quotes(self):
        with tempfile.TemporaryDirectory(prefix='catalogue-test-', dir=ROOT / 'tests') as folder:
            self.assertTrue(Path(folder).resolve().is_relative_to(ROOT / 'tests'))
            path = Path(folder) / 'sample.sql'
            path.write_text("""CREATE TABLE `sample` (
  `id` int,
  `name` varchar(100)
) ENGINE=Aria;
INSERT INTO `sample` VALUES (1,'One, two'); -- trailing comment
INSERT INTO `sample` VALUE(2,'Aw\\'ghrah'); -- alternate valid syntax
-- INSERT INTO `sample` VALUES (3,'Disabled');
""", encoding='utf-8')
            self.assertEqual(builder.read_sql(path, 'sample'), [{'id': 1, 'name': 'One, two'}, {'id': 2, 'name': "Aw'ghrah"}])

    def test_status_applications_only(self):
        script = """-- xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.POISON, 1)
params.attackType = xi.attackType.MAGICAL
params.element = xi.element.THUNDER
target:hasStatusEffect(xi.effect.POISON)
xi.mobskills.mobStatusEffectMove(mob, target, xi.effect.STUN, 1, 0, math.random(1, 5))
xi.mobskills.mobBuffMove(mob, xi.effect.PROTECT, 20, 0, 30)
xi.mobskills.mobStatusEffectMove(mob, target, effect, 1, 0, 30)
"""
        parsed = builder.extract_script(script, {'POISON': 3, 'STUN': 10, 'PROTECT': 40})
        self.assertEqual(parsed['statuses'], [10])
        self.assertEqual(parsed['self_statuses'], [40])
        self.assertEqual(parsed['damage'], 'lightning')
        self.assertEqual(parsed['unresolved_status_expressions'], ['effect'])

    def test_uncertain_element_is_not_displayed(self):
        parsed = builder.extract_script('params.attackType = xi.attackType.MAGICAL\nparams.element = xi.element.FIRE -- TODO: element depends on mob\n', {})
        self.assertNotIn('damage', parsed)
        self.assertIn('damage_type_needs_review', parsed['review_notes'])

    def test_generated_data_integrity(self):
        reference = ROOT / 'data/reference'
        moves = json.loads((reference / 'moves.json').read_text(encoding='utf-8'))
        monsters = json.loads((reference / 'monsters.json').read_text(encoding='utf-8'))
        statuses = json.loads((reference / 'statuses.json').read_text(encoding='utf-8'))
        manifest = json.loads((reference / 'manifest.json').read_text(encoding='utf-8'))
        self.assertEqual(manifest['counts']['moves'], len(moves))
        self.assertEqual(manifest['counts']['monsters'], len(monsters))
        self.assertEqual(moves['319']['statuses'], [3, 4, 5, 6, 11, 12, 13])
        self.assertIn(2028, monsters['2220']['moves'])
        self.assertTrue(monsters['2220']['notorious'])
        for monster in monsters.values():
            self.assertEqual(monster['notorious'], bool(monster['mob_type'] & 2))
        for move in moves.values():
            self.assertNotIn('damage_estimate', move)
            for id in move.get('statuses', []) + move.get('self_statuses', []):
                self.assertIn(str(id), statuses)
        self.assertEqual(manifest['table_rows']['mob_pools'], len(monsters))


if __name__ == '__main__':
    unittest.main()
