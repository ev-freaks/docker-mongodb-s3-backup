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
  mongo "$MONGODB_BACKUP_URI" --quiet --eval "rs.secondaryOk();db.getCollectionNames();" \
    | jq -r '.[]'
}

function backup() {
  sanity_checks

  if [ $# -gt 0 ]; then
    collections=$*
  else
    collections=$(get_all_collections)
  fi

  s3_sse="--sse"

  backup_folder=$(date +%Y%m%d-%H%M%S)

  for collection in $collections ; do
    echo "processing collection $collection .. "
    backup_file="${collection}.jsonl.gz"

    mongoexport -c "$collection" --uri "$MONGODB_BACKUP_URI" \
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
