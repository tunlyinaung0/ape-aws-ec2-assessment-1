
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

### 1. Attach and Mount a Temporary EBS Volume

Attach a temporary EBS volume to the EC2 instance and mount it. Move the application log file to the temporary mount point.

<img width="636" height="222" alt="Screenshot 2026-07-17 at 9 08 43 PM" src="https://github.com/user-attachments/assets/e4702a63-d8ac-4de5-ae17-89a7019120e5" />


---

### 2. Archive Logs and Upload to Amazon S3

Create a Linux script named log-rotator.sh that runs every hour to:

- Compress the application log.
- Upload the compressed file to an Amazon S3 bucket using the EC2 IAM Role.

The archive file name format should be:

```text
application.log-Year-Month-Day-Hour-MinuteMMT.zip
```

---

### 3. Configure CloudWatch Monitoring

Set up the CloudWatch Agent.

Create:

- CloudWatch Dashboard
- CloudWatch Alarm

Monitor the **Disk Usage Percentage** for the application EC2 instance.
