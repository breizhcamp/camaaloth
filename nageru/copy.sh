#!/usr/bin/env bash
export LANG=C

if [[ "$#" -lt 3 ]]; then
    echo "Usage example: ./copy-script.sh /media/video 2019_03_03-BreizhJUG/export.mp4 /media/dest [user@host]"
    exit 1
fi

SRCDIR=$1
SRCFILE=$2
if [[ "$#" -eq 3 ]]; then
    DEST=$3
else
    DEST="$4$3"
fi

echo Copying \[${SRCFILE}\] from dir \[${SRCDIR}\] into ${DEST}

cd "${SRCDIR}"
rsync --times --progress --protect-args --relative "${SRCFILE}" "${DEST}"

RET=$?
echo Copy ended with code \[${RET}\]
exit ${RET}
