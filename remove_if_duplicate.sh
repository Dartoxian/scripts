#!/bin/bash

set -e -x 

if [ -z "$1" -o \( ! -d "$1" \) ]; then
	echo "Usage: ./remove_if_duplicate.sh <location>"
	echo ""
	echo "Finds duplicate files (for example photos in an archive) and removes them (randomly) until only unique files remain."
	exit 0
fi

set -u

LOCATION="$1"

HASHES=$(mktemp)
FILES_TO_REMOVE=$(mktemp)

function on_exit() {
	rm $HASHES
	rm $FILES_TO_REMOVE
}
trap on_exit EXIT

find "$LOCATION" -type f -print0 | xargs -0 -I {} md5sum {} | sort > $HASHES

echo "Found $(wc -l $HASHES) files in $LOCATION"

join <(sort $HASHES | cut -f 1 -d\  | uniq -d) t | perl -e 'my $lasthash=""; while(my $x = <>){my @a = split(/ /, $x,2); if ($a[0] eq $lasthash){print $a[1]} else { $lasthash = $a[0]} }' > $FILES_TO_REMOVE

echo "Found $(wc -l $FILES_TO_REMOVE) files that can be removed"

while IFS= read -r file; do rm -- "$file"; done < $FILES_TO_REMOVE
echo "Done!"
