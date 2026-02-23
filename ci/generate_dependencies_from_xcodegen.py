#!/usr/bin/env python3

import json
import subprocess
from pathlib import Path

PROJECT_YML = Path("project.yml")
OUTPUT = Path("ci/dependencies.json")

# Use Ruby (previously instaled) to convert YAML → JSON
yaml_as_json = subprocess.check_output(
    [
        "ruby",
        "-ryaml",
        "-rjson",
        "-e",
        f"puts YAML.load_file('{PROJECT_YML}').to_json"
    ],
    text=True
)

spec = json.loads(yaml_as_json)
targets = spec.get("targets", {})

graph = {}

for target, config in targets.items():
    deps = []
    for dep in config.get("dependencies", []):
        if isinstance(dep, dict) and "target" in dep:
            deps.append(dep["target"])
    graph[target] = sorted(deps)

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
OUTPUT.write_text(json.dumps(graph, indent=2))

print("Generated dependency graph:")
print(json.dumps(graph, indent=2))