#!/usr/bin/bash

#User enters input
echo "Enter input:"
read input
#Check if python is installed
if python3 --version; then
        echo "Python3 is installed"
else
 echo "Warning!Python3 not installed"
 exit 1
fi
#trapping signal
#Define cleanup function
cleanup() {
	echo "Ctrl+C pressed! Archiving..."
	
	if [ -d attendance_tracker_$input ];then
		tar -czf "attendance_tracker_${input}_archive.tar.gz" "attendance_tracker_$input"
        # Delete folder
        rm -rf "attendance_tracker_$input"
        echo "Project archived and incomplete folder deleted."
    else
        echo "No project folder found to archive."
    fi
}

#Creation of the tree
mkdir attendance_tracker_$input
cd attendance_tracker_$input
cat <<EOF > attendance_checker.py
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF
mkdir Helpers
cd Helpers
cat <<EOF > assets.csv
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
nziza@example.com,Nziza Gahima,2,13
teta@example.com,Teta Onyala,10,5
eva@example.com,Eva Joy,6,9
EOF
cat <<EOF > config.json
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF
cd ..
mkdir reports
cd reports
cat <<EOF > reports.log
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF
cd ..
#Update the attendance thresholds
while true; do
    read -p "Update warning and failure threshold: " warning failure
    
    # Check if both inputs are numeric
    if [[ "$warning" =~ ^[0-9]+$ ]] && [[ "$failure" =~ ^[0-9]+$ ]]; then
        echo "warning: $warning"
        echo "failure: $failure"
        break
    else
        echo "Error: Please enter values which are numbers only"
    fi
done

#Edit config.json file
sed -i "s/\"warning\": [0-9]\+/\"warning\": $warning/" Helpers/config.json
sed -i "s/\"failure\": [0-9]\+/\"failure\": $failure/" Helpers/config.json
echo "Updated thresholds in Helpers/config.json"
#Run the python file
python3 attendance_checker.py start
#Ensuring the application directory structure is followed
if [ -d "attendance_tracker_$input" ] && \
   [ -f "attendance_tracker_$input/attendance_checker.py" ] && \
   [ -d "attendnce_tracker_$input/Helpers" ] && \
   [ -f "attendance_tracker_$input/Helpers/assets.csv" ] && \
   [ -f "attendance_tracker_$input/Helpers/config.json" ] && \
   [ -d "attendance_tracker_$input/reports" ] && \
   [ -f "atendance_tracker_$input/reports/reports.log" ]; then
echo "Directory structure followed"
else
	echo "Directory structure not followed"
fi
