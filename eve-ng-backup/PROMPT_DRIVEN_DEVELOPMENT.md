# Prompt-Driven Development Handoff

Use the following prompt when asking an AI coding assistant to continue development of this EVE-NG backup utility.

---

## Prompt

You are maintaining the `eve-ng-backup` project in the `gblydenburgh/ai-workbench` repository.

The project is a Bash backup utility for a bare-metal EVE-NG server. Before proposing or making changes, read the current `backup.sh` and `README.md`. Treat the current implementation as the source of truth unless a requirement below explicitly says otherwise.

### Development approach

Work incrementally. Do not rewrite the script from scratch unless explicitly requested. Preserve existing behavior that is not part of the requested change. If a requested change is ambiguous and could affect backup integrity, deletion behavior, authentication, destination layout, EVE node availability, or restore semantics, ask one focused question before changing it.

When reviewing changes, distinguish between:

- required EVE-NG backup behavior,
- Synology/rsync transport behavior,
- additional recovery conveniences added by this project.

Call out incorrect assumptions directly. Do not claim a backup is recoverable merely because rsync exited successfully; validation and restore semantics matter.

### Current environment

The current defaults are:

```text
EVE-NG:                bare metal
NAS:                   Synology
NAS IP:                192.168.1.6
rsync account:          eve-ng
rsync module:           home
backup root:            EVE-Backups
password file:          /home/eve-ng/.synology-rsync-password
third-party image dir:  /home/eve-ng/third_party_images
```

The connection uses Synology **rsync daemon mode** over TCP/873:

```text
eve-ng@192.168.1.6::home
```

Do not convert this to SSH or rsync-over-SSH unless explicitly requested. The normal Synology user is intentionally not being placed in the administrators group merely to gain an interactive SSH shell.

The rsync account has been tested and can authenticate and create files/directories. It cannot perform `chgrp`, so backup rsync operations must not require owner/group preservation. The current script uses:

```text
--no-owner
--no-group
```

Do not remove those options without a tested reason.

### EVE-NG backup sources

The core backup set comes from EVE-NG's documented manual backup paths:

```text
/opt/unetlab/addons/
/opt/unetlab/tmp/
/opt/unetlab/labs/
/opt/unetlab/evedb.gz
```

The script also includes EVE customizations when present:

```text
/opt/unetlab/html/templates/
/opt/unetlab/html/images/icons/
/opt/unetlab/html/includes/config.yml
/opt/unetlab/html/includes/custom_templates.yml
```

The script collects additional bare-metal recovery metadata such as network configuration, package inventory, disks, routes, interfaces, and OS information. That metadata is supplemental and is not a substitute for the EVE-documented backup set.

### Backup modes

The script has two modes and their semantics must remain distinct.

#### `upgrade`

```bash
./backup.sh upgrade
```

Requirements:

- Validate prerequisites, NAS authentication, and remote write access before stopping EVE nodes.
- Stop all EVE nodes before copying the backup data.
- Create a new timestamped destination for every run.
- Perform an independent full backup rather than reusing the nightly destination.
- Verify expected backup contents.
- Copy the backup log to the NAS.
- Write `BACKUP_COMPLETE.txt` only after successful transfer and verification.
- Leave EVE nodes stopped after the backup so maintenance can proceed.
- Do not include the separate third-party image archive unless the user explicitly changes that requirement.

Current destination pattern:

```text
EVE-Backups/<hostname>/upgrade/<timestamp>/
```

#### `nightly`

```bash
./backup.sh nightly
```

Requirements:

- Do not stop EVE nodes.
- Synchronize to one persistent destination.
- Let rsync skip unchanged files on later runs.
- Do not use `--delete` unless the user explicitly approves changing the recovery semantics.
- Back up `/home/eve-ng/third_party_images` only when that directory exists.
- If `third_party_images` does not exist, log that it was skipped and continue successfully.
- Keep timestamped logs even though the data destination is persistent.

Current destination pattern:

```text
EVE-Backups/<hostname>/nightly/
```

### Third-party image behavior

The optional local directory is:

```text
/home/eve-ng/third_party_images
```

It is a local archive of third-party appliance images and is not part of the EVE-NG documented core backup set.

It is intentionally backed up only in nightly mode and only if it exists. Its NAS destination is:

```text
third_party_images/
```

Do not fail a nightly backup simply because this optional directory is absent.

### Deletion behavior

The nightly backup intentionally does not use:

```text
--delete
```

This is a recovery decision, not an omission. If an image or lab is accidentally deleted from EVE-NG, the next nightly backup should not automatically remove the NAS copy.

Do not add `--delete`, `--delete-excluded`, destination pruning, or automated stale-file deletion without explicit approval and a discussion of the recovery consequences.

### Running-node consistency

Nightly mode is intentionally non-disruptive and does not stop EVE nodes. Therefore it is not an atomic snapshot. Do not describe it as one.

Upgrade mode is the quiesced backup path because it stops nodes before copying data.

If stronger consistency is requested for nightly backups, discuss the tradeoff before implementing node shutdown, filesystem snapshots, LVM/ZFS snapshots, or other changes.

### Completion markers

The script uses:

```text
BACKUP_STARTED.txt
BACKUP_COMPLETE.txt
```

`BACKUP_COMPLETE.txt` must be written only after data transfer and verification succeed.

For nightly mode, the directory is persistent. Therefore the marker represents the most recent successful run and should be interpreted together with the timestamp in `BACKUP_STARTED.txt`.

### Restore behavior

Do not suggest blindly replacing the entire `/opt/unetlab` directory.

Restored EVE files may need:

```bash
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions
```

Database restoration must follow the EVE-NG restore procedure appropriate for the installed EVE version.

### Script requirements

The script is Bash, not POSIX `sh`.

It must retain:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Do not tell the user to run it as:

```bash
sh backup.sh
```

Use clear function names and comments. Avoid unnecessary shell cleverness. Prefer explicit behavior over compact one-liners for backup-critical logic.

A lock must prevent overlapping backup executions.

The password must not be embedded in the script. It is read from:

```text
/home/eve-ng/.synology-rsync-password
```

The password file must remain mode `600`.

### Validation for code changes

For every script change:

1. Run `bash -n backup.sh`.
2. Exercise `./backup.sh --help`.
3. Exercise `./backup.sh --doc`.
4. Review every rsync command for unintended deletion or destination changes.
5. Confirm the change does not alter `upgrade` versus `nightly` semantics unless that was the requested change.
6. If `shellcheck` is available, run it and explain any intentionally ignored warning.

Do not claim the live NAS backup path was tested unless it was actually executed against the Synology.

### Documentation requirements

Whenever behavior changes, update both:

```text
README.md
backup.sh --doc output
```

If the change affects development assumptions or invariants, update this prompt as well.

The documentation must clearly distinguish:

- EVE-NG documented backup paths,
- project-added system metadata,
- optional third-party image backups,
- upgrade versus nightly behavior,
- Synology rsync-daemon limitations.

### User interaction expectations

The user is an experienced network engineer and automation practitioner. Use precise networking, Linux, rsync, and EVE-NG terminology. Correct terminology when needed. When a design choice is ambiguous or high impact, ask a focused question rather than guessing. When code is supplied, point out actual defects and operational risks instead of merely confirming that it looks correct.

---

End of prompt.
