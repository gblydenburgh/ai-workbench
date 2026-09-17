---
name: network-change
description: 'Plan or review a consequential infrastructure or network change using explicit observed/desired state, impact, validation, rollback, and recovery analysis.'
disable-model-invocation: true
---
# Network change

Use this procedure for a consequential state-changing network or infrastructure task. This skill is intentionally manual-only; it should run when explicitly invoked as `/network-change`.

Do not substitute ceremony for engineering judgment. Keep the analysis proportional to the actual risk, but do not omit a step that materially affects safety or correctness.

## 1. Establish scope

State exactly which systems, devices, sites, tenants, services, configuration domains, or objects are in scope and what is explicitly out of scope.

## 2. Establish desired state

Describe the intended post-change state in concrete, verifiable terms.

## 3. Establish observed state

Retrieve or identify the current state from the target systems or authoritative source. Distinguish retrieved state from assumptions and desired configuration.

If current state is not available and the missing information affects safe execution, stop the executable plan at that boundary and identify what must be collected.

## 4. Normalize and compute the change

When observed and desired data use different representations, normalize them before comparison.

Identify the exact computed change rather than treating the desired configuration as a complete replacement unless replacement is explicitly intended.

## 5. Assess impact and blast radius

Identify what could be affected if the change behaves as intended, fails completely, or partially succeeds.

Consider where relevant:

- traffic forwarding
- routing convergence
- switching behavior
- security policy
- management-plane access
- authentication/authorization
- HA, clustering, and failover
- dependent services
- multiple devices, sites, tenants, or customers

## 6. Identify dependencies and preconditions

Identify prerequisites such as feature state, software version, collection/module behavior, API availability, credentials, source-of-truth correctness, peer configuration, maintenance dependencies, and out-of-band access.

## 7. Determine maintenance requirements

State whether a maintenance window, traffic drain, failover, change freeze exception, console/OOB availability, or coordination with another team is required and why.

## 8. Define execution validation

Define how to determine whether the requested operation itself completed successfully.

Examples include API status and response validation, Ansible task/module result, commit status, command return state, transaction result, or explicit error handling.

Execution success alone is not state convergence.

## 9. Define state validation

Define how to prove the resulting system state matches the desired state.

Use reliable observation where available, such as:

- re-gathered structured configuration
- running configuration
- API query
- routing table
- neighbor or adjacency state
- interface state
- cluster/HA state
- service or application health

State the specific success criteria rather than saying only "verify connectivity."

## 10. Plan for partial failure

Describe what happens if only part of the operation succeeds. Identify states that would be unsafe, inconsistent, or difficult to distinguish from success.

For multi-device changes, consider ordering and whether later steps must stop after an earlier failure.

## 11. Define rollback

Describe how to return to the known pre-change state. Identify what must be captured before execution to make rollback possible.

Do not call a recovery action a rollback when it does not restore the prior state.

## 12. Define recovery

Describe how acceptable service will be restored if exact rollback is unavailable, unsafe, or fails.

Include console/OOB or manual intervention requirements when relevant.

## 13. Produce the execution plan

Present the final plan in execution order with:

- prerequisites
- exact change scope
- execution steps
- stop conditions
- execution validation
- state validation
- rollback trigger and steps
- recovery path

Do not claim a check, validation, test, or observation was performed unless it was actually performed.
