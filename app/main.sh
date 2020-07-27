#!/usr/bin/env bash

set -e

function sanity_checks() {
  if ! [[ $MONGODB_BACKUP_S3_URL ]]; then
    echo "MONGODB_BACKUP_S3_URL env var not set"
    exit 20
  fi

  if ! [[ $MONGODB_BACKUP_URI ]]; then
    echo "MONGODB_BACKUP_URI env var not set"
    exit 20
  fi
}

function backup() {
  sanity_checks
  collections=$*

  s3_sse="--sse"

  tmp_dir=$(mktemp -d /tmp/mongodb-backup.XXXXXXXXXX)
  backup_folder=$(date +%Y%m%d-%H%M%S)

  for collection in $collections ; do
    echo -n "processing collection $collection .. "
    backup_file="${tmp_dir}/${collection}.jsonl.gz"

    mongoexport -c "$collection" --quiet --uri "$MONGODB_BACKUP_URI" | gzip -c > "$backup_file"
    aws s3 cp "$backup_file" "$MONGODB_BACKUP_S3_URL"/"$backup_folder"/ $s3_sse

    rm -f "$backup_file"
    echo "done."
  done

  rmdir "$tmp_dir"
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
