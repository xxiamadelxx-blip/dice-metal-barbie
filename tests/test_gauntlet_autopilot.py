"""No network/provider required: prove builder->test->isolated critic->repair loop."""
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts.gauntlet_autopilot import execute, safe_path, validate_spec


def run(repo, *args):
    p = subprocess.run(["git", *args], cwd=repo, capture_output=True, text=True)
    if p.returncode:
        raise AssertionError(p.stderr)
    return p.stdout.strip()


class Actor:
    builder_model = "fake-builder"
    critic_model = "fake-independent-critic"

    def __init__(self):
        self.roles = []
        self.count = 0

    def __call__(self, role, payload):
        self.roles.append(role)
        if role == "builder":
            self.count += 1
            self.assert_inputs_not_shared(payload)
            return {"edits": [{"path": "sample.py",
                               "content": "print('GOOD')\n" if self.count > 1 else "print('BAD')\n"}]}
        self.assert_raw_not_builder_story(payload)
        return {"verdict": "PASS", "findings": [{"id": "failed-output", "severity": "major",
                "disposition": "resolved"}]} if payload["test_exit"] == 0 else {
                "verdict": "FAIL", "findings": [{"id": "failed-output",
                "severity": "major", "disposition": "open"}]}

    def assert_inputs_not_shared(self, data):
        assert "diff" not in data

    def assert_raw_not_builder_story(self, data):
        assert "source" not in data and "builder_rationale" not in data
        assert "diff" in data and "test_log" in data


class AutoLoopTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        self.root.mkdir()
        run(self.root, "init", "-q")
        run(self.root, "config", "user.email", "tests@example.invalid")
        run(self.root, "config", "user.name", "Unit Tester")
        (self.root / "sample.py").write_text("print('INITIAL')\n")
        run(self.root, "add", "sample.py")
        run(self.root, "commit", "-qm", "base")
        run(self.root, "branch", "-M", "main")
        run(self.root, "checkout", "-qb", "gauntlet/autofix-testing")
        self.out = Path(self.temp.name) / "out"
        self.plan = {"repository": "owner/repo", "task": "Ensure GOOD output",
                     "approved_reference": "test acceptance", "acceptance": ["prints GOOD"],
                     "allowed_paths": ["sample.py"],
                     "test_command": ["python", "-c", "import sample; assert False if False else True"],
                     "max_iterations": 2}

    def test_real_two_role_two_iteration_feedback(self):
        # Output assertion executes actual candidate source on disposable checkout.
        self.plan["test_command"] = ["python", "-c",
                                     "import subprocess; s=subprocess.check_output(['python','sample.py']).decode(); assert s==bytes.fromhex('474f4f440a').decode(),s"]
        actor = Actor()
        record = execute(self.plan, self.root, self.out, actor)
        self.assertEqual(actor.roles, ["builder", "critic", "builder", "critic"])
        self.assertEqual(len(record["iterations"]), 2)
        self.assertEqual(record["iterations"][0]["critic"]["verdict"], "FAIL")
        self.assertEqual(record["iterations"][1]["critic"]["verdict"], "PASS")
        self.assertNotEqual(record["iterations"][0]["candidate_sha"], record["iterations"][1]["candidate_sha"])
        self.assertEqual(json.loads((self.out / "result.json").read_text())["status"],
                         "ACCEPTED_BY_SEPARATE_MODEL_CONTEXT")

    def test_invalid_first_critic_response_gets_one_recorded_recheck(self):
        class CriticFormatRecovery(Actor):
            def __init__(self):
                super().__init__()
                self.critic_calls = 0

            def __call__(self, role, payload):
                self.roles.append(role)
                if role == "builder":
                    return {"edits": [{"path": "sample.py", "content": "print('GOOD')\n"}]}
                self.critic_calls += 1
                if self.critic_calls == 1:
                    return {"verdict": "FAIL", "findings": [
                        {"id": "stable-id", "severity": "major", "disposition": "resolved"}]}
                self.assert_inputs_not_shared(payload)
                assert "format_correction" in payload
                return {"verdict": "PASS", "findings": []}

        self.plan["test_command"] = ["python", "-c",
            "import subprocess; s=subprocess.check_output(['python','sample.py']).decode(); assert s==bytes.fromhex('474f4f440a').decode()"]
        self.plan["max_iterations"] = 1
        actor = CriticFormatRecovery()
        record = execute(self.plan, self.root, self.out, actor)
        self.assertEqual(actor.roles, ["builder", "critic", "critic"])
        self.assertEqual(record["iterations"][0]["critic"]["verdict"], "PASS")
        self.assertTrue((self.out / "reviews/critic-1.json").exists())
        self.assertTrue((self.out / "reviews/critic-1-retry.json").exists())
        self.assertEqual(json.loads((self.out / "reviews/critic-1.json").read_text())["verdict"], "FAIL")

    def test_twice_invalid_independent_review_still_fails(self):
        class AlwaysInvalid(Actor):
            def __call__(self, role, payload):
                if role == "builder":
                    return {"edits": [{"path": "sample.py", "content": "print('GOOD')\n"}]}
                return {"verdict": "FAIL", "findings": [
                    {"id": "made-up-issue", "severity": "major", "disposition": "resolved"}]}
        self.plan["max_iterations"] = 1
        with self.assertRaisesRegex(RuntimeError, "after one retry"):
            execute(self.plan, self.root, self.out, AlwaysInvalid())
        self.assertTrue((self.out / "reviews/critic-1-retry.json").exists())

    def test_refuse_protected_files(self):
        (self.root / "AGENTS.md").write_text("original")
        with self.assertRaises(ValueError):
            safe_path(self.root, "AGENTS.md")
        with self.assertRaises(ValueError):
            safe_path(self.root, "../sample.py")

    def test_refuse_bad_plan(self):
        self.plan["test_command"] = "sh -c corrupt"
        with self.assertRaises(ValueError):
            validate_spec(self.plan, self.root)

    def test_refuse_main_branch(self):
        run(self.root, "checkout", "-q", "main")
        with self.assertRaises(RuntimeError):
            execute(self.plan, self.root, self.out, Actor())

    def test_refuse_uncommitted_collaborator_work(self):
        (self.root / "sample.py").write_text("user-owned")
        with self.assertRaises(RuntimeError):
            execute(self.plan, self.root, self.out, Actor())

    def test_refuse_unauthorized_actor_write(self):
        class Bad(Actor):
            def __call__(self, role, payload):
                return {"edits": [{"path": "AGENTS.md", "content": "harmful"}]}
        with self.assertRaises(RuntimeError):
            execute(self.plan, self.root, self.out, Bad())


if __name__ == "__main__":
    unittest.main()
