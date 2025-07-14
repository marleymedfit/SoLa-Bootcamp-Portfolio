# Bash Scripting Project
# Author: Marley Smith
# Date July 10,2025

#!/bin/bash

# ========== SETUP ==========
# Get timestamp safely
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# Detect who originally invoked sudo (or fallback to current user)
if [ "$SUDO_USER" ]; then
    actual_user="$SUDO_USER"
else
    actual_user="$USER"
fi

# Get their home directory (works even under sudo)
user_home=$(eval echo "~$actual_user")

# Check if Desktop exists, fallback to home if not
if [ -d "$user_home/Desktop" ]; then
    output_file="$user_home/Desktop/system_report_$timestamp.txt"
else
    output_file="$user_home/system_report_$timestamp.txt"
fi


# Starts writing to the report
echo "System Report - Generated on $timestamp" > "$output_file"
echo "======================================" >> "$output_file"

# 1. Collects and displays system information
echo -e "\n1. System Information:" >> "$output_file"
echo "Hostname: $(hostname)" >> "$output_file"
echo "IP Address: $(hostname -I)" >> "$output_file"
echo "Uptime: $(uptime -p)" >> "$output_file"
echo "Kernel Version: $(uname -r)" >> "$output_file"

# 2. Checks disk usage
echo -e "\n2. Disk Usage:" >> "$output_file"
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Disk Usage: $disk_usage%" >> "$output_file"
if [ "$disk_usage" -gt 80 ]; then
    echo "WARNING: Disk usage is above 80%!" >> "$output_file"
fi

# 3. Lists logged-in users and check for empty passwords
echo -e "\n3. Logged-In Users and Security Check:" >> "$output_file"
who >> "$output_file"
echo -e "\nUsers with Empty Passwords (security risk):" >> "$output_file"
awk -F: '($2==""){print $1}' /etc/shadow >> "$output_file"

# 4. Shows top 5 memory-using processes
echo -e "\n4. Top 5 Memory-Using Processes:" >> "$output_file"
ps aux --sort=-%mem | head -n 6 >> "$output_file"

# 5. Checks if important services are running
echo -e "\n5. Essential Services Status:" >> "$output_file"
for service in systemd auditd cron systemd-journald ufw; do
    if systemctl is-active --quiet $service; then
        echo "$service is running" >> "$output_file"
    else
        echo "WARNING: $service is NOT running" >> "$output_file"
    fi
done

# 6. Looks for failed login attempts
echo -e "\n6. Recent Failed Login Attempts:" >> "$output_file"
grep "Failed password" /var/log/auth.log | tail -10 >> "$output_file"

# Done!
echo -e "\nReport saved to $output_file"
