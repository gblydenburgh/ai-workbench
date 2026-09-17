---
name: 'Ansible Network Automation Standards'
description: 'Modern Ansible and network-automation rules: FQCNs, connection patterns, resource modules, idempotency, verification, and testing.'
applyTo: '**/*.yml,**/*.yaml,**/*.j2'
---
# Ansible network automation standards

## Applicability gate

These rules apply only when the current task or file is Ansible content: playbooks, roles, inventories, group/host vars, Ansible-oriented Jinja templates, Execution Environment configuration, or code being generated specifically for Ansible.

If a matching YAML or Jinja file is unrelated to Ansible — for example a GitHub Actions workflow, Docker Compose file, Kubernetes manifest, or unrelated application template — do not apply the Ansible-specific rules below.

Follow existing project conventions when they do not violate correctness or safety.

## Fully Qualified Collection Names are mandatory

Generate Fully Qualified Collection Names (FQCNs) for Ansible modules, plugins, filters, tests, and lookups whenever an FQCN exists.

Do not generate a short name merely because Ansible accepts it or because older examples use it.

Preferred:

```yaml
- name: Apply IOS configuration
  cisco.ios.ios_config:
    lines:
      - ip domain name example.net
```

Do not generate:

```yaml
- name: Apply IOS configuration
  ios_config:
    lines:
      - ip domain name example.net
```

Likewise prefer `ansible.builtin.copy`, `ansible.builtin.assert`, and `ansible.builtin.include_tasks` over their short forms.

## Do not regress to legacy network patterns

Do not generate obsolete 2.9-era network connection patterns when current modules use connection plugins such as `ansible.netcommon.network_cli`, `ansible.netcommon.httpapi`, or `ansible.netcommon.netconf`.

In particular, do not generate a legacy `connection: local` plus module `provider:` credential dictionary for modules whose current documentation expects a connection plugin.

Legacy pattern to avoid when current documentation uses connection plugins:

```yaml
- name: Legacy example — do not generate
  cisco.ios.ios_config:
    provider: "{{ cli }}"
    lines:
      - hostname R1
  connection: local
```

Do not ban a parameter named `provider` globally; some unrelated modules may legitimately define one. Verify the current module interface before deciding.

## Verify the installed environment instead of guessing

When a module, parameter, return value, supported state, or collection behavior is version-sensitive or uncertain, inspect the environment when available.

Use commands such as:

```bash
ansible-doc <fully.qualified.collection.module>
ansible-galaxy collection list
ansible-galaxy collection list <namespace.collection>
ansible --version
```

Also inspect the project's pinned dependencies, Execution Environment definition, requirements files, and collection metadata when relevant.

Do not invent modules or parameters. If the environment is unavailable, state the relevant version assumption and verify against official documentation or source for that version.

## Idempotency

State-changing Ansible automation must be idempotent when the underlying platform and operation permit it.

- A second execution with the same desired input must not introduce additional state changes or side effects.
- Do not determine idempotency solely from Ansible's `changed` value; verify resulting state when practical.
- Prefer a supported purpose-built or declarative module over `ansible.builtin.shell`, `ansible.builtin.command`, or raw CLI when it accurately represents the required state.
- If an operation is inherently non-idempotent, state that explicitly, add guards where practical, and prevent accidental repetition.

## Task and variable quality

- Every task must have a descriptive `name`.
- Prefer task names that describe intended outcome rather than the implementation mechanism.
- Use descriptive variables. Avoid ambiguous names such as `data`, `cfg`, or `x` when the domain meaning can be named.
- Use role defaults for values intended to be overridden; use role vars only when values should not normally be overridden.
- Use `group_vars` and `host_vars` for appropriately scoped inventory data.
- Prefer source-of-truth or inventory data over hardcoded infrastructure-specific values when an authoritative source exists.

## Validation

Validate externally supplied values when invalid data could affect correctness, scope, security, availability, or device configuration.

Use `ansible.builtin.assert` when explicit runtime validation is needed.

Do not duplicate validation already guaranteed by an authoritative upstream schema unless the data crosses a trust boundary, runtime enforcement cannot be guaranteed, or failure would be high-impact.

## Handlers and change-triggered actions

Use handlers when an action should occur only because a related task changed, such as restarting a service.

Do not restart services or perform equivalent follow-up actions unconditionally when a handler accurately models the requirement.

## Check mode

Support check mode when the module and target platform can accurately predict the change without applying it.

Do not claim check-mode support when required runtime state is unavailable, the module does not implement it correctly, or the platform cannot safely predict the result.

## Resource modules

Prefer network resource modules when they support the required feature and correctly model the desired state for the relevant platform and version.

Do not assume state semantics are identical between modules. Explicitly understand the behavior of states such as:

- `merged`
- `replaced`
- `overridden`
- `deleted`
- `gathered`
- `rendered`
- `parsed`

Before using destructive states such as `replaced`, `overridden`, or `deleted`, determine:

1. the configuration scope owned by the module
2. what existing configuration may be removed
3. whether observed implementation behavior matches documentation
4. whether behavior is version-dependent
5. how the resulting state will be verified

For implementation questions, inspect the relevant collection source and tests when documentation is insufficient or appears inconsistent with observed behavior.

## Secrets

Never hardcode real credentials, API tokens, SNMP secrets, vault passwords, or authentication material.

Use the project's credential mechanism, such as Ansible Vault, Automation Controller/AAP credentials, environment variables, or an enterprise secret manager.

Use `no_log: true` when task output could expose secrets, but do not apply it indiscriminately when it would unnecessarily eliminate useful diagnostics.

## Testing repository changes

For changes to repository implementation logic, test behavior rather than merely confirming that a playbook parses.

For parsing, rendering, reconciliation, or resource-module-related changes, consider tests for:

- parsing representative platform configuration
- rendered command/configuration output
- already-correct state
- required change
- idempotent second execution
- explicit disabling/removal where supported
- `replaced`, `overridden`, or `deleted` semantics when modified
- invalid or unexpected input
- failure behavior

Short educational fragments do not require a full committed test suite unless testing is the lesson. They still require modern syntax, FQCNs, meaningful names, and sound structure.

## Project tooling

Inspect the repository before choosing tooling.

- Run `ansible-lint` when it is part of the project environment or documented development workflow.
- Run `yamllint` when the project uses it.
- Run relevant tests, syntax checks, or collection sanity/unit tests when the repository defines them.
- Do not introduce new linting dependencies solely because they are mentioned here.
- Do not report validation as successful unless the command or test was actually run successfully.
