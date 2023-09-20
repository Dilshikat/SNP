#!/bin/bash

# Specify the target host or IP address
target=$1
file=$2
# Check if the user provided a target
if [ -z "$target" ]; then  #if null
    echo "Usage: ./recon.sh  <target>"
    exit 1
fi

# Check if the target host is reachable
if ! ping -c 1 -W 1 "$target"; then
  echo "Target host is not reachable"
  exit 1
fi

# Create a timestamp for log files
timestamp=$(date "+%Y-%m-%d_%H-%M-%S")

# Create a directory for the logs
log_dir="scan_logs_$timestamp"

counter=1
while [ -d "$log_dir" ]; do
    log_dir="scan_logs_${timestamp}_$counter"
    counter=$((counter + 1))
done
file_transfer_port=80
#create a directory
mkdir "$log_dir"

set +e
# Scan ports on the target host using Nmap
echo "starting nmap on the target host"
nmap  $target > "$log_dir/nmap_scan.txt"
echo "ending  nmap"
# Resolve the DNS hostname of the target host using Nslookup
echo "starting nslookup"
nslookup $target > "$log_dir/nslookup_scan.txt"
echo "end nslookup"
# Scan the target host for web vulnerabilities using Nikto
echo "start nikto"
nikto -host "$target"  -p 80 -T 25s  > "$log_dir/nikto_scan.txt"
 
echo "end nikto"
#sql map
echo "start sqlmap"
sqlmap -u $target/index.php?id=1 --batch  > "$log_dir/sql_scan.txt"
echo "stop sqlmap"

echo "Starting file transfer with nc"
nc -l -p $file_transfer_port > "$log_dir/received_file.txt" &  # Start nc in listening mode in the background
sleep 1  # Give nc some time to start listening
nc $target $file_transfer_port < $file  # Send the file to the target
echo "File transfer completed"
echo "all scans are completed!"

#display output
echo "-----Nmap outpt------"
cat "$log_dir/nmap_scan.txt"
rm $log_dir/nmap_scan.txt

echo "-----nslookup output------"
cat "$log_dir/nslookup_scan.txt"
rm $log_dir/nslookup_scan.txt

echo "-----nikto output-----    "
cat "$log_dir/nikto_scan.txt"
rm $log_dir/nikto_scan.txt

echo "sql map output"
cat "$log_dir/sql_scan.txt"
rm $log_dir/sql_scan.txt

echo "nc output"
cat "$log_dir/received_file.txt"
$log_dir/received_file.txt

rm -r  $log_dir 

 
