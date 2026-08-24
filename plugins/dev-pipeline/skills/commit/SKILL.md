---
name: commit
description: Commit and push changes using the team git flow — branch off dev as feature/{task_name}-short-description, commit as "[{task_name}] Short description", with user approval for branch name and commit message.
disable-model-invocation: false
---

# Commit flow

Commit and push the current working-tree changes following this exact flow. Use AskUserQuestion for the approval steps.

## 1. Inspect state

Run `git status`, `git branch --show-current`, and `git diff` (staged + unstaged) to understand what changed. If there are no changes at all, say so and stop.

## 2. Branch handling

**If the current branch is `dev`:**

1. Stash ALL changes including untracked files: `git stash -u`
2. Pull the fresh version: `git pull`
3. Ask the user for the task name (e.g. a ticket ID like `MS-123`). Do not guess it.
4. Derive a short kebab-case description from the diff and propose a branch name: `feature/{task_name}-short-description` (e.g. `feature/MS-123-fix-login-redirect`).
5. Ask the user to approve the branch name (offer the proposal plus 1–2 alternative descriptions). Do NOT create the branch until approved.
6. After approval: `git checkout -b <approved-branch-name>`
7. Unstash: `git stash pop`. If the pop conflicts, stop and report the conflicts to the user — do not resolve them silently.

**If already on a feature branch** (anything other than `dev`/`main`/`master`): show the user the current branch name and ask for approval to commit to it. If they approve, skip stashing and branching and go to step 3 — extract the task name from the branch name if it matches `feature/{task_name}-...`, otherwise ask for it. If they decline, ask how they want to proceed.

**If on `main`/`master`:** stop and ask the user how to proceed — do not commit there.

## 3. Commit

1. If a `fm:fix` script exists in the repo's `package.json` (check with `jq -e '.scripts["fm:fix"]' package.json`), run `npm run fm:fix` before committing so formatting fixes are included in the commit. If the script fails, stop and show the user the output.
2. Propose a commit message in exactly this format: `[{task_name}] Very short description` — one line, imperative, no body, no trailers.
3. Ask the user to approve the commit message (offer the proposal plus an alternative). Do NOT commit until approved.
4. After approval: stage everything (`git add -A`), commit with the approved message.

## 4. Push

Push the branch: `git push -u origin <branch-name>`. Report the final result: branch name, commit hash, and push status.

## 5. Background code review

After a successful push, launch a background code-review agent on the commit (do not block on it — report the push result immediately):

- Use the Agent tool with `run_in_background: true` and a prompt like:
  "Review commit <commit-hash> on branch <branch-name> in <repo-root>. Run `git show <commit-hash>` to get the diff, then review it for correctness bugs, security issues, and obvious quality problems. Read surrounding code where needed for context. Return a concise list of findings with file:line references and severity, or state that the commit looks good."
- Tell the user the review is running in the background; when the agent finishes, summarize its findings.

## Rules

- Never skip an approval step, even if the user seems in a hurry.
- Never force-push, amend, or rewrite history.
- If any git command fails (pull conflicts, push rejected), stop and show the user the output instead of improvising a fix.
- Never run background code review if it was fix after code review.
