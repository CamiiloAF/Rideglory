#!/usr/bin/env python3
"""
Hook: PreToolUse (Edit|Write)
Inyecta la documentación del feature antes de editar archivos en lib/features/<feature>/.
Soporta docs/features/<feature>.md y docs/features/<feature>/ (directorio con .md recursivos).
Dedupe: inyecta UNA sola vez por (sesión, feature) usando un marker en /tmp,
para no repetir los mismos docs en cada Edit/Write de la misma corrida.
"""
import sys
import json
import os
import glob
import hashlib

data = json.load(sys.stdin)
file_path = data.get("tool_input", {}).get("file_path", "")
session_id = data.get("session_id", "")

parts = file_path.replace("\\", "/").split("/")
try:
    feat_idx = parts.index("features")
    feature = parts[feat_idx + 1] if feat_idx + 1 < len(parts) else ""
except (ValueError, IndexError):
    feature = ""

if not feature or feature.endswith(".dart"):
    sys.exit(0)

project_dir = os.environ.get(
    "CLAUDE_PROJECT_DIR", "/Users/cami/Developer/Personal/Rideglory"
)
docs_base = os.path.join(project_dir, "docs", "features")

marker = os.path.join(
    "/tmp",
    "claude-feature-docs-"
    + hashlib.sha1(f"{session_id}:{feature}".encode()).hexdigest()[:16],
)
if session_id and os.path.exists(marker):
    sys.exit(0)

docs = []

md_file = os.path.join(docs_base, feature + ".md")
if os.path.isfile(md_file):
    with open(md_file) as fh:
        docs.append(fh.read())

docs_dir = os.path.join(docs_base, feature)
if os.path.isdir(docs_dir):
    for f in sorted(glob.glob(os.path.join(docs_dir, "**", "*.md"), recursive=True)):
        with open(f) as fh:
            docs.append(f"### {os.path.basename(f)}\n" + fh.read())

if not docs:
    sys.exit(0)

if session_id:
    try:
        open(marker, "w").close()
    except OSError:
        pass

combined = "\n\n---\n\n".join(docs)
MAX_CHARS = 30000
if len(combined) > MAX_CHARS:
    combined = combined[:MAX_CHARS] + "\n\n[... truncado; ver docs/features/ para el resto]"

result = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": (
            f'[CONTEXTO AUTO — se inyecta una vez por sesión] Documentación del feature "{feature}":\n\n'
            + combined
        ),
    }
}
print(json.dumps(result))
