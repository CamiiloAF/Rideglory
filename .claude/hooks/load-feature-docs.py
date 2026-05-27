#!/usr/bin/env python3
"""
Hook: PreToolUse (Edit|Write)
Lee la documentación del feature antes de que Claude edite/escriba un archivo en lib/features/<feature>/.
Soporta docs/features/<feature>.md y docs/features/<feature>/ (directorio con .md recursivos).
"""
import sys
import json
import os
import glob

data = json.load(sys.stdin)
file_path = data.get("tool_input", {}).get("file_path", "")

# Extraer el nombre del feature de rutas como .../lib/features/<feature>/...
parts = file_path.replace("\\", "/").split("/")
try:
    feat_idx = parts.index("features")
    feature = parts[feat_idx + 1] if feat_idx + 1 < len(parts) else ""
except (ValueError, IndexError):
    feature = ""

if not feature:
    sys.exit(0)

docs_base = "/Users/cami/Developer/Personal/Rideglory/docs/features"
docs = []

# Caso 1: archivo único docs/features/<feature>.md
md_file = os.path.join(docs_base, feature + ".md")
if os.path.isfile(md_file):
    with open(md_file) as fh:
        docs.append(fh.read())

# Caso 2: directorio docs/features/<feature>/ con archivos .md
docs_dir = os.path.join(docs_base, feature)
if os.path.isdir(docs_dir):
    for f in sorted(glob.glob(os.path.join(docs_dir, "**", "*.md"), recursive=True)):
        with open(f) as fh:
            docs.append(f"### {os.path.basename(f)}\n" + fh.read())

if not docs:
    sys.exit(0)

combined = "\n\n---\n\n".join(docs)
result = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": f'[CONTEXTO AUTO] Documentación del feature "{feature}":\n\n{combined}'
    }
}
print(json.dumps(result))
