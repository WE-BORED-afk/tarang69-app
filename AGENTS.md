# TARANG69 App — Agent & Skill Guide

Before making changes or vibe-coding in this repository, read [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) for architecture, UI decisions, device details, and release rules.

## Active Global Plugins & Skills

These tools are installed **globally** on the workstation (not vendored into this repo). Use the matching skill whenever a task falls in its domain:

### 1. Lean Code & Review (`ponytail` — Global Plugin)
- **`ponytail`** (default `full`): Apply on every coding/vibe-coding task. Make the smallest complete change, reuse existing helpers/widgets in `lib/`, avoid unnecessary dependencies or abstractions, and end technical change reports with what was skipped/not checked and any risks.
- **`ponytail-review`**: Review uncommitted changes or diffs for bugs, edge cases, and bloat.
- **`ponytail-audit`**: One-shot lean/quality audit across the repo.

### 2. Engineering Workflow & Safety (`superpowers` — Global Plugin)
- **`brainstorming`** / **`writing-plans`**: Use before large new features or structural refactors.
- **`systematic-debugging`**: Use when diagnosing bugs (e.g., countdown timer drift, break/weekend edge cases, Android widget refresh issues).
- **`test-driven-development`**: Use when modifying schedule/sync logic alongside [test/schedule_test.dart](./test/schedule_test.dart) and [test/widget_test.dart](./test/widget_test.dart).
- **`verification-before-completion`**: Run verification (`flutter analyze` / `flutter test`) and confirm actual output before claiming a fix or feature is complete.

### 3. Flutter & Dart (`flutter` — Global Plugin + MCP)
- **`dart-run-static-analysis`** / **`dart-fix-runtime-errors`**: Check lints and active errors when editing Dart code.
- **`flutter-fix-layout-issues`** / **`flutter-build-responsive-layout`**: Use for overflow, sizing, or mobile/web responsive UI work.
- **`dart-add-unit-test`** / **`flutter-add-widget-test`**: Add/update tests for `ScheduleService` and UI widgets.
- **`flutter-use-http-package`** / **`flutter-implement-json-serialization`**: Use when modifying remote GitHub schedule fetching or `assets/data/schedule.json` parsing.

### 4. Android Testing & Deployment (`android-cli-plugin` — Global Plugin)
- **`android-device-hub`** / **`android-cli`**: Mirror, inspect UI, or verify behavior on a connected Android device/emulator (see [scripts/deploy_a51.ps1](./scripts/deploy_a51.ps1) for Samsung Galaxy A51 deployment).
- Note: The Home Screen Widget uses native Android XML/Kotlin (`widget_layout.xml`, `Tarang69WidgetProvider.kt`), not Jetpack Compose.

### 5. UI / UX Polish (`ui-ux-pro-max` — Global Skill)
- **`ui-ux-pro-max`**: Use when designing new screens, refining color contrast, typography, or mobile UI patterns. Query with `--stack flutter` and keep outputs aligned with this app's minimal UI rules (no room badges, clean icon-first header) and `ponytail` simplicity.

## Project Guardrails
- **Release safety:** `.github/workflows/build-apk.yml` triggers a release build on pushes to `main` (ignoring only `scripts/**`, `**.md`, `.gitignore`). Do not commit non-`.md` agent/skill bundles into the repo, and always confirm with the user before triggering or publishing a release.
- **Keep skills out of repo:** Prefer Global skills/plugins (`~/.gemini/config/` and `~/.agents/skills/`) rather than copying tool scripts into this repository.
