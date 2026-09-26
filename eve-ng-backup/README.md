# EVE-NG Backup

Backup utility for a bare-metal EVE-NG server using a Synology NAS as the destination.

The script supports two operational modes:

- `upgrade` — creates a new timestamped, independent backup and stops all EVE nodes first.
- `nightly` — synchronizes to a persistent destination so rsync skips unchanged files on later runs.

The script also contains its own detailed operational documentation:

```bash
./backup.sh --doc
```

## Current environment

The checked-in defaults match the environment this utility was developed for:

```text
NAS:                   192.168.1.6
Synology rsync user:   eve-ng
Synology rsync module: home
Backup root:           EVE-Backups
Password file:         /home/eve-ng/.synology-rsync-password
Third-party images:    /home/eve-ng/third_party_images
```

Edit the configuration block at the top of `backup.sh` if these values change.

## Synology connection model

The script uses **rsync daemon mode** over TCP/873:

```text
eve-ng@192.168.1.6::home
```

It does **not** use SSH. This is intentional because normal Synology users are not granted an interactive SSH shell unless they are members of the administrators group.

The `eve-ng` account is configured as a Synology rsync account and has write access to its `home` module.

The rsync account can write files but cannot change Unix group ownership. The script therefore uses:

```text
--no-owner
--no-group
```

The rsync daemon connection is not SSH encrypted. It is intended for the trusted internal network between EVE-NG and the NAS.

## Backup contents

The core EVE-NG backup set comes from EVE-NG's documented manual-backup paths:

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

It additionally captures system metadata useful when rebuilding a bare-metal server, such as network configuration, package inventory, disk layout, routes, interfaces, and OS information.

Official EVE-NG backup documentation:

https://www.eve-ng.net/index.php/backup-eve-ng-content/

## Third-party images

Nightly mode optionally backs up:

```text
/home/eve-ng/third_party_images
```

The directory is copied only when it exists and is stored on the NAS as:

```text
third_party_images/
```

It is intentionally excluded from `upgrade` mode so that the upgrade backup remains focused on the EVE-NG recovery set.

## Installation

A typical installation location is:

```text
/home/eve-ng/backup.sh
```

Make the script executable and root-owned:

```bash
chown root:root /home/eve-ng/backup.sh
chmod 700 /home/eve-ng/backup.sh
```

Create the rsync password file:

```bash
printf '%s\n' 'RSYNC_PASSWORD' > /home/eve-ng/.synology-rsync-password
chown root:root /home/eve-ng/.synology-rsync-password
chmod 600 /home/eve-ng/.synology-rsync-password
```

The password file contains only the password for the Synology **rsync account**, not a shell command or username.

Do not run the script with `sh`. It is a Bash script:

```bash
./backup.sh nightly
```

or:

```bash
bash backup.sh nightly
```

## Upgrade backup

Run:

```bash
./backup.sh upgrade
```

Upgrade mode:

1. Verifies the local prerequisites and NAS connection.
2. Verifies that the remote destination is writable.
3. Stops all EVE-NG nodes.
4. Creates a new timestamped full backup.
5. Verifies the expected top-level backup contents.
6. Copies the run log to the NAS.
7. Writes `BACKUP_COMPLETE.txt` last.
8. Leaves EVE nodes stopped for the planned maintenance.

Example destination:

```text
EVE-Backups/
└── eve-ng/
    └── upgrade/
        └── 2026-09-26_143812/
            ├── addons/
            ├── labs/
            ├── tmp/
            ├── evedb.gz
            ├── custom/
            ├── system-info/
            ├── logs/
            ├── BACKUP_STARTED.txt
            └── BACKUP_COMPLETE.txt
```

Each `upgrade` run gets a new directory, so it is an independent recovery point rather than an incremental update of a prior upgrade backup.

## Nightly backup

Run:

```bash
./backup.sh nightly
```

Nightly mode does **not** stop EVE nodes. It always synchronizes to:

```text
EVE-Backups/eve-ng/nightly/
```

The first run copies the complete source set. Later runs use rsync's normal comparison and delta behavior, so unchanged files are skipped and only new or changed data needs to be transferred.

The script intentionally does **not** use `--delete`. If a lab or image is accidentally deleted from EVE-NG, a later nightly run will not immediately remove the backup copy from the NAS. The tradeoff is that stale files can accumulate and may eventually require manual cleanup.

Nightly backups are not atomic snapshots because EVE nodes remain running. Use `upgrade` mode when a quiesced recovery point is required.

## Scheduling

Example root crontab entry for 2:00 AM every night:

```cron
0 2 * * * /home/eve-ng/backup.sh nightly >> /var/log/eve-nightly-cron.log 2>&1
```

The script also creates its own timestamped log under `/var/log` and copies that log to the NAS.

## Backup status markers

Each destination contains:

```text
BACKUP_STARTED.txt
BACKUP_COMPLETE.txt
```

For an upgrade backup, the absence of `BACKUP_COMPLETE.txt` means that timestamped backup did not complete successfully.

For the persistent nightly destination, `BACKUP_STARTED.txt` records the most recent attempted run while `BACKUP_COMPLETE.txt` records the most recent successful run. Compare the timestamps if a nightly run was interrupted.

## Restore notes

Do not blindly overwrite the entire `/opt/unetlab` tree.

Restore the required data into the corresponding EVE directories and then repair EVE permissions:

```bash
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions
```

Database restoration should follow the EVE-NG restore procedure appropriate for the installed version.

Keep a timestamped upgrade backup until the upgraded EVE installation has been fully tested.

## Development

The project includes [`PROMPT_DRIVEN_DEVELOPMENT.md`](PROMPT_DRIVEN_DEVELOPMENT.md), which provides a self-contained prompt for continuing development with an AI coding assistant while preserving the current operational assumptions and safety constraints.
