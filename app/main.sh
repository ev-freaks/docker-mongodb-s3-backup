#!/usr/bin/env bash

set -e

function sanity_checks() {
  if ! [[ "$MONGODB_BACKUP_S3_URL" ]]; then
    echo "MONGODB_BACKUP_S3_URL env var not set"
    exit 20
  fi

  if ! [[ "$MONGODB_BACKUP_URI" ]]; then
    echo "MONGODB_BACKUP_URI env var not set"
    exit 20
  fi
}

function get_all_collections() {
  # MongoDB 6+ images no longer ship the legacy `mongo` shell, only `mongosh` - which prints a
  # deprecation warning for rs.secondaryOk() and pretty-prints arrays with single quotes (not
  # valid JSON), so this uses the non-deprecated read-pref call and forces real JSON output.
  mongosh "$MONGODB_BACKUP_URI" --quiet --eval "db.getMongo().setReadPref('secondaryPreferred'); JSON.stringify(db.getCollectionNames())" \
    | jq -r '.[]'
}

##
# Builds a mongoexport --readPreference value that prefers a replica set member in the same
# availability zone as this task, falling back to any secondary and then to the primary.
#
# Each mongoexport run reads a whole collection (no query/projection), so on a multi-GB
# collection this is real cross-AZ data transfer cost if it happens to land on a member in a
# different AZ than the task. The ECS task metadata endpoint (present on both EC2 and Fargate
# launch types) reports which AZ the task itself is running in; matching that against an `az`
# tag on the replica set members lets mongoexport route to the local one.
#
# Falls back to a plain "secondaryPreferred" (still off the primary, just not AZ-aware) when
# the metadata endpoint isn't reachable - e.g. when running the image outside of ECS - or when
# the replica set members aren't tagged with `az` yet, since an unmatched tagSet just falls
# through to the empty `{}` tagSet (any secondary).
function read_preference() {
  local az=""
  if [[ -n "$ECS_CONTAINER_METADATA_URI_V4" ]]; then
    az=$(curl -s -m 2 "$ECS_CONTAINER_METADATA_URI_V4/task" | jq -r '.AvailabilityZone // empty' 2>/dev/null || true)
  fi

  if [[ -n "$az" ]]; then
    echo "{\"mode\": \"secondaryPreferred\", \"tagSets\": [{\"az\": \"$az\"}, {}]}"
  else
    echo "secondaryPreferred"
  fi
}

function backup() {
  sanity_checks

  if [ $# -gt 0 ]; then
    collections=$*
  else
    collections=$(get_all_collections)
  fi

  s3_sse="--sse"
  read_pref=$(read_preference)
  echo "using read preference: $read_pref"

  backup_folder=$(date +%Y%m%d-%H%M%S)

  for collection in $collections ; do
    echo "processing collection $collection .. "
    backup_file="${collection}.jsonl.gz"

    mongoexport -c "$collection" --uri "$MONGODB_BACKUP_URI" --readPreference="$read_pref" \
      | gzip -c \
      | aws s3 cp - "$MONGODB_BACKUP_S3_URL"/"$backup_folder"/"$backup_file" --no-progress $s3_sse
  done
  echo "done."
}

##
# main

action=$1 ; shift

case "$action" in
  "backup")
    backup "$@"
    ;;
  *)
    echo "Usage: $0 backup"
    exit 10
    ;;
esac
