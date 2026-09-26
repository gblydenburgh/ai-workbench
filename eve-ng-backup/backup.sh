#!/usr/bin/env bash

set -Eeuo pipefail

###############################################################################
# EVE-NG Backup to Synology
#
# Usage:
#   ./backup.sh upgrade
#   ./backup.sh nightly
#   ./backup.sh doc
#   ./backup.sh --doc
#
# This is a Bash script. Do not run it with: sh backup.sh
###############################################################################

# -----------------------------------------------------------------------------
# User configuration
# -----------------------------------------------------------------------------
readonly NAS_HOST="192.168.1.6"
readonly NAS_USER="eve-ng"
readonly NAS_MODULE="home"
readonly NAS_BACKUP_ROOT="EVE-Backups"
readonly RSYNC_PASSWORD_FILE="/home/eve-ng/.synology-rsync-password"
readonly THIRD_PARTY_IMAGES_DIR="/home/eve-ng/third_party_images"

# -----------------------------------------------------------------------------
# EVE-NG configuration
# -----------------------------------------------------------------------------
readonly EVE_ROOT="/opt/unetlab"

EVE_HOSTNAME="$(hostname -s)"
readonly EVE_HOSTNAME

TIMESTAMP="$(date '+%Y-%m-%d_%H%M%S')"
readonly TIMESTAMP

readonly RSYNC_REMOTE="${NAS_USER}@${NAS_HOST}::${NAS_MODULE}"
readonly LOCAL_WORK_DIR="/tmp/eve-backup-${TIMESTAMP}"
readonly LOCAL_METADATA_DIR="${LOCAL_WORK_DIR}/system-info"
readonly LOCAL_SEED_DIR="${LOCAL_WORK_DIR}/remote-tree"
readonly LOG_FILE="/var/log/eve-backup-${TIMESTAMP}.log"
readonly LOCK_FILE="/var/lock/eve-backup.lock"

declare -ar RSYNC_COMMON_ARGS=(
    --recursive
    --links
    --perms
    --times
    --hard-links
    --sparse
    --partial
    --human-readable
    --info=progress2
    --no-owner
    --no-group
    --password-file="${RSYNC_PASSWORD_FILE}"
)

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
        | tee -a "${LOG_FILE}"
}

fail() {
    log "ERROR: $*"
    exit 1
}

usage() {
    cat <<EOF_USAGE
Usage:
    $0 upgrade
    $0 nightly
    $0 doc
    $0 --doc

Modes:
    upgrade  Timestamped full backup. Stops EVE nodes and leaves them stopped.
    nightly  Persistent rsync backup. Nodes stay running; unchanged files skip.
    doc      Detailed operating documentation.
EOF_USAGE
}

