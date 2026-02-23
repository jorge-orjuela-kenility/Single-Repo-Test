# Release Process

This document describes how we **cut releases** and **publish them**
using a **single release train model**:

-   One shared version for the entire monorepo\
-   One internal Git tag\
-   One external distribution repository\
-   One unified changelog per release

All frameworks are versioned and released together.

------------------------------------------------------------------------

## Overview

We operate a **single release train** across the SDK:

-   **One version** for the whole monorepo (e.g. `1.0.0` or
    `1.0.0.RC-1`)
-   **One internal tag** per release (e.g. `1.0.0`)
-   **One external distribution repository:**\
    `Truvideo/truvideo-sdk-ios-core`
-   **One `Package.swift`** declaring all binary XCFrameworks
-   **One shared changelog**, generated from conventional commits in the
    release range and used as the GitHub release notes

### Release Workflow

Single workflow:

    .github/workflows/release.yml
    (Job: "Release")

Runs when:

-   PR merged into `release/next` with `cut-rc`, or\
-   Manually triggered via `workflow_dispatch` (`rc` or `prod`, optional
    `dry_run`)

**Dry run:** When `dry_run` is enabled (manual only), the workflow shows what would be done but does not create tags, push commits, or create/update the external release.

The workflow:

1.  Computes the next version\
2.  Versions all frameworks\
3.  Builds all XCFrameworks\
4.  Updates the external `Package.swift`\
5.  Publishes a GitHub release with all artifacts and the shared
    changelog

------------------------------------------------------------------------

# Repo Layout & Local Tooling

The repository uses a layered, modular structure. Project generation and builds are driven by **XcodeGen** and the **Makefile**.

Common local commands:

| Command | Description |
|---------|--------------|
| `make genbuild` | Generate the Xcode project, build it, and open it. Use to verify the project compiles before cutting a release. |
| `make xcframeworks` | Build all frameworks as XCFrameworks (device + simulator). Output: `DerivedData/XCFrameworks/` (e.g. `TruvideoSdk.xcframework`, `TruvideoSdkCamera.xcframework`, …). |
| `make framework SCHEME=<Name>` | Build a single scheme as an XCFramework (e.g. `make framework SCHEME=TruvideoSdk`). |

These match what the release workflow runs: `make genbuild` before versioning, then `make xcframeworks` before publishing to the external repo.

------------------------------------------------------------------------

# Versioning Strategy

We follow **Semantic Versioning (SemVer)** for the base version
(e.g. `1.2.0`).\
The same base version is applied to all frameworks.

## Version Formats

  Channel   Format
  --------- --------------
  RC        `1.2.0.RC-N`
  PROD      `1.2.0`

### RC

-   Base version is not bumped **when the latest tag is already an RC** (e.g. `1.0.0.RC-2` → next is `1.0.0.RC-3`).
-   **When the latest tag is a production tag** (e.g. `1.0.0`), the next RC uses the **bumped** version (from conventional commits since that tag) with **`.RC-1`** (e.g. `1.0.1.RC-1` or `1.1.0.RC-1`).
-   So: first RCs after a prod release start at `.RC-1` for the new version; RCs for the same base increment N.

### PROD

-   Base version is bumped using conventional commits since the last
    tag.

  Commit Type              Bump
  ------------------------ -------
  BREAKING CHANGE / `!:`   Major
  `feat:`                  Minor
  `fix:`, `perf:`          Patch
  default                  Patch

------------------------------------------------------------------------

# Release Execution Flow

## 1. Trigger

-   RC: Merge to `release/next` with `cut-rc`
-   PROD: Manual `workflow_dispatch`

------------------------------------------------------------------------

## 2. Validate & Build

    make genbuild

Ensures project compiles before versioning.

------------------------------------------------------------------------

## 3. Compute Version

-   Determine latest tag
-   Compute commit range (`last_tag..HEAD`)
-   Resolve RC or PROD version

------------------------------------------------------------------------

## 4. Generate Changelog

-   Parse conventional commits
-   Clean commit messages
-   Group by type
-   Produce single shared changelog

------------------------------------------------------------------------

## 5. Apply Version to All Frameworks

For each framework:

### Update `Info.plist`

-   `CFBundleShortVersionString`
-   `CFBundleVersion`
-   `TRVReleaseChannel`

### Update `Version.swift`

-   Update in place if exists (only version, channel, build number; for Core also `SDKSecretKey` from secrets).
-   Create if missing.
-   Preserve file structure and style.

------------------------------------------------------------------------

## 6. Commit & Tag

    chore(release): bump to <version> (<channel>)

Tag format:

    <version>

Examples: - `1.2.0.RC-3` - `1.3.0`

------------------------------------------------------------------------

## 7. Build All XCFrameworks

    make xcframeworks

Output:

    DerivedData/XCFrameworks/

------------------------------------------------------------------------

## 8. Publish to External Repository

External repo:

`Truvideo/truvideo-sdk-ios-core`

Steps:

1.  Zip each XCFramework

2.  Compute checksum:

        swift package compute-checksum <file>.zip

3.  Update `Package.swift` in place

4.  Push tag

5.  Create GitHub release

6.  Upload all artifacts

7.  Attach shared changelog

------------------------------------------------------------------------

# Release Flow Diagram

``` mermaid
flowchart TD

    A[PR merged to release/next with cut-rc<br/>or Manual workflow_dispatch] --> B[Release Workflow Starts]

    B --> C[Validate branch and policy]
    C --> D[make genbuild]

    D --> E[Compute Version<br/>RC or PROD]
    E --> F[Generate Changelog]

    F --> G[Update Info.plist & Version.swift<br/>for all frameworks]
    G --> H[Create Single Commit & Tag]

    H --> I[make xcframeworks]
    I --> J[Zip Artifacts + Compute Checksums]

    J --> K[Update External Package.swift]
    K --> L[Create External GitHub Release]

    L --> M[Upload All XCFramework Zips]
```

------------------------------------------------------------------------

# Labels

  Label      Purpose
  ---------- -------------------------------------------
  `cut-rc`   Allow RC cut on merge into `release/next`
  `prod`     Manual only

SDK/component labels are auto-applied and do not affect release scope.

------------------------------------------------------------------------

# Summary

This release system guarantees:

-   One shared version
-   One internal tag
-   One external distribution repository
-   One `Package.swift`
-   One unified changelog
-   All frameworks built and published together

It enforces deterministic releases, zero version drift, and a single
source of truth for SDK distribution.
