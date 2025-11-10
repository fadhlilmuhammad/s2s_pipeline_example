#!/bin/bash
# filepath: /g/data/v46/fm6730/script_access_s2/vorticity/watch_jobs.sh

while true; do
    clear
    echo "=== VORTICITY JOB MONITORING ==="
    echo "Press Ctrl+C to exit | Refreshing every 30 seconds"
    echo "Last updated: $(date)"
    echo ""
    
    # Get job counts by status
    job_counts=$(qstat -u $USER | tail -n +3 | awk '{print $5}' | sort | uniq -c 2>/dev/null)
    
    if [ -n "$job_counts" ]; then
        echo "Job Summary:"
        echo "$job_counts" | awk '{
            status = $2
            count = $1
            if (status == "R") printf "  🟢 Running: %d\n", count
            else if (status == "Q") printf "  🟡 Queued: %d\n", count  
            else if (status == "H") printf "  🔵 Held: %d\n", count
            else if (status == "E") printf "  🔴 Error: %d\n", count
            else printf "  ⚪ %s: %d\n", status, count
        }'
        echo ""
        
        # Show detailed job list
        echo "Detailed Status:"
        qstat -u $USER | head -2  # Header
        qstat -u $USER | tail -n +3 | sort -k2  # Jobs sorted by name
    else
        echo "✅ No active jobs - all completed!"
    fi
    
    sleep 30
done