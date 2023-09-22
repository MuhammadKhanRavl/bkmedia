#!/bin/bash


# ----- GLOBAL VARIABLES ------------------------------------------------------------------

LOCATION_FILE="configs/locations.cfg"
LOG_FILE="configs/logs.cfg"
COMPLOG_FILE="configs/compressions.cfg"
BACKUP_DIR="backups"

# ----- FUNCTIONS -------------------------------------------------------------------------


# Displays a help message 
helpFunction() {
cat << "EOF"
  ___  _   ___ _  ___   _ ___   ____  __  
 | _ \/_\ / __| |/ / | | | _ \ |__ / /  \ 
 |  _/ _ \ (__| ' <| |_| |  _/  |_ \| () |
 |_|/_/ \_\___|_|\_\\___/|_|   |___(_)__/ 

Packup v3.0 - Backup and restore utility script 

USAGE:
  ./deploy.sh [OPTIONS] [ARGUMENTS]

OPTIONS:
  (empty)        Display available backup locations.
  -logs          Display all the backup logs.
  -comp          Display all the compression logs.
  -B             Create backups for all locations.
  -B [n]         Create a backup for location number [n].
  -R [n]         Restore backup number [n] in the backup logs.
  -R [n] -T      Restore backup number [n] in the backup logs with timestamps intact.
  -R -L [n]      Restore most recent backup for location [n].
  -R -L [n] -T   Restore most recent backup for location [n] with timestamps intact.
  -help          Display this help and exit.

EOF
}


# Reads from the global LOCATION_FILE and displays a list of all 
# locations in a formatted manner.
displayLocations() {
    echo -e "\nClient Locations:"

    local count=1
    while IFS=':' read -r userHost port backupDir
    do
        echo "$count. $userHost $port $backupDir"
        ((count++))
    done < "${LOCATION_FILE}"

    echo -e ""
}


# Reads from the global LOG_FILE and displays a list of backup 
# logs in a formatted manner.
displayLogs() {

    local count=1
    while IFS=':' read -r userHost port backupDir time
    do
        echo "$count. $userHost $port $backupDir $time"
        ((count++))
    done < "${LOG_FILE}"

}


# Writes a new log entry to the global LOG_FILE.
# Arguments:
#   userHost  - The user and host string.
#   port      - The port number.
#   backupDir - The directory to back up.
#   timestamp - The timestamp for the log.
writeLog() {

    # Pulling location information from args
    local userHost="$1"
    local port="$2"
    local backupDir="$3"
    local timestamp="$4"

    # Append the log to the file
    echo "${userHost}:${port}:${backupDir}:${timestamp}" >> "${LOG_FILE}"

}


# Writes a new compression log entry to the provided dir.
# Arguments:
#   location  - The origin of the file
#   oldSize   -  Size before compression
#   newSize   -  Size after compression
#   timestamp - The timestamp for the log.
writeComplog() {

    # Pulling location information from args
    local location="$1"
    local oldSize="$2"
    local newSize="$3"
    local timestamp="$4"

    # Append the log to the file
    echo "${location}:${oldSize}:${newSize}:${timestamp}" >> "${COMPLOG_FILE}"

}


# Reads from the global COMPLOG_FILE and displays a list of compression  
# logs in a formatted manner.
displayCompLogs() {

    local count=1
    while IFS=':' read -r location oldSize newSize timestamp
    do
        echo "${location} ${oldSize} ${newSize} ${timestamp}"
        ((count++))
    done < "${COMPLOG_FILE}"

}


# Reads the timestamps from the timewarp.log file for a given file
# Arguments:
#   filename  - The name of the file you want to get the timestamps for 
readTimestamps() {

    local filename="$1"
    local log_file="timewarp.log" 

    # Remove .timewarp extension 
    local filename="${filename%.timewarp}"

    # Use awk to extract the atime and mtime
    local line=$(grep "$filename:" "$log_file")
    if [[ -z "$line" ]]; then
        echo "Error - $filename not found in log."
        return 1
    fi

    local atime=$(echo "$line" | awk -F':' '{print $3}')
    local mtime=$(echo "$line" | awk -F':' '{print $4}')
    
    echo "$atime,$mtime"

}


# Creates a backup for a given location
# Arguments:
#   userHost    - The user and host string.
#   port        - The port number.
#   backupDir   - The directory to back up.
backupFrom() {
    
    # Pulling location information from args
    local userHost="$1"
    local port="$2"
    local backupDir="$3"

    # Generate a timestamp for backup folder (ISO8601 format)
    local timestamp=$(date --iso-8601=seconds)

    # Determining path for local backup folder
    local machineName="${userHost/@/-}-$port"
    local localBackupDir="${BACKUP_DIR}/${machineName}/${timestamp}"

    # Creating local backup folder
    mkdir -p "$localBackupDir"

    echo "${userHost}:${backupDir}/*"

    # Use scp to copy files over to local backup folder
    scp -p "${userHost}:${backupDir}/*" "$localBackupDir/" 

    # If SCP is successful 
    if [ $? -eq 0 ]; then

        # Iterate through files in localBackupDir
        for file in "$localBackupDir"/*; do

            # Getting timestamps of file and backup time (in unix format)
            local atime=$(stat -c %X "$file")
            local mtime=$(stat -c %Y "$file")
            local backupTime=$(date +%s) 
            
            # Adding timestamps to log
            local filename=$(basename "$file")
            echo "$filename:$backupTime:$atime:$mtime" >> "$localBackupDir/timewarp.log"

            # Handling compression 
            if [[ "$file" == *.xyzar ]]; then
                
                echo "A .xyzar file detected!"

                # Get original size 
                local originalSize=$(du -h "$file" | cut -f1)  

                # Compress
                gzip "$file"
                local compressedSize=$(du -h "${file}.gz" | cut -f1)

                # Log
                writeComplog "${userHost}" "$originalSize" "$compressedSize" "$timestamp"
            
            fi

        done

        # Finish off backup 
        echo "Backup - Completed successfully completed for ${userHost}:${port}."
        writeLog "$userHost" "$port" "$backupDir" "$timestamp" 

    # If SCP is unsuccessful 
    else
        echo "Error - Failed to backup for ${userHost}:${port}."
    fi

}


# Determines how to backup; all locations, or specific location. 
# Arguments:
#   locationNum  - The line number in locations file
backup() {

    # Stores the given function argument, which is the location number
    local locationNum="$1"

    # If there is no location number, backup from all locations
    if [ -z "$locationNum" ]; then
        echo "Backing up from all locations..."

        while IFS=':' read -r userHost port backupDir  
        do
            backupFrom "$userHost" "$port" "$backupDir"
        done < "${LOCATION_FILE}"

    # Restore from location number
    else 
        echo "Backing up from location ${locationNum}..."

        local count=1
        while IFS=':' read -r userHost port backupDir 
        do  
            if [[ "$count" -eq "$locationNum" ]]; then
                backupFrom "$userHost" "$port" "$backupDir"
            fi
            ((count++))
        done < "${LOCATION_FILE}"
    fi

}


# Restores a backup for a given location
# Arguments:
#   userHost  - The user and host string.
#   port      - The port number.
#   backupDir - The directory to back up.
#   timestamp - The time of backup to restore 
#   restoreTime - Whether or not to change timestamps back to original. 
restoreTo() {

    # Pulling location information from args
    local userHost="$1"
    local port="$2"
    local backupDir="$3"
    local timestamp="$4"
    local restoreTime="$5"

    # Determining machine name for accessing it's associated folder 
    local machineName="${userHost/@/-}-$port"

    # If no timestamp is provided, find the latest backup for the given machine
    if [[ -z "$timestamp" ]]; then

        # Determine latest timestamp
        timestamp=$(ls "${BACKUP_DIR}/${machineName}" | sort -r | head -n 1)
        if [[ -z "$timestamp" ]]; then
            echo "Error: No backups found for $machineName."
            return 1
        fi

    fi

    # Define path for backup location to restore from 
    local localBackupDir="${BACKUP_DIR}/${machineName}/${timestamp}"
    
    # Switch to the backup directory, saving the current dir 
    pushd "${localBackupDir}" > /dev/null  

    # Decompress files
    for file in ./*.xyzar.gz; do
        if [[ -f "$file" ]]; then
            gunzip "$file"
        fi
    done

    # Verifiy timestamps
    timewarpScan

    for file in *; do
        local filename=$(basename "$file")

        # Skip if the file is timewarp.log 
        if [[ "$filename" != "timewarp.log" ]]; then

            if [[ "$filename" == *.timewarp ]]; then
                
                echo "Timewarped file detected!"

                if [[ "$restoreTime" == "-T" ]]; then 

                    echo "Correcting timestamp..."

                    # Pull times from log file
                    IFS=',' read returned_atime returned_mtime < <(readTimestamps "$filename")

                    # Change timestamps
                    touch -a -d "@$returned_atime" "$filename"
                    touch -m -d "@$returned_mtime" "$filename"
                fi

                # Remove .timewarp
                mv "$filename" "${filename%.timewarp}"
                local filename="${filename%.timewarp}"

            fi    

            # Send over file
            scp -p "${filename}" "${userHost}:${backupDir}/"

        fi
    done

    # return to the original directory
    popd > /dev/null 

    echo "Restored backup ${timestamp} for ${userHost}."

}   


# Restores a backup for the location defined by log line number
# Arguments:
#   logNum  - The line number in log file
restoreLog(){

    local logNum="$1"
    local tw="$2"
    local count=1
    while IFS=':' read -r userHost port backupDir time
    do  
        if [[ "$count" -eq "$logNum" ]]; then
            echo "Restoring backup ${time} for ${userHost}:${port}..."
            restoreTo "$userHost" "$port" "$backupDir" "$time" "$tw"
        fi
        ((count++))
    done < "${LOG_FILE}"

}


# Restores a backup for the location defined by location line number
# Arguments:
#   locationNum  - The line number in locations file
restoreLoc() {

    local locNum="$1"
    local tw="$2"
    local count=1
    while IFS=':' read -r userHost port backupDir
    do  
        if [[ "$count" -eq "$locNum" ]]; then
            echo "Restoring latest backup for ${userHost}:${port}..."
            restoreTo "$userHost" "$port" "$backupDir" "" "$tw"
        fi
        ((count++))
    done < "${LOCATION_FILE}"

}


# Scans all the backup directories and looks for timewarps
timewarpScan() {

    # Loop through all files in the directory
    for file in *; do

        # Get name of file
        local filename=$(basename "$file")

        # Skip if the file is timewarp.log or already has a .timewarp extension
        if [[ "$filename" != "timewarp.log" ]] && [[ "$filename" != *.timewarp ]]; then
            
            # Read timestamps
            IFS=',' read returned_atime returned_mtime < <(readTimestamps "${filename}")

            # Get the current atime and mtime for the file 
            local currentAtime=$(stat -c %X "$file")
            local currentMtime=$(stat -c %Y "$file")

            # Calculate differences
            local diffAtime=$((currentAtime - returned_atime))
            local diffMtime=$((currentMtime - returned_mtime))

            # If the difference is more than 3 days (in seconds) or less than -3 days, mark the file
            if (( diffAtime > 259200 || diffAtime < -259200 )) || 
               (( diffMtime > 259200 || diffMtime < -259200 )); then
                mv "$file" "${file}.timewarp"
            fi

            # If there's a mismatch in the timestamps, add a .timewarp extension
            # if [[ "$currentAtime" != "$returned_atime" ]] || [[ "$currentMtime" != "$returned_mtime" ]]; then
            #     mv "$file" "${file}.timewarp"
            # fi

        fi
    done

}


# ----- MAIN --------------------------------------------------------------------------------


# Locations 
if [[ $# -eq 0 ]]; then
    displayLocations

# Logs
elif [[ "$1" == "-logs" ]]; then
    displayLogs
elif [[ "$1" == "-comp" ]]; then
    displayCompLogs

# Backup
elif [[ "$1" == "-B" ]]; then

    # Backing up from location number
    if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
        backup "$2"

    # Backung up from all locations 
    else
        backup 
    fi

# Restore
elif [[ "$1" == "-R" ]]; then

    # Restore latest to specific location    -R -L 1 -T
    if [[ "$2" == "-L" && "$3" =~ ^[0-9]+$ ]]; then
        restoreLoc "$3" "$4"
    
    # Restore specific log                   -R 1 -T
    elif [[ "$2" =~ ^[0-9]+$ ]]; then
        restoreLog "$2" "$3"

    # Catch invalid input. 
    else
        echo "Invalid arguments for -R. Please consult '-help' for proper usage."
    fi

# Help
elif [[ "$1" == "-help" ]]; then
    helpFunction

# Any other input
else
    echo "Unknown argument(s). Please consult '-help' for proper usage."
fi

