import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('storage_cleanup', Path(__file__).resolve().parents[1] / 'provisioning/storage/cleanup.py')
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


class RetentionTests(unittest.TestCase):
    def test_keeps_three_newest_plus_old_running_and_boot_systems(self):
        generations = {n: f'/nix/store/system-{n}' for n in range(1, 9)}
        self.assertEqual(cleanup.obsolete_generations(generations, {generations[2], generations[4]}), [1, 3, 5])

    def test_small_history_kept_and_repeated_closures_are_bounded(self):
        self.assertEqual(cleanup.obsolete_generations({1: 'a', 2: 'b'}, {'a', 'b'}), [])
        self.assertEqual(cleanup.obsolete_generations({n: 'same' for n in range(1, 8)}, {'same'}), [1, 2, 3, 4])

    def test_rollback_to_duplicate_closure_keeps_current_profile_number(self):
        generations = {n: 'same' for n in range(1, 8)}
        self.assertEqual(cleanup.obsolete_generations(generations, {'same'}, current=2), [1, 3, 4])
