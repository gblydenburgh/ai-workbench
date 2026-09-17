---
name: ai-status-check
description: Summarize the AI's current engineering behavior, its understanding of the user's technical skill level, and how it will handle Python and Ansible work. Use only when explicitly invoked for a configuration/status sanity check.
disable-model-invocation: true
---

# AI status check

Provide a concise status report of the engineering instructions currently governing this conversation.

This is a read-only diagnostic/status skill. Do not modify files, code, configuration, or instructions unless the user separately asks for a change.

## Evidence rule

Report only what is actually available in the current context.

- Do not claim that a particular instruction file was loaded unless its presence can be identified from the current context or tooling.
- Distinguish **configured/expected behavior** from **behavior or file loading that has been independently verified**.
- If VS Code diagnostics have not been inspected, say that instruction discovery has not been independently verified in this chat.
- Do not invent missing user skills, project conventions, versions, or active instruction sources.

## Required report

Use these sections.

### 1. How I will behave

Summarize the important engineering behavior currently expected of the AI, including as applicable:

- safety and correctness over convenience,
- material assumptions stated rather than presented as facts,
- no fabricated infrastructure state, APIs, modules, parameters, CLI syntax, or supported versions,
- execution success distinguished from resulting-state convergence,
- preservation of unrelated behavior and narrow scope,
- direct correction when the user's technical reasoning is wrong,
- professional coding standards even for exercises or temporary code,
- uncertainty and verification behavior.

Do not merely quote the instruction files. Explain the practical behavior in plain language.

### 2. My current understanding of your skill level

Summarize the technical profile available in the current context. Preserve distinctions between operational experience and implementation-level knowledge.

At minimum, when supported by the loaded profile, address:

- network engineering/domain knowledge,
- Ansible operational skill,
- desired-state/reconciliation reasoning,
- procedural Python,
- Python debugging,
- typing/data modeling,
- software design/modularity,
- testing,
- OOP/classes/inheritance,
- Ansible ResourceModule internals and related framework components.

Do not inflate skill ratings beyond demonstrated evidence. Do not reduce strong networking or operational Ansible experience merely because software-development topics are still being learned.

### 3. How I will handle Python

Summarize the Python-specific behavior available in the current context, including as applicable:

- type hints,
- naming and PEP 8/project conventions,
- useful docstrings and comments,
- exception handling and logging,
- project-adopted linting/testing tools,
- professional form for learning code,
- proactive review of meaningful class boundaries in user-written procedural code,
- explicit explanation when a class is warranted, merely worth knowing about, or inferior to a procedural design.

State clearly that OOP suggestions should teach design judgment rather than force classes into every script.

### 4. How I will handle Ansible

Summarize the Ansible-specific behavior available in the current context, including as applicable:

- FQCN generation,
- avoidance of obsolete network automation patterns unless an old verified target requires them,
- verification with the installed environment when module/version behavior matters,
- resource-module state semantics and ownership,
- idempotency based on resulting state rather than `changed` alone,
- task naming, variable handling, handlers, check-mode awareness, secrets, and project validation tooling.

When relevant, mention that `ansible-doc <fqcn>` and `ansible-galaxy collection list` are preferred environment checks rather than guessing.

### 5. Manual skills and current limitations

State which manual skills are known from the current context and whether they are active.

In particular:

- `/network-change` is intended to be manually invoked for the detailed high-impact network-change procedure.
- `/ai-status-check` is this read-only status report.

Do not imply `/network-change` is active merely because it exists.

End with a short **Confidence / verification** statement that says whether this report is based only on instructions present in context or whether VS Code diagnostics/tooling also verified file discovery.