show_documentation() {
    cat <<EOF_DOC
EVE-NG BACKUP SCRIPT
====================

PURPOSE
  Back up a bare-metal EVE-NG server to a Synology NAS using rsync daemon
  mode on TCP/873. SSH is not used.

SYNOLOGY CONNECTION
  NAS:        ${NAS_HOST}
  User:       ${NAS_USER}
  Module:     ${NAS_MODULE}
  Root:       ${NAS_BACKUP_ROOT}
  Password:   ${RSYNC_PASSWORD_FILE}

  The Synology rsync account can write data but cannot chgrp files, so the
  script intentionally uses --no-owner and --no-group.

CORE EVE-NG BACKUP SET
  /opt/unetlab/addons/
  /opt/unetlab/tmp/
  /opt/unetlab/labs/
  /opt/unetlab/evedb.gz

ADDITIONAL DATA
  EVE templates, icons, selected EVE config files, and bare-metal recovery
  metadata such as interfaces, routes, package inventory, disk layout, and
  operating-system information.

UPGRADE MODE
  Run:
      ./backup.sh upgrade

  Use before EVE upgrades, OS migrations performed by EVE, storage changes,
  or major server maintenance.

  Behavior:
    - Validates the NAS before disrupting EVE.
    - Stops all EVE nodes.
    - Creates a new timestamped full backup.
    - Verifies expected top-level backup content.
    - Copies the run log to the NAS.
    - Writes BACKUP_COMPLETE.txt last.
    - Leaves EVE nodes stopped.

  Destination:
      ${NAS_BACKUP_ROOT}/${EVE_HOSTNAME}/upgrade/<timestamp>/

NIGHTLY MODE
  Run:
      ./backup.sh nightly

  Behavior:
    - Does not stop EVE nodes.
    - Always writes to one persistent destination.
    - First run is a full backup.
    - Later runs let rsync skip unchanged files and transfer changed/new data.
    - Does NOT use --delete, so a source deletion does not immediately remove
      the NAS copy.
    - If ${THIRD_PARTY_IMAGES_DIR} exists, it is backed up as
      third_party_images/. If it does not exist, the backup continues.

  Destination:
      ${NAS_BACKUP_ROOT}/${EVE_HOSTNAME}/nightly/

CONSISTENCY
  Nightly mode is not an atomic snapshot because nodes remain running.
  Upgrade mode is the quiesced backup path.

STATUS MARKERS
  BACKUP_STARTED.txt is written when a run starts.
  BACKUP_COMPLETE.txt is written only after successful transfer/verification.
  In nightly mode, compare their timestamps to identify an interrupted run.

LOGGING
  Local logs:
      /var/log/eve-backup-<timestamp>.log

  Remote logs:
      <backup>/logs/eve-backup-<timestamp>.log

CONCURRENCY
  /var/lock/eve-backup.lock prevents overlapping runs.

RESTORE
  Do not blindly overwrite all of /opt/unetlab. Restore the required content
  to the corresponding EVE directories and then run:

      /opt/unetlab/wrappers/unl_wrapper -a fixpermissions

  Restore the EVE database using the procedure appropriate for the installed
  EVE version.

NIGHTLY CRON EXAMPLE
  0 2 * * * /home/eve-ng/backup.sh nightly >> /var/log/eve-nightly-cron.log 2>&1
EOF_DOC
}

parse_mode() {
    if [[ $# -ne 1 ]]; then
        usage
        exit 1
    fi

    case "$1" in
        upgrade)
            BACKUP_MODE="upgrade"
            REMOTE_BACKUP_DIR="${NAS_BACKUP_ROOT}/${EVE_HOSTNAME}/upgrade/${TIMESTAMP}"
            ;;
        nightly)
            BACKUP_MODE="nightly"
            REMOTE_BACKUP_DIR="${NAS_BACKUP_ROOT}/${EVE_HOSTNAME}/nightly"
            ;;
        doc|--doc|-d)
            show_documentation
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Invalid option: %s\n\n' "$1"
            usage
            exit 1
            ;;
    esac

    readonly BACKUP_MODE
    readonly REMOTE_BACKUP_DIR
}

require_root() {
    [[ ${EUID} -eq 0 ]] || fail "This script must be run as root."
}

acquire_lock() {
    exec 9>"${LOCK_FILE}"
    flock -n 9 || fail "Another EVE backup is already running."
}

verify_dependencies() {
    local command_name

    for command_name in rsync stat dpkg ip lsblk df uname hostname flock; do
        command -v "${command_name}" >/dev/null 2>&1 \
            || fail "Required command not found: ${command_name}"
    done
}

verify_password_file() {
    [[ -f "${RSYNC_PASSWORD_FILE}" ]] \
        || fail "Rsync password file not found: ${RSYNC_PASSWORD_FILE}"

    local mode
    mode="$(stat -c '%a' "${RSYNC_PASSWORD_FILE}")"
    [[ "${mode}" == "600" ]] \
        || fail "Password file must have mode 600. Current mode: ${mode}"
}

