#!/bin/bash
# Copyright (C) 2020 The Los-Legacy Open Source Project
# Mitch, Exodusnick, BenLue
set +xe
if [ -z "$*" ]; then
  TARGET_DATE=$(date +"%Y%m%d");
else
  export TARGET_DATE="$*";
fi

cd "${SYSTEM_PATH}" || exit

export SEARCH_FILENAME="$BRANCH-$TARGET_DATE-UNOFFICIAL-$DEVICE.zip"

echo "$OUTPUT_PATH"
echo "$FILENAME"
echo "$SEARCH_FILENAME"

if [ -e "$OUTPUT_PATH"/"$SEARCH_FILENAME"  ]; then
  echo "Starte Upload"  
    mv "$OUTPUT_PATH"/"$SEARCH_FILENAME" "$OUTPUT_PATH"/"$FILENAME" 
    md5sum "$OUTPUT_PATH"/"$FILENAME" > "$OUTPUT_PATH"/"$FILENAME"".md5sum" 
else
    ls "$OUTPUT_PATH"/"$SEARCH_FILENAME"
fi

if [ -e "$OUTPUT_PATH"/"$FILENAME" ]; then
  
  echo "Erstelle MD5-Prüfsummmendatei"
  
  MD5SUM=$(cat < "${OUTPUT_PATH}"/"${DEVICE}"/"${BRANCH}"-"$TARGET_DATE"-"${ROMTYPE}"-"${DEVICE}".zip.md5sum | awk '{ print $1 }')
  FILESIZE=$(stat -c%s "${OUTPUT_PATH}"/"${DEVICE}"/"${BRANCH}"-"$TARGET_DATE"-"${ROMTYPE}"-"${DEVICE}".zip )       
  DATETIME=$(date -u +"%F %H:%M:%S")
  export "${DATETIME?}"
  
  echo ""
  cat "${OUTPUT_PATH}"/"${DEVICE}"/"${BRANCH}"-"$TARGET_DATE"-"${ROMTYPE}"-"${DEVICE}".zip.md5sum
  echo ""
  echo "Übertrage Rom in Datenbank"
  echo "URL: ${URL}/${DEVICE}/${BRANCH}-$TARGET_DATE-${ROMTYPE}-${DEVICE}.zip"
  echo "Filename: ${BRANCH}-$TARGET_DATE-${ROMTYPE}-${DEVICE}.zip"
  echo "Device: ${DEVICE}"
  echo "OS Version: ${VERSION}"
  echo "Datetime: $DATETIME"
  echo "Romtype: $OTA_ROMTYPE"
  echo "MD5SUM: $MD5SUM"
  echo "SIZE: $FILESIZE"

  NO_SUCCESS=1  
    while [ "$NO_SUCCESS" != "0" ]; do
      scp "${OUTPUT_PATH}"/"${DEVICE}"/"${BRANCH}"-"$TARGET_DATE"-"${ROMTYPE}"-"${DEVICE}".zip "$USER"@los-legacy.de":/var/www/html/files/"$DEVICE"/
      NO_SUCCESS=$?;
    done
    NO_SUCCESS=1
    while [ "$NO_SUCCESS" != "0" ]; do
      scp "${OUTPUT_PATH}"/"${DEVICE}"/"${BRANCH}"-"$TARGET_DATE"-"${ROMTYPE}"-"${DEVICE}".zip.md5sum "$USER"@los-legacy.de:/var/www/html/files/"$DEVICE"/
      NO_SUCCESS=$?;        
    done
    echo ""
    echo "Entferne ggfs. bereits eingetragenes Build von heute"
    echo "cd /opt/lineageos_updater && FLASK_APP=/opt/lineageos_updater/app.py flask delrom -f ${BRANCH}-$DATETIME-${ROMTYPE}-${DEVICE}.zip"
    NO_SUCCESS=1
    while [ "$NO_SUCCESS" != "0" ]; do
      ssh "$USER"@los-legacy.de "cd /opt/lineageos_updater && FLASK_APP=/opt/lineageos_updater/app.py flask delrom -f \${BRANCH}-\${TARGET_DATE}-\${ROMTYPE}-\${DEVICE}.zip"
      NO_SUCCESS=$?;
    done
    echo ""
    echo "Veröffentliche Build von heute"
    echo "cd /opt/lineageos_updater && FLASK_APP=/opt/lineageos_updater/app.py flask addrom --filename ${BRANCH}-$TARGET_DATE-${ROMTYPE}-${DEVICE}.zip --device $DEVICE --version $VERSION --datetime \"""$DATETIME""\" --romtype $OTA_ROMTYPE --md5sum $MD5SUM --size ""$FILESIZE"" --url ${URL}/${DEVICE}/${BRANCH}-${TARGET_DATE}-${ROMTYPE}-${DEVICE}.zip"
    NO_SUCCESS=1
    while [ "$NO_SUCCESS" != "0" ]; do      
      ssh "$USER"@los-legacy.de "cd /opt/lineageos_updater && FLASK_APP=/opt/lineageos_updater/app.py flask addrom --filename ${BRANCH}-$TARGET_DATE-${ROMTYPE}-${DEVICE}.zip --device $DEVICE --version $VERSION --datetime \'""$DATETIME""\' --romtype $OTA_ROMTYPE --md5sum $MD5SUM --size ""$FILESIZE"" --url ${URL}/${DEVICE}/${BRANCH}-${TARGET_DATE}-${ROMTYPE}-${DEVICE}.zip"
      NO_SUCCESS=$?;    
    done
fi
