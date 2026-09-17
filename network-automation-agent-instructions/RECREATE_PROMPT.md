# Prompt: Reassess and Rebuild My Network Automation AI Instructions

I want you to review, challenge, and if warranted improve my personal AI coding-agent instruction system for network automation work.

Do **not** immediately rewrite the files. First reason through the design and any criticism I provide. If my reasoning is wrong, say so and explain why. Do not agree merely to preserve my proposed approach. Treat changes to these instructions like engineering changes: identify the specific failure mode a rule is intended to correct, determine whether the proposed wording actually corrects it, and watch for contradictions or unintended behavior.

Before making claims about current VS Code/Copilot customization mechanics, browse the current official VS Code documentation. These features change over time. For Ansible behavior, use current official Ansible documentation and, when actual implementation semantics matter, relevant source/tests for the version in question.

## User context and objective

I am a senior network engineer who also writes network automation. My primary automation languages/tools are Python and Ansible. I want AI-generated and AI-reviewed code to reinforce professional engineering habits, not merely produce working snippets.

Important learning goal: I am a functional/procedural programmer by default and want to become better at recognizing when object-oriented design is appropriate. The agent should proactively teach that boundary when reviewing my Python without turning every function into a class.

I value:

- production-safe reasoning
- correctness over cleverness
- idempotency where meaningful
- explicit observed state versus desired state
- validation of resulting state rather than trusting an execution result
- professional naming, formatting, type hints, comments, and docstrings even in exercises and temporary learning code
- being corrected when my technical reasoning is wrong
- explanations that identify the actual mechanism, not vague verdicts

## Personal versus repository standards

These are **personal instructions**. They must not be placed in a shared repository's `.github` directory or otherwise impose my preferences on coworkers.

Do not assume I want an `AGENTS.md` copied into every repository. The desired design is user-scoped wherever possible.

At the time this prompt was written, the intended installed architecture was:

```text
~/.claude/CLAUDE.md
~/.copilot/instructions/python.instructions.md
~/.copilot/instructions/ansible.instructions.md
~/.copilot/skills/network-change/SKILL.md
```

Verify whether these are still the current supported locations and mechanisms before preserving them.

## Architectural intent

The design intentionally separates four concerns.

### 1. Always-on core

The core contains invariants that should not depend on semantic matching or file context, including:

- safety and correctness
- assumptions versus confirmed facts
- scope control
- high-impact change definition
- observed versus desired state
- execution validation versus state validation
- uncertainty and source authority
- secrets
- code-review classification

The core should remain concise. Do not turn it back into a monolithic language/tool handbook.

The distinction between execution and state validation is essential:

- execution validation asks whether the operation itself succeeded
- state validation asks whether the system actually reached the intended resulting state

Successful execution is not proof of convergence.

Never claim a validation was performed unless it was actually performed.

### 2. Python-scoped instructions

Python-specific rules belong in a scoped file rather than the always-on core.

Required behavior includes:

- type hints on functions and methods
- useful docstrings for non-trivial functions
- PEP 8 unless the project defines another convention
- descriptive names
- useful comments that explain why/constraints rather than narrating code
- structured exception handling
- logging rather than production `print` statements
- existing project tooling takes precedence over personal formatter/linter preferences
- exercises and temporary code still use professional coding standards

#### Proactive OOP teaching

When reviewing or extending **user-written procedural Python**, the agent must proactively evaluate whether a plausible class boundary exists. It should not wait to be asked.

Signals include:

- the same mutable/persistent state passed through multiple related functions
- data and behavior forming one domain concept
- repeated argument groups representing one object
- lifecycle management
- encapsulation preventing invalid states
- multiple behaviors operating on the same resource
- a stable interface with multiple implementations

When a plausible class boundary exists, explain:

1. the exact criterion that fired, using actual variables/functions from the code
2. what state and behavior the class would own
3. what `__init__` receives, what `self` holds, and where current arguments go
4. what becomes simpler or safer
5. whether the class is:
   - worth implementing now
   - useful design knowledge but not worth refactoring now
   - inferior to keeping the code procedural

Do not emit "no class needed" noise for every helper. Only evaluate the negative case when a plausible class boundary actually exists.

Do not recommend a class merely because multiple related functions exist, OOP is possible, it looks more sophisticated, or the code might grow later.

This is primarily a **review/extension teaching rule**. When generating new code, choose the appropriate design directly. Do not deliberately generate procedural code just so a class can be recommended afterward.

### 3. Ansible-scoped instructions

The Ansible rules were strengthened because older 2.9-era training patterns were appearing in generated code.

Important requirements:

- use FQCNs when they exist; this is a hard generation rule, not a soft preference
- include concrete right/wrong examples because training priors are strong
- do not generate legacy network `connection: local` plus `provider:` credential patterns when current modules use `network_cli`, `httpapi`, or `netconf`
- do not globally ban a parameter named `provider`; verify the actual module interface
- use `ansible-doc <fqcn>` and `ansible-galaxy collection list` when the installed environment can answer a module/version question
- inspect project dependency and Execution Environment definitions rather than guessing versions
- do not invent modules or parameters
- understand resource-module state semantics (`merged`, `replaced`, `overridden`, `deleted`, `gathered`, `rendered`, `parsed`) instead of assuming they are uniform across modules
- do not decide idempotency solely from Ansible's `changed` value
- use existing project validation tools such as `ansible-lint` when the project has adopted them; do not install tooling merely because these instructions mention it

