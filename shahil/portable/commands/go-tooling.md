---
description: Go monorepo + tooling gotchas — build tag semantics, generated-stub pinning (gRPC, protoc), SDK major-version breaks, debug-output hygiene. Apply when working in Go modules with codegen, multi-module monorepos, or third-party SDK upgrades.
---

# /go-tooling — Go Monorepo & Tooling Rules

> Skill created 2026-06-01 from 4 orphaned Go-tooling learnings clustered out of the
> {{PROJECT}} context-engine build session. Per `/learned` constraint #10 (3+ orphans
> in one theme = missing skill), force-fitting them into adjacent skills (`scaffold`,
> `architect`) would dilute both — this skill is the right home.

## When to use

Triggers on any of these signals:
- You're about to add or upgrade a third-party Go SDK (openai-go, anthropic-sdk-go, AWS, GCP, OpenAI).
- You ran `make proto` / `protoc` and the build broke on the generated stubs.
- `go mod tidy` is complaining about a package that doesn't exist yet (because it's
  generated, or it's a planned future module).
- You're writing a Go CLI or test harness that uses GORM and stdout is unreadable.
- You're working in a multi-module Go monorepo (sibling services under one root).

## Learned Rules

1. **`go mod tidy` parses every `.go` file regardless of build tags — to stage a file with imports that don't resolve yet, rename off the `.go` extension.** Tried `//go:build proto` to gate `cmd/server/main.go` while waiting on generated proto stubs. Tidy still failed with `module github.com/.../proto/contextengine: git ls-remote ... remote: Repository not found`. Build tags affect which files COMPILE per build invocation; they do NOT affect which files participate in the module graph. Fix: rename `main.go` to `main.go.tmpl` (or `.disabled`) until the dep lands. Same pattern applies for wire/mockgen/protoc workflows where generated files don't exist at clone time. Document the rename in a sibling README so future readers know to rename back after `make proto`. *(From: feedback_learned_go_mod_tidy_ignores_build_tags.md)*

2. **After regenerating gRPC stubs, check the `grpc.SupportPackageIsVersionN` line at the top of every `*_grpc.pb.go` — bump `google.golang.org/grpc` to match.** Latest `protoc-gen-go-grpc` (v1.6.2) emitted `grpc.SupportPackageIsVersion9`, but `grpc-go v1.62.1` (transitively pulled by `gorm.io/driver/mysql`) only goes up to v8. Build failed with `undefined: grpc.SupportPackageIsVersion9`. Fix: `go get google.golang.org/grpc@latest` (bumped to v1.81.1). Triggers any time you (a) `go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest`, OR (b) regenerate stubs in a project dormant >3 months. After regeneration, `grep SupportPackageIsVersion proto/**/*_grpc.pb.go` to find the required version, then verify `go.mod`. Document the pair (protoc-gen-go-grpc + grpc-go) versions together in the project's tooling docs. *(From: feedback_learned_grpc_pin_runtime_to_generator.md)*

3. **`openai-go` v0.x → v1.x is a breaking API rewrite — pin explicitly to peer-service versions; never let `go mod tidy` auto-resolve.** v0 uses `openai.F[T](value)` parameter wrappers; v1 dropped them entirely and changed `NewClient` to return a value instead of a pointer. When wrote a new service mirroring account-api's `openai_service.go` (pinned `v0.1.0-alpha.41`), `go mod tidy` auto-resolved to v1.12.0; 7+ lines failed with `undefined: openai.F` and `cannot use openai.NewClient(...) (value of struct type openai.Client) as *openai.Client value in struct literal`. Fix: `go get github.com/openai/openai-go@v0.1.0-alpha.41`. Before adding `openai-go` (or any SDK with a v0→v1 rewrite — anthropic-sdk-go, pinecone-go, langchaingo) to a new service, run `grep -r "openai-go" --include=go.mod .` across the repo first; use whatever version peer services pin. For greenfield with no peer, prefer the current stable line and document the pin. *(From: feedback_learned_openai_go_v0_v1_break.md)*

4. **Default GORM `Logger` to `logger.Silent` in CLIs and test harnesses — Warn level floods stdout with full SQL on every slow query.** When debugging a duplicate-key error in `cmd/ingest-cli`, stdout returned 50KB+ of ANSI-colored SQL because GORM's Warn level prints the FULL batch INSERT for any query slower than 200ms. The actual error message was buried under megabytes of `INSERT INTO ... VALUES (...)`. `head -100` and `tail -50` both missed it. Lost ~10 minutes. Fix: `Logger: logger.Default.LogMode(logger.Silent)` in `&gorm.Config{}`. Bump to `logger.Warn` only when actively hunting a query-shape bug (missing index, wrong join). For row-data bugs (PK collision, type mismatch, NULL handling) SQL noise is pure distraction. *(From: feedback_learned_gorm_logger_silent_default.md)*
