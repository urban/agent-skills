import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "check-links.py"
SPEC = importlib.util.spec_from_file_location("check_links", SCRIPT)
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


class LinkChecks(unittest.TestCase):
    def test_relative_encoded_paths_and_duplicate_heading_fragments(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "target file.md").write_text("# Target\n## State\n## State\n")
            source = root / "source.md"
            source.write_text("[state](target%20file.md#state-1)\n[home](#source)\n# Source\n")
            files, links, errors = CHECKER.check([source])
            self.assertEqual((len(files), links, errors), (1, 2, []))

    def test_reports_broken_path_and_heading(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.md"
            source.write_text("# Source\n[missing](absent.md)\n[wrong](#gone)\n")
            _, _, errors = CHECKER.check([source])
            self.assertEqual(len(errors), 2)
            self.assertIn("missing path absent.md", errors[0])
            self.assertIn("missing heading #gone", errors[1])

    def test_ignores_external_links_and_fenced_examples(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "source.md"
            source.write_text(
                "[web](https://example.com/missing)\n"
                "```markdown\n[example](absent.md)\n```\n"
                "~~~markdown\n[example](absent.md)\n~~~\n"
            )
            _, links, errors = CHECKER.check([source])
            self.assertEqual((links, errors), (0, []))

    def test_missing_input_is_an_error(self):
        with tempfile.TemporaryDirectory() as directory:
            _, _, errors = CHECKER.check([Path(directory) / "absent.md"])
            self.assertEqual(len(errors), 1)
            self.assertIn("input does not exist", errors[0])


if __name__ == "__main__":
    unittest.main()
