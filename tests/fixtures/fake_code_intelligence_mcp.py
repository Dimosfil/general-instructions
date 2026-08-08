#!/usr/bin/env python3
"""Small newline-delimited MCP server used by code-intelligence adapter tests."""

from __future__ import annotations

import json
import sys


TOOLS = [
    {"name": "get_context", "description": "fixture", "inputSchema": {"type": "object"}},
    {"name": "get_risk", "description": "fixture", "inputSchema": {"type": "object"}},
]


for line in sys.stdin:
    request = json.loads(line)
    if "id" not in request:
        continue
    method = request.get("method")
    if method == "initialize":
        result = {
            "protocolVersion": request.get("params", {}).get("protocolVersion"),
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "fake-code-intelligence", "version": "1"},
        }
    elif method == "tools/list":
        result = {"tools": TOOLS}
    elif method == "tools/call":
        params = request.get("params") or {}
        result = {
            "content": [{"type": "text", "text": json.dumps(params)}],
            "structuredContent": {"echo": params},
            "_meta": {"indexed_commit": "fixture-index", "live_head": "fixture-live"},
        }
    else:
        result = {}
    print(json.dumps({"jsonrpc": "2.0", "id": request["id"], "result": result}), flush=True)
