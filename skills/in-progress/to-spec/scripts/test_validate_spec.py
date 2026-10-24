#!/usr/bin/env python3
"""Contract tests for spec-checker mechanics and its command-line interface."""

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


sys.dont_write_bytecode = True
SCRIPT = Path(__file__).with_name("validate-spec.py").resolve()
LOADER = importlib.util.spec_from_file_location("spec_checker", SCRIPT)
checker = importlib.util.module_from_spec(LOADER)
LOADER.loader.exec_module(checker)
SPEC = """# Receipt export

Status: Draft; approval pending.

## Intent

An account holder can retain their own receipts. Bulk export is excluded.

## Public contract

Preserve ownership checks; an unavailable export gives a retryable response.

### Acceptance evidence

- AC-01: An owner requests a receipt and receives its correct contents.
- AC-03: A different account cannot retrieve that receipt.

## Delivery and decisions

No migration is needed. Release to the account UI after verification.
The implementation may choose its private structure. No open product decisions.

## Continuation

Execute only after approval. Verify AC-01 and AC-03.
"""


class SpecCheckTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "spec.md"

    def findings(self, text=SPEC, check_blockers=False):
        return checker.check(text, self.path, check_blockers)

    def test_flexible_headings_and_nonsequential_stable_ids(self):
        self.assertEqual(self.findings(), [])
        reordered = SPEC.replace("## Intent", "## Product boundary").replace(
            "## Continuation", "## Next session")
        self.assertEqual(self.findings(reordered + "\n## Extra context\n\nUseful detail.\n"), [])

    def test_missing_duplicate_empty_and_unknown_acceptance_ids(self):
        variants = [
            SPEC.replace("- AC-01:", "- Outcome:").replace("- AC-03:", "- Outcome:"),
            SPEC + "\n- AC-01: Another definition.\n",
            SPEC + "\n- AC-04:\n",
            SPEC + "\nSee AC-99.\n",
        ]
        for text in variants:
            with self.subTest(text=text):
                self.assertTrue(self.findings(text))

    def test_title_and_empty_section_contract(self):
        for text in (SPEC.replace("# Receipt export", "", 1),
                     SPEC + "\n# Second title\n\nText.\n",
                     SPEC.replace("# Receipt export", "# ", 1),
                     "Preface\n" + SPEC, SPEC + "\n## Empty\n",
                     SPEC + "\n## \n\nText.\n"):
            with self.subTest(text=text):
                self.assertTrue(self.findings(text))
        self.assertEqual(self.findings(SPEC.replace(
            "## Intent\n\n", "## Framing\n\n### Intent\n\n")), [])

    def test_fenced_examples_do_not_define_headings_ids_or_links(self):
        for fence in ("```", "~~~~"):
            example = f"\n{fence}md\n# Example\n## Empty\n- AC-01: example\nSee AC-99 [missing](absent.md)\n{fence}\n"
            with self.subTest(fence=fence):
                self.assertEqual(self.findings(SPEC + example), [])
        self.assertTrue(self.findings(SPEC + "\n```text\nunclosed\n"))
        self.assertEqual(self.findings(SPEC + "\n## Schema\n\n```ts\ntype X = string\n```\n"), [])

    def test_drafting_and_unresolved_markers_have_different_meanings(self):
        for marker in ("{{Fill this}}", "[TODO: draft]"):
            self.assertTrue(self.findings(SPEC + marker))
        for marker in ("TODO: Confirm", "todo : confirm", "BLOCKED:"):
            with self.subTest(marker=marker):
                text = SPEC + "\n" + marker + " export retention.\n"
                self.assertEqual(self.findings(text), [])
                self.assertTrue(self.findings(text, check_blockers=True))
        # A machine must not infer acceptance from a clean document.
        self.assertEqual(self.findings(SPEC, check_blockers=True), [])

    def test_inline_local_links_resolve_from_document_not_process(self):
        target = self.path.parent / "decision record.md"
        target.write_text("# Decision\n", encoding="utf-8")
        self.assertEqual(self.findings(SPEC + "\n[ADR](decision%20record.md#choice)\n"), [])
        self.assertTrue(self.findings(SPEC + "\n[ADR](missing.md)\n"))
        self.assertEqual(self.findings(SPEC + "\n[web](https://example.invalid/x) [anchor](#intent)\n"), [])

    def test_bundled_template_is_not_a_completed_spec(self):
        template = SCRIPT.parents[1] / "assets" / "spec-template.md"
        self.assertTrue(self.findings(template.read_text(encoding="utf-8")))

    def test_cli_pass_failure_markers_and_input_errors(self):
        def run(*args):
            return subprocess.run([sys.executable, str(SCRIPT), *map(str, args)],
                                  cwd=self.directory.name, text=True, capture_output=True)

        self.path.write_text(SPEC, encoding="utf-8")
        result = run(self.path, "--check-blockers")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("readiness were not evaluated", result.stdout)
        self.path.write_text(SPEC + "\nTODO: Confirm retention.\n", encoding="utf-8")
        self.assertEqual(run(self.path).returncode, 0)
        self.assertEqual(run(self.path, "--check-blockers").returncode, 1)
        self.assertEqual(run(self.path.parent / "absent.md").returncode, 1)
        self.path.write_bytes(b"\xff")
        self.assertEqual(run(self.path).returncode, 1)


if __name__ == "__main__":
    unittest.main()
