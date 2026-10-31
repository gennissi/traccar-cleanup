#!/usr/bin/env bash
# Delete Traccar positions and events older than $DAYS, in small batches.
set -euo pipefail

DAYS="${DAYS:-90}"          # how many days of history to keep
BATCH="${BATCH:-10000}"     # rows deleted per transaction
DB="${DB:-traccar}"
DRY_RUN="${DRY_RUN:-0}"     # set to 1 to only count rows

MYSQL=(mysql --defaults-extra-file=/etc/traccar-cleanup.cnf -N -B "$DB")

log() { echo "$(date '+%F %T') $*"; }
q()   { "${MYSQL[@]}" -e "$1"; }

# servertime is when the row was inserted, so it grows with the id.
# Find the first id we keep; everything below it is old.
keep_from=$(q "SELECT id FROM tc_positions
               WHERE servertime >= NOW() - INTERVAL $DAYS DAY
               ORDER BY id LIMIT 1")
if [[ -z "$keep_from" ]]; then
  keep_from=$(( $(q "SELECT COALESCE(MAX(id), 0) FROM tc_positions") + 1 ))
fi

old_positions=$(q "SELECT COUNT(*) FROM tc_positions WHERE id < $keep_from")
old_events=$(q "SELECT COUNT(*) FROM tc_events
                WHERE eventtime < NOW() - INTERVAL $DAYS DAY")
log "Keeping $DAYS days. Old positions: $old_positions, old events: $old_events"

if [[ "$DRY_RUN" == "1" ]]; then
  log "Dry run, nothing deleted."
  exit 0
fi

delete_in_batches() {
  local label=$1 sql=$2 total=0 n
  while :; do
    n=$(q "$sql LIMIT $BATCH; SELECT ROW_COUNT();")
    total=$(( total + n ))
    (( n < BATCH )) && break
    sleep 0.5   # give Traccar's inserts room to breathe
  done
  log "Deleted $total $label"
}

delete_in_batches "events" \
  "DELETE FROM tc_events WHERE eventtime < NOW() - INTERVAL $DAYS DAY"

# Never delete a device's latest position (tc_devices.positionid).
delete_in_batches "positions" \
  "DELETE FROM tc_positions
   WHERE id < $keep_from
     AND id NOT IN (SELECT positionid FROM tc_devices WHERE positionid IS NOT NULL)"

log "Done."