verify_eve_installation() {
    local path

    [[ -x "${EVE_ROOT}/wrappers/unl_wrapper" ]] \
        || fail "EVE-NG unl_wrapper not found under ${EVE_ROOT}."

    for path in "${EVE_ROOT}/addons" "${EVE_ROOT}/tmp" "${EVE_ROOT}/labs"; do
        [[ -d "${path}" ]] || fail "Required EVE directory not found: ${path}"
    done

    [[ -f "${EVE_ROOT}/evedb.gz" ]] \
        || fail "Required EVE database backup not found: ${EVE_ROOT}/evedb.gz"
}

verify_nas_authentication() {
    log "Testing Synology rsync authentication..."

    rsync \
        --password-file="${RSYNC_PASSWORD_FILE}" \
        "${RSYNC_REMOTE}/" \
        >/dev/null \
        || fail "Unable to authenticate to ${NAS_HOST}::${NAS_MODULE}."

    log "Synology authentication successful."
}

prepare_remote_backup() {
    log "Preparing and testing remote backup destination..."

    mkdir -p \
        "${LOCAL_SEED_DIR}/${REMOTE_BACKUP_DIR}/logs" \
        "${LOCAL_SEED_DIR}/${REMOTE_BACKUP_DIR}/custom"

    cat > "${LOCAL_SEED_DIR}/${REMOTE_BACKUP_DIR}/BACKUP_STARTED.txt" <<EOF_STARTED
EVE-NG backup started.
Mode:     ${BACKUP_MODE}
Hostname: ${EVE_HOSTNAME}
Started:  $(date --iso-8601=seconds)
EOF_STARTED

    rsync \
        --recursive \
        --times \
        --no-owner \
        --no-group \
        --no-perms \
        --password-file="${RSYNC_PASSWORD_FILE}" \
        "${LOCAL_SEED_DIR}/" \
        "${RSYNC_REMOTE}/" \
        >>"${LOG_FILE}" 2>&1 \
        || fail "Unable to create or write to the remote backup destination."

    log "Remote destination is writable."
}

stop_eve_nodes() {
    log "Stopping all EVE-NG nodes..."

    "${EVE_ROOT}/wrappers/unl_wrapper" -a stopall \
        >>"${LOG_FILE}" 2>&1 \
        || fail "EVE-NG reported an error while stopping nodes."

    sleep 10
    log "EVE-NG nodes stopped."
}

copy_metadata_file() {
    local source_file="$1"

    if [[ -f "${source_file}" ]]; then
        cp -a "${source_file}" "${LOCAL_METADATA_DIR}/$(basename "${source_file}")"
    fi
}

collect_metadata() {
    log "Collecting system metadata..."
    mkdir -p "${LOCAL_METADATA_DIR}"

    {
        echo "EVE-NG backup metadata"
        echo "Backup mode: ${BACKUP_MODE}"
        echo "Backup time: $(date --iso-8601=seconds)"
        echo "Hostname: ${EVE_HOSTNAME}"
        uname -a
    } > "${LOCAL_METADATA_DIR}/system.txt"

    dpkg -l > "${LOCAL_METADATA_DIR}/packages.txt"
    ip address show > "${LOCAL_METADATA_DIR}/ip-address.txt"
    ip route show > "${LOCAL_METADATA_DIR}/ip-route.txt"
    ip link show > "${LOCAL_METADATA_DIR}/ip-link.txt"
    lsblk -f > "${LOCAL_METADATA_DIR}/lsblk.txt"
    df -hT > "${LOCAL_METADATA_DIR}/df.txt"

    command -v lscpu >/dev/null 2>&1 \
        && lscpu > "${LOCAL_METADATA_DIR}/lscpu.txt"
    command -v free >/dev/null 2>&1 \
        && free -h > "${LOCAL_METADATA_DIR}/memory.txt"
    command -v lspci >/dev/null 2>&1 \
        && lspci > "${LOCAL_METADATA_DIR}/lspci.txt"
    command -v blkid >/dev/null 2>&1 \
        && blkid > "${LOCAL_METADATA_DIR}/blkid.txt" || true
    command -v eve-info >/dev/null 2>&1 \
        && eve-info > "${LOCAL_METADATA_DIR}/eve-info.txt" 2>&1 || true

    copy_metadata_file /etc/os-release
    copy_metadata_file /etc/hostname
    copy_metadata_file /etc/hosts
    copy_metadata_file /etc/fstab

    [[ ! -f /etc/network/interfaces ]] \
        || cp -a /etc/network/interfaces "${LOCAL_METADATA_DIR}/interfaces"
    [[ ! -d /etc/network/interfaces.d ]] \
        || cp -a /etc/network/interfaces.d "${LOCAL_METADATA_DIR}/interfaces.d"
    [[ ! -d /etc/netplan ]] \
        || cp -a /etc/netplan "${LOCAL_METADATA_DIR}/netplan"

    log "System metadata collected."
}

