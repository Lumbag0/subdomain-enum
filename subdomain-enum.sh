#!/bin/bash

# Description: Prints the banner of the program
# Parameters: N\A
# Returns: N\A
function banner {
    echo "================================"
    echo "|--------Subdomain-Enum--------|"
    echo "================================"
    echo "|Author: Lumbag0               |"
    echo "================================"
}

# Description: Validates the required input to the script
# Paremters: status of options_used, url_set, out_set
# Returns: 1 if any one of the required inputs is not passed, 0 if successful
function validate_input {
    local options_used=$1
    local url_set=$2
    local out_set=$3
    local can_continue=0

    # Check that an argument was passed
    if ((options_used == 1)); then
        echo "ERROR: No Arguments Passed to the script, quitting..." > /dev/stderr
        usage
        can_continue=1
        return $can_continue
    fi
    
    # Check that the target url was passed
    if ((url_set == 1)); then
        echo "ERROR: Target not specified, quitting..." > /dev/stderr
        usage
        can_continue=1
        return $can_continue
    fi 

    # Check that the output file was passed
    if ((out_set == 1)); then
        echo "ERROR: Output file not specified, quitting..." > /dev/stderr
        usage
        can_continue=1
        return $can_continue
    fi 

    return $can_continue
}

# Description: Checks to make sure necessary commands are installed
# Parameters: N\A
# Returns: 0 if successfully installed jq or if jq is already installed 1 if install fails
function check_dependencies {
    # Check that jq is installed
    installed_jq=0
    if ! which jq > /dev/null; then 
        if ! sudo apt update && sudo apt install jq; then
            echo "ERROR: Could not install jq, quitting..." > /dev/stderr
            installed_jq=1
            return $installed_jq
        else
            return $installed_jq
        fi
    fi
    return $installed_jq
}

# Description: Prints usage information to the terminal
# Parameters: N\A
# Returns: N\A
function usage {
    echo "REQUIRED OPTIONS:"
    echo "-u <DOMAIN>: Domain to query for"
    echo "-o: Output to file"
    echo -e "\nOPTIONAL OPTIONS:"
    echo "-h: Display this help menu"
    echo -e "\nUSAGE: ./subdomain-enum.sh -u <DOMAIN> -o <OUTPUT_FILE>"
    echo "EXAMPLE: ./subdomain-enum.sh -u google.com -o google_domains"
}

# Description: Checks that crt.sh is reachable
# Parameters: N\A
# Returns: 0 if reachable 1 if not
function crt_reachable {
    is_reachable=

    # Search for status code 200, if found set is_reachable to 0, else set to 1
    if curl -sI https://crt.sh | grep -q 200; then
        echo "[*] INFO: crt.sh is reachable, commencing query..."
        is_reachable=0
    else
        echo "[*] ERROR: crt.sh is not reachable, quitting..." > /dev/stderr
        is_reachable=1
    fi

    return $is_reachable
}

# Description: Checks input for http or https and remove it from the input
# Parameters: Domain name to search for
# Returns: Cleaned input
function clean_input {
    local domain=$1

    # Check if http or https is in front of the domain, if so then remove it
    if echo "$domain" | grep -qe "http" -e "https"; then
        domain=${domain##*/}
    fi

    echo "$domain"
}

# Description: Query crt.sh for subdomains
# Parameters: Domain, output file
# Returns: subdomains
function crt_search {
    local domain=$1
    local output_file=$2

    curl -s "https://crt.sh/?q=$domain&output=json" -o "$domain"_raw_json
    jq -r '.[].common_name' < "$domain"_raw_json | sort -u | tee "$domain"
}

domain=
output_file=1
url_set=1
out_set=1

# Print Banner
banner

while getopts ":u:ho:" option; do
    options_used=0
    case $option in 
        h) 
            usage
            exit 0
            ;;
        u)
            domain=$OPTARG
            url_set=0
            ;;
        o)
            output_file=$OPTARG
            out_set=0
            ;;
        \?)
            echo "[*] ERROR: Invalid Option: $OPTARG" > /dev/stderr
            exit 1
            ;;
    esac
done

# Validate that arguments, url, and the output file are set, if one of them is not, then exit
if ! validate_input "$options_used" "$url_set" "$out_set"; then
    exit 1
fi

# Make sure neccessary packages are installed, if installation fails, exit
if ! check_dependencies; then
    exit 1
fi

# If crt.sh is not reachable, then quit
if ! crt_reachable; then
    exit 1
fi

# Clean input
domain=$(clean_input "$domain")

# Perform subdomain search
found_domains=$(crt_search "$domain" "$output_file")

echo "$found_domains"