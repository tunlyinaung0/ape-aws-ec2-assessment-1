#!/bin/bash

LOG_DIR="/var/log/storage-breaker"
LOG_FILE="$LOG_DIR/application.log"

TIMESTAMP=$(date +"%Y-%m-%d-%H-%MMMT")
RENAMED_LOG="$LOG_FILE-$TIMESTAMP"
ZIP_FILE="$RENAMED_LOG.zip"
S3_BUCKET="s3://tunlyinaung-test-bucket/logs/"

if [ -s "$LOG_FILE" ]; then
    # 1. Rename the active log file immediately to free up the path
    mv "$LOG_FILE" "$RENAMED_LOG"
    
    # 2. Recreate a fresh, empty application.log file so the app can keep writing
    touch "$LOG_FILE"
    chmod 664 "$LOG_FILE" 
    
    # 3. Zip the renamed file (-j ignores paths so the zip contains just the file)
    zip -j "$ZIP_FILE" "$RENAMED_LOG"
    
    # 4. Upload the zip to S3 and clean up local files
    if aws s3 cp "$ZIP_FILE" "$S3_BUCKET"; then
        echo "Successfully uploaded $ZIP_FILE to S3. Cleaning up local files."
        rm "$RENAMED_LOG"
        rm "$ZIP_FILE"
    else
        echo "ERROR: S3 upload failed! Keeping $RENAMED_LOG and $ZIP_FILE locally for safety." >&2
        exit 1
    fi
else
    echo "Log file does not exist or is empty. Skipping."
fi
