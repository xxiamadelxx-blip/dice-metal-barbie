"""Contract tests for the canonical Dice engineering router. All offline stdlib."""
from __future__ import annotations

import json
from pathlib import Path
import tempfile
import unittest

from scripts.engineering_router import (
    EXPECTED_REPO, ROOT, RouterError, checkpoint, git_info, load_registry,
    record_incident,
    main, parse_mode, probe_tools, read_json, report, route_for,
    validate_registry, validate_state,
)


class EngineeringRouterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reg = load_registry(ROOT)
        cls.saved = read_json(ROOT / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json")

    def test_registry_contains_every_domain_and_fallback(self):
        self.assertEqual([], validate_registry(self.reg))
        self.assertEqual([], validate_state(self.saved, self.reg))
        ids = {r["id"] for r in self.reg["routes"]}
        for name in ("code", "architecture", "creative-3d", "audio-haptics",
                     "security", "performance", "android-release", "qa-critic",
                     "agent-operations", "interface-accessibility", "observability",
                     "supply-chain", "reliability-persistence"):
            self.assertIn(name, ids)
        for route in self.reg["routes"]:
            self.assertTrue(route["checks"])
            self.assertTrue(route["fallback"])
            self.assertTrue(route["artifacts"])

    def test_resume_stuck_handoff_intents_have_single_entrypoint(self):
        for phrase, expected in (
                ("продолжай", "continue"), ("продолжай работу", "continue"),
                ("завис", "stuck"), ("застрял", "stuck"),
                ("передача новому агенту", "handoff"), ("new agent", "handoff")):
            self.assertEqual(parse_mode(phrase), expected)
            selected = route_for(phrase, self.reg, self.saved["active"])
            self.assertEqual(selected["id"], self.saved["active"]["route"])

    def test_dependencies_are_not_stuck_signal(self):
        self.assertEqual(parse_mode("Анализ архитектуры и зависимостей"), "new-task")

    def test_explicit_specialty_selection(self):
        for prompt, name in (
                ("Создай звук столкновения кубиков", "audio-haptics"),
                ("Нужен анализ архитектуры и зависимостей", "architecture"),
                ("У нас уязвимость security", "security"),
                ("Измерь FPS", "performance"),
                ("Нужно проверить APK и подпись", "android-release"),
                ("Нужно исправить скрипт и ошибку в коде", "code")):
            self.assertEqual(route_for(prompt, self.reg, self.saved["active"])["id"], name)
        self.assertEqual(route_for("anything", self.reg, self.saved["active"], "creative-3d")["id"], "creative-3d")
        with self.assertRaises(RouterError):
            route_for("anything", self.reg, self.saved["active"], "invented")

    def test_stuck_requires_failure_diagnosis_and_no_false_ci(self):
        result = report("завис", self.reg, self.saved, ROOT)
        self.assertEqual(result["mode"], "stuck")
        self.assertTrue(any("do not blindly repeat" in x for x in result["warnings"]))
        self.assertEqual(result["project"], EXPECTED_REPO)
        self.assertNotIn("PASS", result["current"].values())

    def test_fake_schema_or_cross_repository_rejected(self):
        altered = json.loads(json.dumps(self.reg))
        altered["repository"] = "wrong/repository"
        self.assertTrue(validate_registry(altered))
        altered = json.loads(json.dumps(self.reg))
        altered["routes"].append(altered["routes"][0])
        self.assertTrue(any("duplicate" in x for x in validate_registry(altered)))
        state = json.loads(json.dumps(self.saved))
        state["repository"] = "another/project"
        self.assertTrue(validate_state(state, self.reg))
        state["repository"] = EXPECTED_REPO
        state["active"]["status"] = "blocked"
        state["active"]["blockers"] = []
        self.assertTrue(any("blocker" in x for x in validate_state(state, self.reg)))

    def test_diagnostics_label_tool_presence_without_claiming_execution(self):
        out = probe_tools(ROOT)
        self.assertIn("godot", out)
        self.assertIn("python3", out)
        self.assertIn("gauntlet_cli", out)
        self.assertTrue(out["gauntlet_cli"] in ("source-present", "not-present"))
        self.assertTrue(all(v.startswith(("binary-found:", "not-detected",
                                         "source-present", "not-present")) for v in out.values()))

    def test_hand_off_recovers_previous_state_without_rewriting(self):
        entry = report("передача новому агенту", self.reg, self.saved, ROOT)
        self.assertEqual(entry["saved"]["task"], self.saved["active"]["task"])
        self.assertIn("handoff_stale", entry)
        self.assertEqual(entry["mode"], "handoff")
        self.assertTrue(entry["next_actions"])

    def test_atomic_checkpoint_requires_blocker_and_keeps_status_honest(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "docs/handoff").mkdir(parents=True)
            (root / "config").mkdir()
            (root / "config/engineering_routes.json").write_text(json.dumps(self.reg), encoding="utf-8")
            target = root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json"
            target.write_text(json.dumps(self.saved), encoding="utf-8")
            from argparse import Namespace
            data = dict(route="audio-haptics", task="Implement physical collision audio",
                        owner="fresh reviewer", next_action="Obtain raw Godot contact recording",
                        status="blocked", blocker=[], evidence=[],
                        verification_note="")
            with self.assertRaises(RouterError):
                checkpoint(root, self.reg, Namespace(**data))
            data["blocker"] = ["No real Android playback evidence"]
            done = checkpoint(root, self.reg, Namespace(**data))
            updated = read_json(target)
            self.assertEqual(updated["active"]["status"], "blocked")
            self.assertEqual(updated["active"]["route"], "audio-haptics")
            self.assertEqual(done["checkpoint"]["evidence"], [])
            self.assertEqual(updated["active"]["last_verified_sha"], "")
            self.assertEqual(updated["active"]["last_observed_sha"], "")
            self.assertEqual([], validate_state(updated, self.reg))


    def test_no_verified_checkpoint_without_evidence(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "docs/handoff").mkdir(parents=True)
            (root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json").write_text(
                json.dumps(self.saved), encoding="utf-8")
            from argparse import Namespace
            args = Namespace(route="code", task="test", owner="agent",
                             status="verified", next_action="close",
                             blocker=[], evidence=[], verification_note="")
            with self.assertRaisesRegex(RouterError, "requires authentic"):
                checkpoint(root, self.reg, args)

    def test_identical_failed_approach_budget_across_agent_sessions(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "docs/handoff").mkdir(parents=True)
            path = root / "docs/handoff/ACTIVE_ROUTING_HANDOFF.json"
            path.write_text(json.dumps(self.saved), encoding="utf-8")
            from argparse import Namespace
            args = Namespace(route="code", fingerprint="CI timeout unchanged / same command",
                             outcome="failed", evidence="artifact://ci-error-log",
                             classification="transient timeout")
            self.assertEqual(record_incident(root, self.reg, args)["same_approach_failures"], 1)
            second = record_incident(root, self.reg, args)
            self.assertEqual(second["same_approach_failures"], 2)
            self.assertTrue(second["do_not_retry"])
            recovered = read_json(path)
            self.assertEqual(recovered["active"]["status"], "blocked")
            self.assertTrue(any("DO NOT RETRY" in b for b in recovered["active"]["blockers"]))
            self.assertEqual([], validate_state(recovered, self.reg))
            with self.assertRaisesRegex(RouterError, "DO NOT RETRY"):
                record_incident(root, self.reg, args)
            report_data = report("завис", self.reg, recovered, root, "code")
            self.assertTrue(report_data["route_exhausted_fingerprints"])

    def test_documentation_hooks_prevent_bypassing_router(self):
        agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        handoff_doc = (ROOT / "docs/ENGINEERING_ROUTER.md").read_text(encoding="utf-8")
        self.assertIn("scripts/engineering_router.py", agents)
        self.assertIn("продолжай", agents)
        self.assertIn("завис", agents)
        self.assertIn("docs/handoff/ACTIVE_ROUTING_HANDOFF.json", handoff_doc)


if __name__ == "__main__":
    unittest.main()
