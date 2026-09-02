# Context Discipline

Standing policy for how agents manage the context window and the payloads they send. Always loaded (see `instructions` in the OpenCode config).

These are cost rules, not style preferences. Both sections below describe ways of spending money repeatedly for something you should pay for once.

## Cache-prefix discipline

Provider prompt caches match on an **exact byte prefix**. Everything from the first changed byte onward is a cache miss, re-charged at full input price — and it stays missed for every subsequent turn in that session.

The practical consequence: editing something near the *start* of a conversation is far more expensive than appending the same number of bytes at the end.

**Rules:**

1. **Volatile content goes at the tail.** Status, progress, working state, and scratch notes are appended at the end of the payload. When they need updating, strip the stale copy and re-append at the tail — never edit it in place in an earlier turn.
2. **Stable content stays at the front, and stays byte-identical.** Instructions, rules, reference material, and skill bodies must not have timestamps, run IDs, session IDs, counters, or "current as of" lines interpolated into them. One interpolated timestamp at the top of an always-loaded file invalidates the cache prefix on every single turn, in every session, forever.
3. **Do not rewrite history to tidy it.** Re-flowing an earlier message to be neater costs the entire cache from that point onward. Leave it.

## Bounded state

Any file that is re-read into context on every iteration is paid for on every iteration. An unbounded working-state file is therefore not a tidiness problem — it is a bill that grows without limit.

**Caps** for agent-maintained state files (for example a `state.md`, a running plan, or an evidence/decision log):

| Thing | Cap | When exceeded |
|---|---|---|
| State / working file | 120 lines | Compress oldest entries into a one-line summary |
| Evidence or decision log | 40 entries | Evict oldest-first |

A state file is a **rolling summary, not a log**. If it only ever grows, it is the wrong shape.

Durable conclusions that must survive eviction belong in a real file on disk (`docs/`, an ADR, a checkpoint note) — not in the rolling state. Write it down properly, then let the state file forget it.

## Keep bulk content out of the main context

The most expensive thing an agent does is read a large amount of content in order to answer a small question about it.

- **Derive, don't read.** When you want to *know something about* content (a count, a match, a diff, a summary) rather than *see* it, run code over it and return only the answer. This repo's harness ships `context-mode`, whose `ctx_execute_file` and `ctx_batch_execute` tools exist precisely for this: the bytes stay in the sandbox and only what you print enters context.
- **Reading-then-summarising in a subagent only moves the problem.** A subagent that reads 400 KB into its own context and returns a paragraph still paid for 400 KB. Prefer deriving in a sandbox over delegating a raw read.
- **Exception: editing.** An edit has to match the file byte-for-byte, so read the real file when you intend to change it. This is the one case where a plain read is correct.
- **Hand over paths, not contents.** When passing work to a subagent or another lane, send the question, the paths, and the acceptance criteria. A subagent's cost is its own prompt *plus whatever you sent it* — pasting prior findings or a transcript into the payload converts a cheap call into an expensive one.

## Why this is a rule and not a suggestion

Every item above has the same failure mode: it costs nothing visible today and compounds silently. Nobody notices a cache-busting timestamp or a 900-line state file at the moment it is introduced — it shows up later as a session that costs several times what an equivalent one did last month, with no single change to point at.

---

*The cache-prefix and bounded-state patterns here were adapted from the MIT-licensed [`oh-my-opencode-slim`](https://github.com/) plugin's approach, by way of the Delta delivery-loop harness. Adopted as written policy, deliberately not as a dependency.*
