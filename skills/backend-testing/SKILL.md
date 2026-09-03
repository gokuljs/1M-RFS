---
name: backend-testing
description: Plan, implement, and evaluate 1M-RFS backend experiments across C++, Node.js, Redis, and future backends while keeping workloads, measurements, and comparisons reproducible. Use for backend implementation, load testing, benchmarking, or backend comparisons in this repository; do not use for unrelated work or for claiming capacity without measured evidence.
---

# Backend Testing

## Purpose

Use this skill for experiments that investigate how backend systems behave under workloads targeting up to one million requests. Treat the target as an engineering question to measure, not as a result that has already been achieved.

## Before implementation

- Read the repository `README.md` and `AGENTS.md` before making changes.
- Define the request behavior, workload shape, success criteria, and comparison boundary for the experiment.
- Do not invent exact toolchain versions, dependencies, service interfaces, or deployment topology while those decisions remain open. Record decisions when they are intentionally made.
- Keep backend-specific code isolated from shared workload definitions and evaluation logic.

## Backend coverage

- C++ experiments should keep build, runtime, and test assumptions explicit.
- Node.js experiments should keep package-manager, runtime, and test assumptions explicit.
- Redis experiments should distinguish service behavior from datastore behavior and record relevant Redis configuration.
- Additional backends should implement the same observable request contract where practical so results remain comparable.

## Testing and benchmarking

- Add focused correctness tests with each implementation change.
- For load tests, record the workload, concurrency, duration, request mix, environment, configuration, dataset, errors, throughput, latency distribution, and resource usage.
- Keep warm-up, measurement, and teardown phases distinguishable.
- Repeat important measurements and report variability instead of presenting a single run as definitive.
- Do not compare results from materially different workloads or environments without calling out the difference.

## Results and commits

- Separate implementation, benchmark tooling, and result-reporting changes into focused commits.
- Review the complete diff and run the relevant checks before each commit.
- Push each completed commit to the active branch after validation.
- Do not report a one-million-request capacity claim until the supporting measurements are committed and reproducible.

## Security

- Never commit credentials, tokens, private keys, or production data.
- Use environment variables or ignored local configuration for secrets and connection details.
