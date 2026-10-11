"""Localhost Ollama independent critic: do not need API key or external provider."""
import io
import json
import os
import unittest
from unittest.mock import patch

from scripts.gauntlet_autopilot import ChatActor


class FakeResponse:
    def __init__(self, data):
        self._bytes = json.dumps(data).encode("utf-8")

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self, limit):
        return self._bytes[:limit]


class LocalModelTests(unittest.TestCase):
    def actor(self, **overrides):
        env = {"GAUNTLET_AI_BACKEND": "ollama_local",
               "GAUNTLET_AI_URL": "https://untrusted.example/chosen-elsewhere",
               "GAUNTLET_AI_TOKEN": "not-used-here",
               "GAUNTLET_BUILDER_MODEL": "qwen2.5-coder:1.5b",
               "GAUNTLET_CRITIC_MODEL": "qwen2.5-coder:7b"}
        env.update(overrides)
        with patch.dict(os.environ, env, clear=True):
            return ChatActor()

    def test_local_no_credential_required(self):
        model = self.actor(GAUNTLET_AI_TOKEN="", GAUNTLET_AI_URL="")
        self.assertEqual(model.endpoint, "http://127.0.0.1:11434/api/chat")
        self.assertEqual(model.token, "")
        self.assertNotEqual(model.builder_model, model.critic_model)

    def test_critic_is_different_model_with_no_builder_history(self):
        actor = self.actor()
        requests = []

        def serve(req, timeout):
            self.assertEqual(timeout, 360)
            self.assertEqual(req.full_url, "http://127.0.0.1:11434/api/chat")
            self.assertNotIn("authorization", {k.lower() for k in req.headers})
            body = json.loads(req.data)
            requests.append(body)
            if body["model"] == "qwen2.5-coder:1.5b":
                response = {"edits": [{"path": "smoke.py", "content": "return 6"}]}
            else:
                response = {"verdict": "PASS", "findings": []}
            return FakeResponse({"message": {"content": json.dumps(response)}})

        with patch("scripts.gauntlet_autopilot.urllib.request.urlopen", side_effect=serve):
            result_builder = actor("builder", {"source": {"smoke.py": "return 5"}})
            result_critic = actor("critic", {"diff": "+return 6", "test_log": "PASS"})
        self.assertEqual(result_builder["edits"][0]["content"], "return 6")
        self.assertEqual(result_critic["verdict"], "PASS")
        self.assertEqual([x["model"] for x in requests],
                         ["qwen2.5-coder:1.5b", "qwen2.5-coder:7b"])
        self.assertEqual([x["format"] for x in requests], ["json", "json"])
        self.assertFalse(any("return 5" in str(x["messages"]) for x in requests[1:]))

    def test_same_model_cannot_claim_independence(self):
        with self.assertRaisesRegex(RuntimeError, "different models"):
            self.actor(GAUNTLET_CRITIC_MODEL="qwen2.5-coder:1.5b")

    def test_unknown_backend_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "unsupported"):
            self.actor(GAUNTLET_AI_BACKEND="https://attacker.invalid")

    def test_remote_backend_still_requires_real_credentials(self):
        with patch.dict(os.environ, {
            "GAUNTLET_AI_BACKEND": "openai",
            "GAUNTLET_AI_URL": "http://127.0.0.1:11434/v1/chat/completions",
            "GAUNTLET_BUILDER_MODEL": "builder",
            "GAUNTLET_CRITIC_MODEL": "critic",
            "GAUNTLET_AI_TOKEN": "",
        }, clear=True):
            with self.assertRaisesRegex(RuntimeError, "HTTPS endpoint and token"):
                ChatActor()


if __name__ == "__main__":
    unittest.main()
