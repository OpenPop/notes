#! /bin/bash
MBOX="$1"
NEWMBOX=$(mktemp)
sed -n '1h;1!H;${;g;s/Fossil-ID: \([0-9]*\)\n\n/Fossil-ID: \1\n\nr\1 /g;p;}' "$MBOX" > "$NEWMBOX"
cat "$NEWMBOX" > "$MBOX"
