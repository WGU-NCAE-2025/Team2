#!/bin/bash

# Prompt user for command choice
echo "Select which command to use for monitoring network connections:"
echo "1) netstat"
echo "2) ss"
read -p "Enter your choice (1 or 2): " choice

# Set the command based on user input
if [[ "$choice" == "1" ]]; then
    command="netstat"
elif [[ "$choice" == "2" ]]; then
    command="ss"
else
    echo "Invalid choice. Defaulting to netstat."
    command="netstat"
fi

while true; do
    clear
    echo "Retrieving active network connections using $command..."

    # Use the selected command to capture active connections
    if [[ "$command" == "netstat" ]]; then
        mapfile -t connections < <(netstat -tunap 2>/dev/null | awk 'NR>2 {print $4, $5, $7}' | sort -u)
    else
        mapfile -t connections < <(ss -tunp 2>/dev/null | awk 'NR>1 {print $5, $6, $7}' | sort -u)
    fi

    if [[ ${#connections[@]} -eq 0 ]]; then
        echo "No active network connections found."
    else
        echo -e "Index\tLocal Address\t\t\tForeign Address\t\t\tPID/Program\t\tParent User\tLogged-in User"
        echo "--------------------------------------------------------------------------------------------------------------"
        for i in "${!connections[@]}"; do
            local_addr=$(echo "${connections[$i]}" | awk '{print $1}')
            foreign_addr=$(echo "${connections[$i]}" | awk '{print $2}')
            pid_program=$(echo "${connections[$i]}" | awk '{print $3}')

            # Extract PID
            if [[ "$command" == "netstat" ]]; then
                pid=$(echo "$pid_program" | cut -d'/' -f1)
            else
                pid=$(echo "$pid_program" | sed -n 's/.*pid=\([0-9]*\),.*/\1/p')
            fi

            # Get Parent User (who owns the SSHD process)
            parent_user=$(ps -o user= -p "$pid" 2>/dev/null)

            # Get Child Process (actual logged-in user)
            child_pid=$(pgrep -P "$pid")
            if [[ -n "$child_pid" ]]; then
                logged_in_user=$(ps -o user= -p "$child_pid" 2>/dev/null)
            else
                logged_in_user="N/A"
            fi

            printf "[%d]\t%-25s %-25s %-15s %-12s %-12s\n" "$i" "$local_addr" "$foreign_addr" "$pid_program" "$parent_user" "$logged_in_user"
        done

        # Ask user to kill processes
        echo -e "\nEnter the number(s) of the connection(s) to kill (comma-separated), or wait 5 seconds to refresh:"
        read -t 5 -r input

        if [[ -n "$input" ]]; then
            IFS=',' read -ra selection <<< "$input"
            for index in "${selection[@]}"; do
                if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 0 && index < ${#connections[@]} )); then
                    # Extract PID for killing
                    if [[ "$command" == "netstat" ]]; then
                        pid=$(echo "${connections[$index]}" | awk '{print $3}' | cut -d'/' -f1)
                    else
                        pid=$(echo "${connections[$index]}" | awk '{print $3}' | sed -n 's/.*pid=\([0-9]*\),.*/\1/p')
                    fi

                    echo "Killing process with PID $pid..."
                    kill -9 "$pid" 2>/dev/null
                    if [[ $? -eq 0 ]]; then
                        echo "Killed process $pid"
                    else
                        echo "Failed to kill process $pid. You may need root privileges."
                    fi
                else
                    echo "Invalid selection: $index"
                fi
            done
            sleep 2
        fi
    fi
done
