#!/bin/bash
set -u

APP_ROOT="/home/pi/ApplicationDeploy"
APP_STAGE="/home/pi/ApplicationDeploy.new"
APP_BACKUP="/home/pi/ApplicationBackup"
STATE_FILE="/home/pi/.application_update_state"
LOG_FILE="/home/pi/.application_update.log"

mkdir -p /home/pi
exec >>"$LOG_FILE" 2>&1

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

state() {
  if [ -f "$STATE_FILE" ]; then
    printf '%s' "$(tr -d '\r\n' < "$STATE_FILE")"
  else
    printf '%s' "NONE"
  fi
}

remove_incomplete_stage() {
  if [ -d "$APP_STAGE" ]; then
    log "Removing incomplete staging directory: $APP_STAGE"
    rm -rf "$APP_STAGE"
  fi
}

validate_app_dir() {
  local target="$1"
  [ -d "$target" ] || return 1
  [ -r "$target" ] || return 1
  [ -x "$target" ] || return 1
  return 0
}

recover_on_boot() {
  local current_state
  current_state="$(state)"

  case "$current_state" in
    COPYING)
      log "Recovery: interrupted copy detected; cleaning staging area"
      remove_incomplete_stage
      echo "NONE" > "$STATE_FILE"
      ;;
    READY_TO_SWITCH|SWITCHING)
      log "Recovery: final swap is pending"
      if [ -d "$APP_STAGE" ] && validate_app_dir "$APP_STAGE"; then
        if [ -d "$APP_ROOT" ] && [ ! -d "$APP_BACKUP" ]; then
          mv "$APP_ROOT" "$APP_BACKUP"
        elif [ -d "$APP_ROOT" ] && [ -d "$APP_BACKUP" ]; then
          log "ApplicationBackup already exists; retaining it and replacing the active install"
          rm -rf "$APP_ROOT"
        fi

        if mv "$APP_STAGE" "$APP_ROOT" 2>/dev/null; then
          if validate_app_dir "$APP_ROOT"; then
            log "Recovery: installed new application successfully"
            echo "SUCCESS" > "$STATE_FILE"
            return 0
          fi
        fi

        if [ -d "$APP_BACKUP" ] && [ ! -d "$APP_ROOT" ]; then
          mv "$APP_BACKUP" "$APP_ROOT"
        fi
      else
        log "Recovery: invalid or missing staged app; removing stale stage"
        remove_incomplete_stage
      fi
      echo "NONE" > "$STATE_FILE"
      ;;
    SUCCESS)
      log "Recovery: previous update already succeeded"
      ;;
    *)
      if [ -d "$APP_STAGE" ] && ! validate_app_dir "$APP_STAGE"; then
        log "Recovery: removing invalid staged application"
        remove_incomplete_stage
      fi
      ;;
  esac
}

finalize_update() {
  if [ ! -d "$APP_STAGE" ]; then
    log "No staged update ready; nothing to do"
    echo "NONE" > "$STATE_FILE"
    exit 0
  fi

  if ! validate_app_dir "$APP_STAGE"; then
    log "Staged application is invalid; removing it"
    remove_incomplete_stage
    echo "NONE" > "$STATE_FILE"
    exit 1
  fi

  if [ -d "$APP_ROOT" ] && [ ! -d "$APP_BACKUP" ]; then
    log "Backing up current application to $APP_BACKUP"
    mv "$APP_ROOT" "$APP_BACKUP"
  elif [ -d "$APP_ROOT" ] && [ -d "$APP_BACKUP" ]; then
    log "ApplicationBackup already exists; keeping backup intact and replacing the live app"
    rm -rf "$APP_ROOT"
  fi

  if mv "$APP_STAGE" "$APP_ROOT" 2>/dev/null; then
    if validate_app_dir "$APP_ROOT"; then
      log "New application installed successfully"
      echo "SUCCESS" > "$STATE_FILE"
      exit 0
    fi
  fi

  if [ -d "$APP_BACKUP" ] && [ ! -d "$APP_ROOT" ]; then
    log "Swap failed; restoring previous application"
    mv "$APP_BACKUP" "$APP_ROOT"
  fi

  remove_incomplete_stage
  echo "ROLLBACK_REQUIRED" > "$STATE_FILE"
  exit 1
}

case "${1:-}" in
  --recover)
    recover_on_boot
    ;;
  --finalize)
    echo "SWITCHING" > "$STATE_FILE"
    finalize_update
    ;;
  *)
    case "$(state)" in
      READY_TO_SWITCH|SWITCHING)
        finalize_update
        ;;
      *)
        recover_on_boot
        ;;
    esac
    ;;
esac

exit 0
