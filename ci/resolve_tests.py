#!/usr/bin/env python3

import os
import json
import sys
import subprocess
from pathlib import Path
from fnmatch import fnmatch

BASE_REF = sys.argv[1]  # e.g. origin/main
github_output = os.environ.get("GITHUB_OUTPUT")

def git_diff_files(base_ref):
    result = subprocess.check_output(
        ["git", "diff", "--name-only", f"{base_ref}...HEAD"],
        text=True
    )
    return [line.strip() for line in result.splitlines() if line.strip()]

def load_yaml_via_ruby(path):
    yaml_as_json = subprocess.check_output(
        [
            "ruby",
            "-ryaml",
            "-rjson",
            "-e",
            f"puts YAML.load_file('{path}').to_json"
        ],
        text=True
    )
    return json.loads(yaml_as_json)

def load_json(path):
    with open(path) as f:
        return json.load(f)

def classify_change_type(files):
    """
    Retorna:
      "test" if ALL files are under Tests/ or Testing/
      "production" if there is at least one production file
    """
    for file in files:
        parts = Path(file).parts
        if "Tests" not in parts and "Testing" not in parts:
            return "production"
    return "test"


def match_targets(files, target_paths):
    modified = {}
    for target, patterns in target_paths.items():
        for file in files:
            for pattern in patterns:
                if fnmatch(file, pattern):
                    modified.setdefault(target, []).append(file)
    return modified

def build_reverse_graph(graph):
    reverse = {t: [] for t in graph}
    for target, deps in graph.items():
        for dep in deps:
            reverse[dep].append(target)
    return reverse

def get_all_dependents(target, reverse_graph):
    visited = set()
    stack = [target]

    while stack:
        current = stack.pop()
        for dep in reverse_graph.get(current, []):
            if dep not in visited:
                visited.add(dep)
                stack.append(dep)
    return visited

def main():
    changed_files = git_diff_files(BASE_REF)

    target_paths = load_yaml_via_ruby("ci/target_paths.yml")
    dependency_graph = load_json("ci/dependencies.json")

    modified_targets = match_targets(changed_files, target_paths)

    reverse_graph = build_reverse_graph(dependency_graph)

    resolved_targets = set()

    classified_targets = {}

    for target, files in modified_targets.items():
        change_type = classify_change_type(files)
        classified_targets[target] = change_type
        resolved_targets.add(target)

        if change_type == "production":
            dependents = get_all_dependents(target, reverse_graph)
            resolved_targets.update(dependents)

    resolved_targets = sorted(resolved_targets)

    print("=== Dependency-Aware Test Resolution ===\n")

    print("Modified targets:")
    for t, change_type in classified_targets.items():
        print(f"- {t} ({change_type})")

    print("\nResolved dependent targets:")
    for t in resolved_targets:
        if t not in modified_targets:
            print(f"- {t}")

    test_schemes = [f"{t}" for t in resolved_targets]

    print("\nFinal test schemes:")
    for s in test_schemes:
        print(f"- {s}")

    # GitHub Actions output
    if github_output:
        with open(github_output, "a") as f:
            f.write(f"test_schemes={','.join(test_schemes)}\n")

if __name__ == "__main__":
    main()
