---
name: project-guardrails
description: Personal project guardrails for this user and this repository. Use for all tasks in this project, especially coding, debugging, UI/art asset work, GitHub operations, architecture decisions, simulator/device testing, repeated fix attempts, and any task where Codex might overreach, guess without evidence, or keep iterating in a wrong direction.
---

# Project Guardrails

Before doing work in this repository, read these guardrails and apply them as constraints. Treat them as project-level operating rules, not optional preferences.

## Start-Of-Task Checklist

- Check whether the task involves visible art assets; if yes, use the image generation skill/tool for the asset itself.
- Keep changes tied to the user's request and avoid unrelated modules.
- Analyze the requirement as a technical expert; do not reflexively agree with the user's proposed solution.
- Do not push, upload, publish, create PRs, or otherwise send anything to GitHub without explicit user instruction.
- If two iterations fail to produce a clear result, stop and reassess the direction with the user.
- For bug fixes, gather evidence before changing uncertain code.

## 1. Art Assets Must Use Image Generation

Bad behavior:
- Implemented visual art assets with code instead of generating proper image assets.
- Generated art existed in a preview or temporary file, but the running app used a placeholder, simplified replacement, or wrong asset.

Required behavior:
- For anything explicitly marked as an art asset, visual asset, illustration, background, character, icon, decorative image, or similar, use the image generation skill/tool.
- For any visible art asset generation, replacement, wiring, or review, also read and follow `.codex/skills/art-asset-integration-guard/SKILL.md` before claiming completion.
- Before replacing source rasters, `.imageset` files, or UI references for generated art, prove the raw generated artifact handoff: a local generator output file or a rollout `image_generation_call.result` PNG decoded into a raw source file with provenance.
- Do not recreate directly visible art resources with hand-written code unless the user explicitly asks for code-native or vector implementation.
- Code may integrate, load, mask, place, or animate generated assets, but should not be the primary way the art itself is created.
- Do not treat chat previews, thumbnails, remembered image-generation results, temporary clipboard images, composite previews, green-screen mockups, assumed `$CODEX_HOME/generated_images/...` paths, or `UIImage(named:) != nil` checks as proof that art is integrated.
- If a generated preview exists but no raw generated PNG/provenance can be produced, stop; do not substitute `PIL/ImageDraw`, SVG, SwiftUI drawing, canvas, SF Symbols, old art, or line sketches.

Completion check:
- Check whether any visible art asset was implemented through code.
- If yes, remake it with image generation unless the user explicitly requested code-based art.
- Check that generated art has raw PNG/provenance evidence before post-processing or asset catalog replacement.
- Check that final source art, app-facing `.imageset` PNG, compiled bundle, and running UI screenshot all show the intended asset. If any link is missing, say the art is not fully integrated.

Trigger:
- Tasks explicitly involving art assets.
- Tasks involving generated art assets and code integration.
- Any task involving generated PNGs, source raster files, asset catalogs, SwiftUI image loading, simulator screenshots, or visual asset QA.

## 2. Stay Within The Requested Module

Bad behavior:
- Repeatedly rolled back or reworked the same problem area, such as Apple Health logic, and kept causing regressions.

Required behavior:
- Keep development modular and tied to the user's request.
- Do not modify unrelated modules, flows, files, or business logic outside the requested scope.
- Before changing shared logic, inspect existing behavior and dependencies.

Completion check:
- Review whether any change goes beyond the user's request.
- If there are out-of-scope changes, warn the user and explain why they were made, or avoid them if unnecessary.

Trigger:
- All code-side tasks.
- Any task involving existing app logic, health data, sync behavior, persistence, or cross-module interaction.

## 3. Do Not Reflexively Agree With The User

Bad behavior:
- Agreed too quickly with the user's proposed direction without expert analysis.

Required behavior:
- Act as a technical expert.
- Analyze the requirement carefully.
- Consider project stability, maintainability, architecture, and long-term consequences.
- If the user's proposed approach seems risky or suboptimal, say so clearly and suggest a better technical plan.

Completion check:
- Check whether the chosen solution is appropriate from the whole-project perspective.
- If a better approach exists, present it before implementing or continuing.

Trigger:
- All tasks.
- Especially architecture, debugging, feature design, refactoring, and technical decision tasks.

## 4. Never Push To GitHub Without Explicit Instruction

Bad behavior:
- Uploaded or pushed to GitHub based on context instead of an explicit user request.

Required behavior:
- Do not push, publish, upload, create a PR, or otherwise send anything to GitHub unless the user explicitly asks.
- Local commits are also only appropriate when the user asks for commit-related work.

Completion check:
- Check whether any command or plan implies pushing, uploading, publishing, or creating a remote GitHub artifact.
- If yes, stop unless the user explicitly requested it.

Trigger:
- All tasks.
- Any task involving git, GitHub, commits, branches, remotes, PRs, releases, or deployment.

## 5. Stop After Two Failed Iterations

Bad behavior:
- Continued iterating in a wrong direction or bad solution until the code became messy and hard to maintain.

Required behavior:
- If two iterations fail to produce a clear, effective result, stop and tell the user the current direction may be wrong.
- Reassess the root cause, technical plan, and assumptions before making more changes.
- Prefer a simpler, cleaner redesign over piling patches onto a failing approach.

Completion check:
- Pay special attention to tasks that have already gone through two attempts without clear progress.
- If the task is stuck, report that the direction may be incorrect and propose a reset or alternative plan.

Trigger:
- All tasks.
- Especially debugging, UI tuning, data logic, integration work, and repeated fix attempts.

## 6. Debug With Evidence Before Changing Code

Bad behavior:
- Guessed the cause of bugs and changed code without evidence.

Required behavior:
- Prioritize debugging before editing.
- Use logs, tests, simulator output, device logs, reproduction steps, screenshots, database inspection, or other evidence.
- Do not guess blindly unless the problem has been clearly localized.
- If evidence is unavailable, say what evidence is missing and how to obtain it.

Completion check:
- Before modifying uncertain code, confirm there is test output, logs, reproduction evidence, or a clear diagnosis.
- If not, gather evidence first.

Trigger:
- All bug-fix tasks.
- Any task involving uncertain behavior, simulator/device issues, crashes, regressions, data sync, persistence, or platform APIs.

## Final Response Checklist

- State whether the work stayed within the requested scope.
- Mention any evidence used for debugging or verification.
- Mention if no GitHub push/upload was performed.
- For art-related tasks, state whether image generation was used for visible art assets.
