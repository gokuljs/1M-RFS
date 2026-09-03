# Agent Guidelines

## Repository purpose

This repository investigates how backend systems can be designed and tested toward handling up to one million requests. Treat performance as an experimental question: do not present benchmark results or capacity claims until they have been measured and documented.

## Current project stage

The repository is currently documentation-first. Detailed requirements, exact toolchain versions, dependencies, interfaces, service topology, and backend implementations will be defined in later commits. Do not invent those decisions while they are still intentionally open.

## Planned backend areas

The initial exploration is expected to include:

- C++ services and their build and test tooling
- Node.js services and their build and test tooling
- Redis-backed workloads
- Additional backends added as separate experiments

Keep shared workload definitions and evaluation criteria backend-neutral wherever practical. Backend-specific behavior, assumptions, and limitations must be documented explicitly.

## Engineering workflow

- Read the existing README and relevant documentation before changing the repository.
- Make one focused, reviewable change at a time.
- Keep commits small and use a clear commit message describing the change.
- Push each completed commit to the active branch after validation.
- Add or update tests with implementation changes; documentation-only changes must at least pass `git diff --check`.
- For future benchmarks, record the workload, environment, configuration, dataset, measurement method, and observed results so experiments are reproducible.

## Security and configuration

- Never commit credentials, tokens, private keys, or production data.
- Use environment variables or local, ignored configuration for secrets and connection details.
- Keep local-development defaults safe and clearly distinguish them from production settings.

## Completion standard

Before calling a change complete, verify the intended files, review the complete diff, run the relevant checks, and report any unverified assumptions or limitations.