backup_directory() {
    local source_path="$1"
    local destination_path="$2"
    local rsync_status

    if [[ ! -d "${source_path}" ]]; then
        log "Skipping missing optional directory: ${source_path}"
        return
    fi

    log "Backing up ${source_path}/ -> ${destination_path}/"

    set +e
    rsync \
        "${RSYNC_COMMON_ARGS[@]}" \
        "${source_path%/}/" \
        "${RSYNC_REMOTE}/${REMOTE_BACKUP_DIR}/${destination_path}/" \
        2>&1 | tee -a "${LOG_FILE}"
    rsync_status="${PIPESTATUS[0]}"
    set -e

    [[ "${rsync_status}" -eq 0 ]] \
        || fail "rsync failed for ${source_path}. Exit code: ${rsync_status}"
}

backup_file() {
    local source_path="$1"
    local destination_path="$2"
    local rsync_status

    if [[ ! -f "${source_path}" ]]; then
        log "Skipping missing optional file: ${source_path}"
        return
    fi

    log "Backing up ${source_path} -> ${destination_path}"

    set +e
    rsync \
        --times \
        --perms \
        --partial \
        --human-readable \
        --no-owner \
        --no-group \
        --password-file="${RSYNC_PASSWORD_FILE}" \
        "${source_path}" \
        "${RSYNC_REMOTE}/${REMOTE_BACKUP_DIR}/${destination_path}" \
        2>&1 | tee -a "${LOG_FILE}"
    rsync_status="${PIPESTATUS[0]}"
    set -e

    [[ "${rsync_status}" -eq 0 ]] \
        || fail "rsync failed for ${source_path}. Exit code: ${rsync_status}"
}

backup_eve() {
    log "Starting EVE-NG data backup."

    # EVE-NG documented core backup set.
    backup_directory "${EVE_ROOT}/labs" "labs"
    backup_directory "${EVE_ROOT}/addons" "addons"
    backup_directory "${EVE_ROOT}/tmp" "tmp"
    backup_file "${EVE_ROOT}/evedb.gz" "evedb.gz"

    # EVE customizations.
    backup_directory "${EVE_ROOT}/html/templates" "custom/templates"
    backup_directory "${EVE_ROOT}/html/images/icons" "custom/icons"
    backup_file "${EVE_ROOT}/html/includes/config.yml" "custom/config.yml"
    backup_file \
        "${EVE_ROOT}/html/includes/custom_templates.yml" \
        "custom/custom_templates.yml"

    # Supplemental bare-metal recovery information.
    backup_directory "${LOCAL_METADATA_DIR}" "system-info"

    # Optional local archive: nightly only.
    if [[ "${BACKUP_MODE}" == "nightly" ]]; then
        if [[ -d "${THIRD_PARTY_IMAGES_DIR}" ]]; then
            backup_directory "${THIRD_PARTY_IMAGES_DIR}" "third_party_images"
        else
            log "Optional third-party image directory does not exist: ${THIRD_PARTY_IMAGES_DIR}"
        fi
    fi

    log "EVE-NG data transfer complete."
}

