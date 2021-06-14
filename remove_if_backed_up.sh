#!/bin/bash

set -e -x 

if [ -z "$1" -o \( ! -d "$1" \) -o -z "$2" -o \( ! -d "$2" \) ]; then
	echo "Usage: ./remove_if_backed_up.sh <backup location> <removal location>"
	exit 0
fi

set -u

BACKUP_LOCATION="$1"
REMOVE_LOCATION="$2"

BACKUP_HASHES=$(mktemp)
REMOVE_HASHES=$(mktemp)
FILES_TO_REMOVE=$(mktemp)

function on_exit() {
	rm $BACKUP_HASHES
	rm $REMOVE_HASHES
	rm $FILES_TO_REMOVE
}
trap on_exit EXIT

find "$BACKUP_LOCATION" -type f -print0 | xargs -0 -I {} md5sum {} | sort > $BACKUP_HASHES || true &
BACKUP_HASH_PID=$!

find "$REMOVE_LOCATION" -type f -print0 | xargs -0 -I {} md5sum {} | sort > $REMOVE_HASHES || true &
REMOVE_HASH_PID=$!

wait $BACKUP_HASH_PID $REMOVE_HASH_PID

echo "Found $(wc -l $BACKUP_HASHES) backup files"
echo "Found $(wc -l $REMOVE_HASHES) candidates for removal"

join -o 2.2 $BACKUP_HASHES $REMOVE_HASHES > $FILES_TO_REMOVE

echo "Removing $(wc -l $FILES_TO_REMOVE) files..."
cat $FILES_TO_REMOVE | xargs -I {} rm "{}"
echo "Done!"