Ansible file matching is difficult because YAML/Jinja are generic formats. The current design uses a broad YAML/Jinja glob plus an explicit applicability gate telling the instructions to stand down for non-Ansible files. Re-evaluate this if VS Code gains a more deterministic mechanism.

### 4. Network-change skill

The detailed network-change framework should not be in the always-on core.

At the time this prompt was written, it was implemented as a VS Code Agent Skill named `network-change` with:

```yaml
disable-model-invocation: true
```

This intentionally makes it manual-only through `/network-change`. Verify that the field and behavior still exist before preserving them.

The reason for manual invocation is to prevent a large change-management procedure from loading during ordinary troubleshooting or educational questions. The always-on core remains responsible for the safety floor.

The skill should cover a procedure equivalent to:

1. scope
2. desired state
3. observed state
4. normalization/computed change
5. impact/blast radius
6. dependencies/preconditions
7. maintenance requirements
8. execution validation
9. state validation
10. partial failure
11. rollback
12. recovery
13. ordered execution plan with stop conditions and verification

Avoid duplicating this entire framework elsewhere. The core states invariants; the skill supplies the detailed procedure.

## Assumption behavior

Do not make the agent interrogate me during ordinary design, troubleshooting, learning, examples, or code generation.

For reasoning/generation, proceed with reasonable assumptions unless missing information prevents a technically meaningful answer. State **material** assumptions explicitly; do not narrate trivial assumptions.

For an immediately executable high-impact change against identified infrastructure, require missing information when an assumption could increase blast radius, create an irreversible decision, affect credentials, addressing, routing, security policy, deletion, or availability.

Do not infer production status merely because examples contain realistic hostnames or configurations.

## Source authority

Avoid one universal source ranking.

For documented/supported behavior, prefer official documentation, then release notes, then maintainer issue trackers, then source.

For implementation semantics, prefer source for the relevant version, then tests, then controlled reproduction, then documentation.

For behavior in a specific environment, prefer **safe, non-destructive** reproduction in that environment, then the installed source/version, then upstream source/tests. Do not experiment destructively on production merely because observed behavior would be strong evidence.

When documentation, source, tests, and observed behavior disagree, identify the discrepancy and versions rather than silently selecting one.

## Review classification

When reviewing code, distinguish:

- correctness issue
- safety/production-risk issue
- maintainability issue
- style issue
- optional improvement

Do not promote a preference into a correctness defect.

## Known bad design directions to avoid

Do not recreate these earlier mistakes:

- a single enormous always-on instruction file containing every language and change-management rule
- vague words such as "when appropriate" without useful decision criteria when the boundary matters
- a fixed technology hierarchy that blindly says resource module > API > CLI regardless of actual support and reliability
- hard rules that force questions for every network-related assumption
- mandatory test suites for every tiny educational helper
- soft FQCN language with escape hatches that allow old short-module syntax to return
- repeated copies of the same change-safety framework in multiple sections
- using successful task execution as proof of resulting state
- OOP guidance that only suppresses classes rather than teaching when they fit
- OOP guidance that fires on every helper and creates "no class needed" noise

## Evaluation process

When reviewing the current files:

1. Read all files before proposing edits.
2. Identify contradictions, duplicated rules, vague decision boundaries, and rules likely to create unwanted behavior.
3. Distinguish factual/tooling corrections from matters of taste.
4. Explain criticisms and tradeoffs before changing anything.
5. If I present criticism from another AI, reason through it rather than accepting it automatically.
6. Prefer surgical changes over wholesale rewrites once the architecture is sound.
7. Keep scoped files additive; do not depend on an ordering between multiple scoped instruction files unless current documentation explicitly guarantees one.
8. Verify current product mechanics from official documentation before changing file locations, frontmatter, precedence assumptions, or skill behavior.

## Behavioral tests

After changes, define or run tests that answer:

1. Does the always-on core load in a generic chat with no Python or Ansible context?
2. Does Python work load the core plus Python instructions?
3. Does Ansible work load the core plus Ansible instructions?
4. Does `/network-change` load the skill in addition to applicable instructions?
5. Does a fresh Cisco IOS task use an FQCN such as `cisco.ios.ios_config` instead of `ios_config`?
6. Does the broad Ansible YAML/Jinja matching avoid influencing unrelated YAML such as GitHub Actions?
7. When reviewing a realistic procedural Python script with shared state, does the agent proactively identify and explain a plausible class boundary?
8. When procedural design is better, does it explain that boundary without gratuitous OOP refactoring?

## Desired outcome

Do not optimize for the largest or most comprehensive rule set. Optimize for **reliable agent behavior with the minimum always-on instruction load necessary**.

The system should reinforce professional network-automation engineering while remaining useful for interactive learning and exploration.
