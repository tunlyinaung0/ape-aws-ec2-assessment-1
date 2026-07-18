
# Permission Issue While Installing

Facing permission issue while installing.

<img width="629" height="144" alt="Screenshot 2026-07-17 at 9 04 02 PM" src="https://github.com/user-attachments/assets/898cce65-f3d9-48f7-be3b-e21d1c6140c5" />


## Investigation

Checked the directory owner and found that it is owned by the **root** user.

<img width="626" height="110" alt="Screenshot 2026-07-17 at 9 05 41 PM" src="https://github.com/user-attachments/assets/dadc2df6-87ea-4d3b-8d75-fe84882e5db1" />


## Solution

Change the ownership of the current directory and all child directories to the **ubuntu** user.

```bash
sudo chown -R ubuntu:ubuntu /opt/storage-breaker
```

<img width="636" height="110" alt="Screenshot 2026-07-17 at 9 06 41 PM" src="https://github.com/user-attachments/assets/da0406f4-9586-44f6-a59d-3ea851a809fe" />


After changing the ownership, the permission issue was resolved.


---

# Postmortem: No Available Storage Left on EC2

## Investigation

Checking the instance health on the `/health` endpoint showed that the application was **unhealthy**.

Performed the following basic checks:

- CPU Usage
- Memory Usage

Both CPU and Memory usage were normal.

Next, checked the disk usage using:

```bash
df -hT
```

Found that the storage was completely full.

<img width="639" height="190" alt="Screenshot 2026-07-17 at 9 08 19 PM" src="https://github.com/user-attachments/assets/c04ee155-4157-41a0-8231-4ca929a01ec6" />


## Solution


### 1. Archive Logs and Upload to Amazon S3

Create a Linux script named log-rotator.sh that runs every hour to:

- Compress the application log.
- Upload the compressed file to an Amazon S3 bucket using the EC2 IAM Role.

The archive file name format should be:

```text
application.log-Year-Month-Day-Hour-MinuteMMT.zip
```

```bash
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
```

---

### 2. Configure CloudWatch Monitoring

Set up the CloudWatch Agent.

Create:

- CloudWatch Dashboard
- CloudWatch Alarm

Monitor the **Disk Usage Percentage** for the application EC2 instance.
