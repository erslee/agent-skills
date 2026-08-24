---
name: dev-pipeline
description: Full engineering pipeline for a coding task — research, a solution proposal approved by the user, decomposition into subtasks approved task by task, implementation, test + verification with a fix-loop, commit and push via the commit skill, then an optional code review on request. Invoke for any non-trivial coding task (new feature, bug fix, refactor, migration) that changes code, in any git repo. Do not invoke for pure Q&A, explanations, or read-only exploration with no code changes intended.
disable-model-invocation: false
---

# Dev pipeline

Run this end-to-end pipeline for a coding task. You are the orchestrator AND the default implementer. Do the work inline in the main session unless a stage below states a concrete reason to delegate.

## When an agent is worth spawning

Every fresh agent starts cold: it re-derives context you already have (research findings, file locations, conventions), which costs a full round-trip and loses nuance at the handoff. Spawn one only when at least one of these holds:

1. **Parallelism** — two or more truly independent, file-disjoint subtasks that can run at the same time.
2. **Context isolation** — the work floods context with noisy output you don't need to keep: broad codebase sweeps, long test-suite logs, browser sessions.
3. **Fresh eyes** — code review, where NOT having the author's context is the benefit.

Rule of thumb: if writing the agent's prompt takes about as long as doing the subtask, do it yourself. When you want isolation but the work depends on conversation context, prefer `subagent_type: "fork"` — it inherits your full context, avoiding the cold start.

## 0. Scope check

Skip this whole skill if the request has no code to write or change: pure questions, explanations, reading/searching code to answer something, or a single trivial edit (rename a variable, fix a typo, tweak a string) that doesn't warrant research/tests/review overhead. Just do those directly.

Also stop and confirm with the user before starting if:
- there is no git repository here and none was offered to init, or
- the request is ambiguous enough that research/decomposition would be guessing at requirements.

## 1. Research

Answer narrow questions yourself with Grep/Glob/Read — a few targeted searches are faster than briefing an agent. Spawn `Explore` (or `researcher` for "how does X work end to end") only when the question is genuinely broad — sweeping many files or subsystems whose contents you don't need verbatim afterwards. Independent broad questions can go to parallel agents in one turn.

Skip this step outright if you already have enough context — don't research for its own sake. Synthesize findings yourself; don't forward raw agent output to later steps.

## 1.5 Propose the solution — wait for approval

Never go straight from research into decomposition. First describe the solution to the user and stop until they approve it. Do not create or edit any file before that approval.

Keep the proposal as simple as possible:

- plain words, no jargon dump, no code walls;
- an ASCII sketch of the flow or structure when it helps (data path, before → after, component tree);
- what will change, at a high level;
- one line on the main alternative you rejected and why.

Shape to aim for:

```
Goal: <one sentence, in the user's terms>

  <ascii sketch of the flow, marking the NEW / CHANGED parts>

Approach: <one or two sentences>
Rejected: <alternative> — <why not>
```

**How to ask:** if the task is simple and there's one sensible way to do it, ask in plain text. If you are unsure, or there are several viable approaches, use `AskUserQuestion` with the options laid out — one option per approach, with the trade-off in the description.

If the user asks for changes, revise the proposal and ask again. Move on only once they approve.

## 2. Decompose

Break the task into units and track them with `TaskCreate`. Do the decomposition yourself — you just did the research, so you know the real boundaries; a dispatcher agent would have to re-read the codebase to rediscover them.

A split into parallel subtasks is only valid when the pieces are file-disjoint (no shared files) and neither needs the other's output mid-flight. Dependent work is one unit — do it sequentially yourself rather than relaying context between agents, since each handoff loses information. Most tasks decompose into a sequence of steps for you, not a fan-out of agents.

## 2.5 Task plan review — wait for approval

Before writing any code, show the decomposition to the user and get it approved. Present the tasks **one at a time**, in order, and always offer to approve the rest in one go.

Each task is a small card, as simple as you can make it:

```
Task 1/4: <one plain sentence — what this task does>

  files:  src/lib/training/functions.ts   (edit)
          src/lib/training/topics.ts      (new)

  why:    <why these files and this approach, 1-2 sentences>
```

