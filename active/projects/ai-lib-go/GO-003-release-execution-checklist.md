# GO-003 Release Execution Checklist

## Gate Before Release

- [ ] GO runtime capability parity confirmed (`GO-002` closed)
- [ ] Cross-runtime compliance evidence archived (Go/Rust/Python/TS)
- [ ] Changelog/release notes prepared per repository

## Matrix Commit and Push

- [ ] `ai-protocol` commit and push
- [ ] `ai-lib-go` commit and push
- [ ] `ai-lib-rust` commit and push
- [ ] `ai-lib-python` commit and push
- [ ] `ai-lib-ts` commit and push
- [ ] `ai-protocol-mock`/`spiderswitch` updates pushed if release-coupled

## Package Publishing

- [ ] Rust crate publish (crates.io)
- [ ] Python package publish (PyPI)
- [ ] TypeScript package publish (npm)
- [ ] Go module release tag push and proxy availability verification

## Post-Publish Verification

- [ ] Rust install smoke test from registry
- [ ] Python install smoke test from PyPI
- [ ] TypeScript install smoke test from npm
- [ ] Go `go get` smoke test via module proxy

## ailib.info Sync

- [ ] Update runtime matrix pages (EN/ZH/JA/ES)
- [ ] Update ecosystem and intro pages with final Go runtime status
- [ ] Align release version matrix with published tags
- [ ] Verify links and navigation integrity

## Evidence and Closure

- [ ] Update `ai-lib-plans` standup and MEMORY with release evidence links
- [ ] Attach package registry URLs and release tag URLs
- [ ] Mark `GO-003` task completed

