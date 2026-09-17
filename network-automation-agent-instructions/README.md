# Network Automation Agent Instructions

Personal AI engineering instructions for network automation work. The design deliberately separates always-on invariants from language/tool-specific rules and from manually invoked workflows and diagnostics.

These files are personal configuration. They are not intended to be committed into shared work repositories.

## Installed layout

Copy the files to:

```text
~/.claude/CLAUDE.md
~/.copilot/instructions/python.instructions.md
~/.copilot/instructions/ansible.instructions.md
~/.copilot/skills/network-change/SKILL.md
~/.copilot/skills/ai-status-check/SKILL.md
```

The copies stored in this repository are organized as:

```text
network-automation-agent-instructions/
├── README.md
├── RECREATE_PROMPT.md
├── core/
│   └── CLAUDE.md
└── copilot/
    ├── instructions/
    │   ├── python.instructions.md
    │   └── ansible.instructions.md
    └── skills/
        ├── ai-status-check/
        │   └── SKILL.md
        └── network-change/
            └── SKILL.md
```

## Why it is split this way

### `CLAUDE.md` — always-on engineering floor

Contains cross-domain engineering judgment and the user technical profile:

- safety and correctness hierarchy
- skill-level calibration
- assumption handling
- desired vs observed state
- execution vs state validation
- scope control
- source authority and uncertainty
- secret handling
- review classification

VS Code can load `~/.claude/CLAUDE.md` as personal always-on instructions when `chat.useClaudeMdFile` is enabled. Keeping this core tool-neutral also makes it reusable by Claude-compatible tooling.

### `python.instructions.md` — Python-specific behavior

Applies to Python work. It contains:

- type hints
- docstrings
- PEP 8 and naming
- comments and error handling
- logging
- project-aware tooling
- repository testing expectations
- proactive class-design review for user-written procedural code

The class-review rule is intentionally educational: when a plausible class boundary exists, the agent must explain why. It must also explain when procedural design is preferable. It does not deliberately generate inferior procedural code in order to recommend a class later.

### `ansible.instructions.md` — Ansible-specific behavior

Uses a broad YAML/Jinja glob because Ansible projects vary in layout, then explicitly stands down when matching YAML/Jinja content is not Ansible.

Important rules include:

- FQCNs are mandatory when they exist
- do not regress to legacy network `connection: local` + `provider:` patterns when current modules use connection plugins
- verify installed modules and versions with `ansible-doc`, `ansible-galaxy collection list`, and project dependency definitions instead of guessing
- do not infer idempotency only from Ansible's `changed` result
- understand resource-module state semantics before destructive use

### `/network-change` — manual high-impact workflow

The skill has:

```yaml
disable-model-invocation: true
```

Therefore Copilot does not auto-load it based on semantic matching. Invoke it explicitly with:

```text
/network-change
```

`user-invocable` is left at its default, so the skill remains available in the `/` menu.

The always-on core supplies the safety floor even when the skill is not invoked; the skill supplies the detailed high-impact change procedure.

### `/ai-status-check` — manual instruction sanity check

This is a read-only diagnostic skill. Invoke it explicitly with:

```text
/ai-status-check
```

It summarizes:

1. how the AI believes it should behave,
2. its current understanding of the user's technical skill level,
3. how it will handle Python coding and review,
4. how it will handle Ansible coding and review,
5. known manual skills and current verification limitations.

It also has:

```yaml
disable-model-invocation: true
```

so it does not consume context during normal work and cannot be auto-selected by the model. The status skill must distinguish instructions actually available in the current context from configuration that has not been independently verified through VS Code diagnostics.

## Configuration verification

Use VS Code Chat customization diagnostics to verify discovery and loading.

Test these cases:

1. A generic technical chat with no Python or Ansible file context should include `~/.claude/CLAUDE.md`.
2. Python work should include the core plus `python.instructions.md`.
3. Ansible work should include the core plus `ansible.instructions.md`.
4. `/network-change` should include the core, any applicable scoped instructions, and the network-change skill.
5. `/ai-status-check` should summarize the core/user profile and applicable Python/Ansible behavior without claiming unverified files were loaded.

Also test the behavior that originally motivated the stronger Ansible rule. In a fresh chat, request a Cisco IOS task and verify that generated YAML uses an FQCN such as:

```yaml
cisco.ios.ios_config:
```

rather than:

```yaml
ios_config:
```

For the broad Ansible glob, also verify that opening an unrelated YAML file such as a GitHub Actions workflow does not cause the Ansible-specific rules to influence the response.

## Maintenance

Treat these files as executable behavioral configuration rather than static documentation.

Change a rule when observed agent behavior demonstrates a need. Avoid expanding the always-on core merely because a useful rule exists; domain-specific and procedural rules should remain scoped so they do not compete for attention on unrelated tasks.

See [`RECREATE_PROMPT.md`](RECREATE_PROMPT.md) to reassess or rebuild this system with a future model.
