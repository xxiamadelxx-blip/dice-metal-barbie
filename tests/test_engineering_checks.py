"""Executable offline checks: no external services and no generated asset invention."""
from __future__ import annotations

import json
from pathlib import Path
import struct
import tempfile
import unittest
import wave

from scripts.engineering_checks import gd_architecture, secrets, wav_audio, frame_timings


class EngineeringCheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def write(self, relative, content):
        target = self.root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        return target

    def make_wav(self, name, value, frames=120):
        filename = self.root / name
        with wave.open(str(filename), "wb") as stream:
            stream.setnchannels(1)
            stream.setsampwidth(2)
            stream.setframerate(48000)
            stream.writeframes(struct.pack("<" + "h" * frames, *([value] * frames)))
        return filename

    def test_valid_literal_dependency_map(self):
        self.write("src/main.gd", 'var x = preload("res://src/core/rng.gd")\n')
        self.write("src/core/rng.gd", "extends RefCounted\n")
        result = gd_architecture(self.root)
        self.assertEqual(result["verdict"], "PASS_STATIC_ONLY")
        self.assertEqual(result["edges"], 1)

    def test_rejects_ui_dependency_and_missing_files(self):
        self.write("src/core/rng.gd", 'var x = preload("res://src/ui/screen.gd")\n'
                                     'var y = preload("res://src/core/absent.gd")\n')
        self.write("src/ui/screen.gd", "extends Control\n")
        result = gd_architecture(self.root)
        self.assertEqual(result["verdict"], "FAIL")
        self.assertTrue(any(x["problem"] == "forbidden runtime layering" for x in result["findings"]))
        self.assertTrue(any(x["problem"] == "missing static source" for x in result["findings"]))

    def test_detects_static_dependency_cycle(self):
        self.write("src/core/a.gd", 'var next = load("res://src/core/b.gd")\n')
        self.write("src/core/b.gd", 'var prev = load("res://src/core/a.gd")\n')
        result = gd_architecture(self.root)
        self.assertEqual(result["verdict"], "FAIL")
        self.assertTrue(any("cycle" in x["problem"] for x in result["findings"]))

    def test_secret_findings_are_always_redacted(self):
        token = "ghp_" + ("X" * 40)
        self.write("src/debug.gd", "var token = '" + token + "'\n")
        result = secrets(self.root)
        self.assertEqual(result["verdict"], "FAIL")
        self.assertEqual(result["findings"][0]["line"], 1)
        self.assertNotIn(token, json.dumps(result))
        self.assertEqual(result["findings"][0]["rule"], "github-access-token")

    def test_audio_peak_not_human_acceptance(self):
        clean = wav_audio(self.make_wav("clean.wav", 12000))
        self.assertEqual(clean["verdict"], "PASS_SIGNAL_ONLY")
        self.assertEqual(clean["channels"], 1)
        self.assertGreater(clean["duration_s"], 0)
        self.assertIn("NOT_VERIFIED", clean["scope_note"])
        self.assertEqual(wav_audio(self.make_wav("silent.wav", 0))["verdict"], "FAIL")
        self.assertEqual(wav_audio(self.make_wav("clip.wav", 32767))["verdict"], "FAIL")

    def test_perf_never_substitutes_mesa_for_real_phone(self):
        valid = {"device_kind": "phone", "device_model": "test-phone",
                 "frame_ms": [12.5] * 40, "target_fps": 60}
        self.assertEqual(frame_timings(valid)["verdict"], "PASS_PHONE_FRAMETIME")
        self.assertEqual(frame_timings(valid | {"device_kind": "mesa"})["verdict"],
                         "NOT_VERIFIED_DEVICE")
        self.assertEqual(frame_timings(valid | {"frame_ms": [22.0] * 40})["verdict"], "FAIL")
        self.assertEqual(frame_timings(valid | {"frame_ms": [12.0]})["verdict"], "NOT_VERIFIED")
        self.assertEqual(frame_timings(valid | {"frame_ms": [float("nan")] * 40})["verdict"],
                         "NOT_VERIFIED")

    def test_repo_has_canonical_checks_documentation(self):
        root = Path(__file__).resolve().parents[1]
        docs = (root / "docs/ENGINEERING_ROUTER.md").read_text(encoding="utf-8")
        for command in ("engineering_checks.py architecture", "engineering_checks.py security",
                        "engineering_checks.py audio", "engineering_checks.py performance"):
            self.assertIn(command, docs)


if __name__ == "__main__":
    unittest.main()
