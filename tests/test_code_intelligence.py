from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools/project-memory/code_intelligence.py"
SPEC = importlib.util.spec_from_file_location("code_intelligence", MODULE_PATH)
assert SPEC and SPEC.loader
CODE_INTELLIGENCE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CODE_INTELLIGENCE)


class CodeIntelligenceTests(unittest.TestCase):
    def section(self) -> dict:
        return {
            "enabled": True,
            "provider": "fixture",
            "project_path": ".",
            "allowed_tools": ["get_context", "get_risk"],
            "capabilities": {
                "context": {"tool": "get_context", "argument": "target"},
                "risk": {"tool": "get_risk", "argument": "target"},
            },
            "transport": {
                "kind": "mcp-stdio",
                "command": sys.executable,
                "args": [str(ROOT / "tests/fixtures/fake_code_intelligence_mcp.py")],
            },
            "routing": {
                "default_route": "project_memory",
                "combined_route": "federated",
                "fallback_sources": ["project_memory", "source_files"],
                "routes": [
                    {"id": "project_memory", "sources": ["project_memory"], "terms": ["decision"]},
                    {
                        "id": "code_intelligence",
                        "sources": ["code_intelligence"],
                        "terms": ["caller"],
                        "path_extensions": [".py"],
                    },
                ],
            },
            "freshness": {"require_indexed_commit": True, "warn_on_dirty_worktree": True},
        }

    def test_router_uses_configured_indicators(self) -> None:
        section = self.section()
        self.assertEqual(
            CODE_INTELLIGENCE.configured_route(section, "which caller uses module.py?")["route"],
            "code_intelligence",
        )
        self.assertEqual(
            CODE_INTELLIGENCE.configured_route(section, "decision and caller")["route"],
            "federated",
        )

    def test_router_falls_back_when_provider_is_disabled(self) -> None:
        section = self.section()
        section["enabled"] = False
        result = CODE_INTELLIGENCE.configured_route(section, "which caller uses module.py?")
        self.assertEqual(result["route"], "fallback")
        self.assertEqual(result["sources"], ["project_memory", "source_files"])
        self.assertTrue(result["fallback"])

    def test_freshness_detects_commit_mismatch_and_dirty_tree(self) -> None:
        freshness = CODE_INTELLIGENCE.assess_freshness(
            self.section(),
            {"indexed_commit": "old", "live_head": "new"},
            {"head": "new", "dirty": True},
        )
        self.assertTrue(freshness["stale"])
        self.assertEqual(len(freshness["warnings"]), 2)

    def test_freshness_accepts_abbreviated_commit_and_nested_meta(self) -> None:
        result = {
            "structuredContent": {
                "result": {"_meta": {"indexed_commit": "abcdef123456"}}
            }
        }
        meta = CODE_INTELLIGENCE.extract_provider_meta(result)
        freshness = CODE_INTELLIGENCE.assess_freshness(
            self.section(), meta, {"head": "abcdef1234567890", "dirty": False}
        )
        self.assertFalse(freshness["stale"])

    def test_status_and_call_work_with_mcp_fixture(self) -> None:
        config = {"code_intelligence": self.section()}
        with tempfile.NamedTemporaryFile("w", suffix=".json", encoding="utf-8", delete=False) as handle:
            json.dump(config, handle)
            config_path = Path(handle.name)
        try:
            status = subprocess.run(
                [sys.executable, str(MODULE_PATH), "--config", str(config_path), "status"],
                cwd=ROOT,
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(status.returncode, 0, status.stdout + status.stderr)
            self.assertTrue(json.loads(status.stdout)["ok"])
            call = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    "--config",
                    str(config_path),
                    "call",
                    "get_context",
                    "--arguments",
                    '{"target":"Example"}',
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(call.returncode, 0, call.stdout + call.stderr)
            payload = json.loads(call.stdout)
            self.assertEqual(payload["tool"], "get_context")
            self.assertTrue(payload["freshness"]["stale"])
        finally:
            config_path.unlink(missing_ok=True)

    def test_call_rejects_non_allowlisted_tool(self) -> None:
        config = {"code_intelligence": self.section()}
        with tempfile.NamedTemporaryFile("w", suffix=".json", encoding="utf-8", delete=False) as handle:
            json.dump(config, handle)
            config_path = Path(handle.name)
        try:
            result = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    "--config",
                    str(config_path),
                    "call",
                    "generate_refactoring_code",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("not allowlisted", result.stdout)
        finally:
            config_path.unlink(missing_ok=True)

    def test_config_rejects_inline_environment_values(self) -> None:
        section = self.section()
        section["transport"]["env"] = {"TOKEN": "not-allowed"}
        self.assertTrue(
            any("inline environment values" in error for error in CODE_INTELLIGENCE.validate_config(section))
        )


if __name__ == "__main__":
    unittest.main()
