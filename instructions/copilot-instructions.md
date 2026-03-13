# GitHub Copilot Toolkit — Workspace Custom Instructions

> **Installation**: This file is installed to `.github/copilot-instructions.md` (workspace scope)
> or `~/.copilot/copilot-instructions.md` (personal/user scope) by the toolkit installer.
> Edit it to match your project's conventions.

---

## General Behaviour

- Be concise in explanations. Prefer showing code over describing it.
- When you are uncertain about scope or requirements, ask one focused clarifying question before proceeding.
- Prefer making surgical, minimal changes. Don't refactor unrelated code while fixing a bug.
- Always validate that your changes don't break existing behaviour (run tests, linter, build).

## Development Workflow

- Follow **Test-Driven Development**: write tests first, run them to failure, then write the minimum code to pass.
- Before reading a large number of files yourself, consider delegating to a subagent (Oracle, Explorer) to preserve context.
- For complex multi-phase tasks, write a plan to `plans/` before starting implementation.
- After completing a feature or fix, run the full test suite to check for regressions.

## Code Style

- Match the style, naming conventions, and idioms already present in the codebase.
- Prefer explicit over implicit. Name variables and functions clearly.
- Only add comments to code that needs clarification; don't comment self-evident code.
- Use the project's existing linter/formatter (don't introduce new tooling unless asked).

## Git & Commits

- Write clear, imperative-mood commit messages: `Add login endpoint` not `Added login endpoint`.
- Keep commits focused — one logical change per commit.
- Always include a `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer in commits.
- Don't commit secrets, credentials, or `.env` files.

## Agent Orchestration (when using Atlas / Prometheus)

- Use Atlas for full development lifecycle tasks (plan → implement → review → commit).
- Use Prometheus when you need a comprehensive plan before implementation begins.
- Delegate heavy file-reading research to Oracle or Explorer subagents to preserve the conductor's context window.
- Run independent implementation tasks in parallel via multiple Sisyphus invocations.

## MCP Tools

- When MCP tools are available (see agent files for the list), prefer them over manual steps.
- Use MCP tools conservatively — confirm before creating PRs, merging branches, or sending messages.

## Project-Specific Notes

<!-- Add your project-specific conventions below this line -->