verify_remote_backup() {
    log "Verifying remote backup contents..."

    local listing
    local required_item

    listing="$(
        rsync \
            --password-file="${RSYNC_PASSWORD_FILE}" \
            "${RSYNC_REMOTE}/${REMOTE_BACKUP_DIR}/"
    )" || fail "Unable to read completed backup directory."

    printf '%s\n' "${listing}" >> "${LOG_FILE}"

    for required_item in addons labs tmp evedb.gz system-info; do
        grep -Fq "${required_item}" <<< "${listing}" \
            || fail "Expected remote backup item not found: ${required_item}"
    done

    if [[ "${BACKUP_MODE}" == "nightly" && -d "${THIRD_PARTY_IMAGES_DIR}" ]]; then
        grep -Fq "third_party_images" <<< "${listing}" \
            || fail "Expected remote backup item not found: third_party_images"
    fi

    log "Remote backup contents verified."
}

copy_log_to_nas() {
    local remote_log_path
    remote_log_path="${REMOTE_BACKUP_DIR}/logs/eve-backup-${TIMESTAMP}.log"

    rsync \
        --times \
        --no-owner \
        --no-group \
        --password-file="${RSYNC_PASSWORD_FILE}" \
        "${LOG_FILE}" \
        "${RSYNC_REMOTE}/${remote_log_path}" \
        || fail "Failed to copy backup log to Synology."
}

write_completion_marker() {
    local completion_file="${LOCAL_WORK_DIR}/BACKUP_COMPLETE.txt"

    cat > "${completion_file}" <<EOF_COMPLETE
EVE-NG backup completed successfully.
Mode:        ${BACKUP_MODE}
Hostname:    ${EVE_HOSTNAME}
Completed:   $(date --iso-8601=seconds)
Destination: ${NAS_HOST}::${NAS_MODULE}/${REMOTE_BACKUP_DIR}
EOF_COMPLETE

    rsync \
        --times \
        --no-owner \
        --no-group \
        --password-file="${RSYNC_PASSWORD_FILE}" \
        "${completion_file}" \
        "${RSYNC_REMOTE}/${REMOTE_BACKUP_DIR}/BACKUP_COMPLETE.txt" \
        || fail "Failed to write BACKUP_COMPLETE.txt to Synology."
}

cleanup() {
    [[ ! -d "${LOCAL_WORK_DIR}" ]] || rm -rf "${LOCAL_WORK_DIR}"
}

main() {
    parse_mode "$@"
    require_root
    verify_dependencies
    acquire_lock
    verify_password_file
    verify_eve_installation

    log "============================================================"
    log "EVE-NG BACKUP"
    log "Mode         : ${BACKUP_MODE}"
    log "EVE hostname : ${EVE_HOSTNAME}"
    log "NAS          : ${NAS_HOST}"
    log "rsync user   : ${NAS_USER}"
    log "rsync module : ${NAS_MODULE}"
    log "Backup path  : ${REMOTE_BACKUP_DIR}"
    [[ "${BACKUP_MODE}" != "nightly" ]] \
        || log "3rd-party dir: ${THIRD_PARTY_IMAGES_DIR} (optional)"
    log "============================================================"

    # Never disrupt EVE until NAS authentication and write access have passed.
    verify_nas_authentication
    prepare_remote_backup

    if [[ "${BACKUP_MODE}" == "upgrade" ]]; then
        stop_eve_nodes
    else
        log "Nightly mode: EVE nodes will remain running."
    fi

    collect_metadata
    backup_eve
    verify_remote_backup
    log "Backup data and verification completed successfully."

    # The completion marker is intentionally the final remote write.
    copy_log_to_nas
    write_completion_marker

    printf '\nBACKUP COMPLETED SUCCESSFULLY\n'
    printf 'Destination: %s::%s/%s\n' \
        "${NAS_HOST}" "${NAS_MODULE}" "${REMOTE_BACKUP_DIR}"

    if [[ "${BACKUP_MODE}" == "upgrade" ]]; then
        printf 'EVE nodes have intentionally been left stopped.\n'
    else
        printf 'Nightly incremental synchronization complete.\n'
    fi
}

trap cleanup EXIT
main "$@"
