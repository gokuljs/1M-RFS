---
name: readme-writing
description: Write and revise concise, accurate README files for the 1M-RFS repository. Use when documenting the project purpose, current scope, verified usage, or measured results; do not invent setup steps, dependencies, or performance claims.
---

# README Writing

## Purpose

Keep the repository README short, clear, and useful to someone seeing the project for the first time.

## Writing rules

- Lead with a one-sentence description of the project.
- State the current goal and scope before describing future work.
- Mention only technologies, commands, dependencies, and workflows verified in the repository.
- Distinguish planned experiments from measured results.
- Never present an unmeasured performance target as an achieved capability.
- Prefer short paragraphs and focused bullet lists over repeated explanations.
- Keep detailed agent rules, benchmark procedures, and implementation notes in their dedicated files.

## Before editing

- Inspect the repository structure and existing documentation.
- Preserve accurate information unless the task explicitly changes it.
- Remove stale, duplicated, or unsupported claims.

## Validation

- Review the rendered Markdown for readability.
- Check links and commands when they are included.
- Run git diff --check.
