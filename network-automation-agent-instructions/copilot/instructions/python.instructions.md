---
name: 'Python Engineering Standards'
description: 'Python coding, review, testing, and class-design guidance for infrastructure and network automation.'
applyTo: '**/*.py'
---
# Python engineering standards

Follow existing project conventions when they do not violate correctness or safety. Use Python 3.12+ defaults when the project does not establish another supported version.

## Code quality

- Use type hints on every function and method you write, including return types.
- Prefer precise types over `Any`. Use `Any` only when the interface genuinely cannot be narrowed without misrepresenting the data.
- Follow PEP 8 unless the project defines a documented alternative.
- Use descriptive names. Prefer `management_address`, `desired_snmp_users`, and `configured_vlans` over ambiguous names such as `data`, `tmp`, or `x` outside trivial mathematical/indexing scopes.
- Prefer `pathlib.Path` over `os.path` for path handling unless project constraints require otherwise.
- Prefer small functions with one clear responsibility and explicit return values.
- Use context managers for resources with a lifecycle.
- Prefer the standard library when it solves the problem clearly and adequately.

Professional coding standards still apply to examples, exercises, temporary files, and learning code. Do not use their temporary nature as a reason to omit useful type hints, naming, formatting, function structure, comments, or docstrings.

## Docstrings

Every non-trivial function and method must have a useful docstring.

A trivial private helper may omit a docstring only when its name, type signature, implementation, and side effects are all obvious.

Document, where applicable:

- purpose and important behavior
- arguments
- return value
- constraints
- exceptions intentionally exposed to callers
- non-obvious side effects

Do not write docstrings that merely restate the function name.

## Comments

Add comments when they explain:

- why an implementation exists
- a platform quirk or compatibility constraint
- an assumption or workaround
- behavior that would otherwise surprise a maintainer

Do not add comments that simply translate code into English. Keep comments synchronized with the implementation; an incorrect comment is a defect.

## Error handling and logging

- Catch exceptions only when the current layer can recover, add useful context, translate to a meaningful domain error, perform required cleanup, or intentionally select an alternate path.
- Catch specific exception types when practical.
- Do not use `except Exception: pass` or otherwise suppress failures that matter to the requested outcome.
- Preserve the original exception with `raise ... from exc` when wrapping adds context.
- Use `logging`, not `print`, for operational messages in production code.
- Never log real credentials, tokens, private keys, authentication headers, SNMP secrets, or other sensitive values.

## Class-design review

When reviewing or extending user-written procedural Python, proactively evaluate whether the code contains a plausible class boundary. Do not wait for the user to ask about object-oriented design.

A plausible class boundary exists when one or more of these criteria are present:

- the same mutable or persistent state is passed among several related functions
- data and behavior represent one domain concept
- the same group of arguments is repeatedly passed together as one logical object
- resource lifecycle must be managed
- encapsulation could prevent invalid state
- multiple behaviors operate on the same underlying resource
- multiple implementations need a stable common interface
- stateful behavior is awkward or error-prone when represented as independent functions

If a plausible boundary exists, explicitly evaluate it. Do not generate "no class needed" commentary for isolated helpers where no meaningful class boundary exists.

For each class opportunity, explain:

1. **Criterion** — identify the specific evidence in the actual code, naming variables, functions, and state flow rather than saying only that the code is "stateful."
2. **Ownership** — identify what data the class would own and which behaviors would become methods.
3. **Mechanism** — explain what `__init__` would receive, what `self` would hold, and which repeated function arguments would become instance state.
4. **Benefit** — state concretely what becomes simpler, safer, clearer, easier to test, or easier to extend.
5. **Recommendation** — classify the result as one of:
   - worth implementing now
   - useful design knowledge but not worth refactoring now
   - procedural design preferred

When a plausible class boundary exists but procedural design remains preferable, explain which criterion makes the procedural design the better choice.

Do not recommend a class solely because:

- several related functions exist
- object-oriented design is possible
- a class looks more sophisticated
- the code might grow later

A class suggestion is normally a maintainability issue or optional improvement, not a correctness issue. Treat it as a correctness issue only when the current design actually permits incorrect state or behavior.

This proactive teaching requirement applies primarily when reviewing or extending user-written code. When generating new code, choose the appropriate design directly; do not deliberately generate an inferior procedural design merely to recommend a class afterward. Explain a non-obvious class choice when it materially helps understanding.

## Testing

For repository implementation code, add or update tests when behavior changes. At minimum, cover the behaviors materially affected by the change, including failure behavior where it matters.

For reconciliation, parsing, rendering, or configuration-generation logic in repository code, explicitly consider:

- already-correct state
- required change
- converged second execution/idempotency
- invalid or unexpected input

Add deletion, replacement, override, partial-state, API-failure, or integration tests when those behaviors are part of the implementation.

Do not require a committed test suite for every short educational exercise, scratch fragment, or isolated helper. Professional structure and type/documentation standards still apply to those examples.

## Project tooling

Before choosing or invoking formatters, linters, type checkers, or test runners, inspect the project's existing configuration such as `pyproject.toml`, `ruff.toml`, `setup.cfg`, `tox.ini`, or project documentation.

- Use the tooling already adopted by the project.
- Do not introduce Ruff, Black, Flake8, mypy, pytest, or another tool solely because it is preferred here.
- When Ruff is already configured, run the applicable checks after edits, such as `ruff check` and `ruff format --check`.
- Run the project's relevant tests and static checks before reporting repository changes complete when the environment permits it.
- Do not claim a tool or test passed unless it was actually run successfully.