Then ask: approve this task / change it / **approve all remaining tasks**. Use plain text when the task is simple and unambiguous; use `AskUserQuestion` when you are unsure or the task could reasonably be done more than one way.

Rules:

- Every file the task will touch must be listed up front, marked `new` / `edit` / `delete`. "Some files under src/lib" is not a plan.
- If the user changes a task, re-show it before continuing; if the change affects later tasks, re-show those too.
- If implementation later turns out to need a file that wasn't in the approved list, stop and tell the user before touching it.

## 3. Implement

Default: implement inline yourself, subtask by subtask, marking tasks complete as you go. You have the research context, you see the diffs, and the user sees your progress. Stay inside the file list approved in step 2.5.

Spawn `principal-developer` workers only when step 2 produced two or more genuinely independent subtasks worth running in parallel — then spawn them concurrently in one turn, each with a self-contained prompt: what to build, the file paths it owns, acceptance criteria, and constraints from research. When workers return, reconcile any shared interfaces yourself (same signatures, same shapes) — don't assume agreement because both "finished".

Hold code you write inline to the same design standard as the `principal-developer` agent and the `code-reviewer`: **DRY** (one home per rule or literal — reuse before you add), **KISS** (simplest construct that solves it), **YAGNI** (nothing without a present caller), **SOLID** (one reason to change per unit, narrowest interface that works), **separation of concerns** (logic out of transport/UI, in testable units). Where a principle conflicts with the surrounding module's established pattern, follow the pattern and flag the tension — and don't trade KISS/YAGNI away to satisfy DRY.

Write or update tests as part of each subtask where the change has verifiable runtime behavior — matching the project's existing framework and conventions. If the project has no test framework, don't introduce one unasked; verify via typecheck/lint/build instead.

## 4. Test and verify

Run the narrowest check that covers the change, then the project's standard checks (typecheck, lint, tests if a suite exists). Run these inline; if a full suite is long and noisy, run it via a background Bash task instead of spawning an agent to watch it.

Spawn `test-writer` only when tests ARE the deliverable (backfilling coverage on code you didn't just write) — not as a routine stage after every implementation.

Ask the user before doing any real-browser verification (e.g. spawning `ui-tester` or invoking the `verify` skill) — don't launch it unprompted. If they decline or don't respond, skip and say so explicitly rather than silently proceeding.

## 5. Fix loop

If checks or verification fail, fix inline — you have the full implementation context, which is exactly what a freshly spawned fixer would lack. If a parallel worker from step 3 is still addressable and the failure is inside its boundary, resume it via `SendMessage`; never spawn a fresh agent just to fix.

After 3 failed fix cycles on the same failure, stop looping — summarize what's failing and ask the user how to proceed rather than continuing to churn.

Do not proceed to commit until checks pass (or the user has explicitly told you to proceed anyway).

## 6. Commit and push

Invoke the `commit` skill to branch/commit/push per the team git flow. Let that skill own its own approval steps (branch name, commit message) — don't shortcut them.

## 7. Code review (optional, on request)

After the commit is pushed, ask the user whether they want a code review of the change — don't run it unprompted.

If they say yes, spawn the `code-reviewer` agent on the diff. A fresh agent is the right tool here: it hasn't seen your reasoning, so it reads the code as a stranger would. (Do not invoke `/code-review` via the `Skill` tool — that command is user-triggered only and will fail if called programmatically.)

If it reports findings, use judgment: clear-cut bugs go through the fix loop and land as a follow-up commit (via the `commit` skill again); stylistic/uncertain findings can be surfaced to the user instead of auto-applied.

## Notes

- This pipeline is orchestration guidance, not a script — the stages are mandatory to consider, not mandatory to delegate. A typical 1–3 file change runs entirely inline with zero spawns; the code reviewer only appears if the user asks for it after commit.
- The two approval gates (1.5 and 2.5) are the exception: they are mandatory. No code is written before the solution and the task plan have been approved.
- Explanations at both gates are for a reader who hasn't seen the code. Prefer a small ASCII diagram over a paragraph, and a paragraph over a code dump.
- Keep the user informed at each stage transition with a one-line status update, not a full transcript of agent output.
