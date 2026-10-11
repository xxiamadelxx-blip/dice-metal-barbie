"""Negative and positive cases for fail-closed Gauntlet evidence records."""
import copy
import unittest

from scripts.gauntlet_evidence import evaluate

A = "a" * 40
B = "b" * 40
C = "c" * 40


def valid_record():
    return {
        "schema_version": 1,
        "repository": "owner/repo",
        "task": "dice-physics",
        "builder_id": "builder-session",
        "approved_reference": "docs/PRD.md#acceptance",
        "baseline_sha": A,
        "candidate_sha": B,
        "required_gates": ["physics", "visual"],
        "iterations": [{
            "index": 1,
            "candidate_sha": B,
            "artifact_refs": ["https://github.com/owner/repo/actions/runs/123"],
            "checks": [
                {"gate": "physics", "status": "PASS", "evidence_ref": "https://github.com/owner/repo/actions/runs/123"},
                {"gate": "visual", "status": "PASS", "evidence_ref": "artifact://visual-frame-001"},
            ],
            "critic": {
                "mode": "independent",
                "reviewer_id": "reviewer-other-session",
                "isolated_run_ref": "https://github.com/owner/repo/issues/42",
                "raw_artifact_review_ref": "artifact://critic-report",
                "verdict": "PASS",
                "findings": [],
            },
        }],
    }


class GauntletEvidenceTests(unittest.TestCase):
    def test_valid_independent_review_contract(self):
        self.assertEqual(evaluate(valid_record(), expected_sha=B, expected_repository="owner/repo"), [])

    def test_rejects_self_review_green(self):
        r = valid_record()
        r["iterations"][0]["critic"]["mode"] = "self_review"
        self.assertTrue(any("independent" in e for e in evaluate(r)))

    def test_rejects_forged_same_identity(self):
        r = valid_record()
        r["iterations"][0]["critic"]["reviewer_id"] = r["builder_id"]
        self.assertTrue(any("identity" in e for e in evaluate(r)))

    def test_rejects_missing_raw_review(self):
        r = valid_record()
        del r["iterations"][0]["critic"]["raw_artifact_review_ref"]
        self.assertTrue(any("raw artifacts" in e for e in evaluate(r)))

    def test_rejects_missing_gate_and_unverified(self):
        r = valid_record()
        r["iterations"][0]["checks"] = [{"gate": "physics", "status": "NOT_VERIFIED"}]
        problems = evaluate(r)
        self.assertTrue(any("missing gates" in e for e in problems))
        self.assertTrue(any("every final" in e for e in problems))

    def test_rejects_wrong_sha_or_repo(self):
        self.assertTrue(any("candidate_sha" in e for e in evaluate(valid_record(), expected_sha=C)))
        self.assertTrue(any("repository" in e for e in evaluate(valid_record(), expected_repository="other/repo")))

    def test_rejects_unresolved_blocker(self):
        r = valid_record()
        r["iterations"][0]["critic"]["findings"] = [{
            "id": "blackout", "severity": "blocker", "disposition": "open",
            "evidence_ref": "artifact://black-video",
        }]
        self.assertTrue(any("unresolved" in e for e in evaluate(r)))

    def test_rejects_fake_resolution_without_retest(self):
        r = valid_record()
        r["iterations"][0]["critic"]["findings"] = [{
            "id": "blackout", "severity": "blocker", "disposition": "resolved",
            "evidence_ref": "artifact://black-video",
        }]
        self.assertTrue(any("retest_ref" in e for e in evaluate(r)))

    def test_failure_then_fix_then_independent_pass(self):
        r = valid_record()
        old = copy.deepcopy(r["iterations"][0])
        old["critic"]["verdict"] = "FAIL"
        old["checks"][0]["status"] = "FAIL"
        old["candidate_sha"] = A
        r["iterations"].insert(0, old)
        r["iterations"][1]["index"] = 2
        r["iterations"][1]["change_ref"] = "https://github.com/owner/repo/commit/" + B
        self.assertEqual(evaluate(r), [])
        del r["iterations"][1]["change_ref"]
        self.assertTrue(any("change_ref" in e for e in evaluate(r)))

    def test_rejects_empty_record(self):
        self.assertTrue(evaluate({}))
        self.assertTrue(evaluate("PASS"))
        self.assertTrue(evaluate(valid_record() | {"iterations": []}))


if __name__ == "__main__":
    unittest.main()
