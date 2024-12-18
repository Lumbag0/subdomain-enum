#!/bin/bash

# Description: Prints the banner of the program
# Parameters: N\A
# Returns: N\A
function banner {
    echo "================================"
    echo "|--------Subdomain-Enum--------|"
    echo "================================"
    echo "|Author: Lumbag0               |"
    echo -e "================================\n"
}

# Description: Checks to make sure necessary commands are installed
# Parameters: N\A
# Returns: N\A
function check_dependencies {
    # Check that jq is installed
    if ! which jq > /dev/null; then 
        sudo apt update && sudo apt install jq
    fi
}

# Description: Prints usage information to the terminal
# Parameters: N\A
# Returns: N\A
function usage {
    echo "OPTIONS:"
    echo "-u <DOMAIN>: Domain to query for"
    echo "-h: Display this help menu"
    echo "-o: Output to file"
    echo "USAGE: ./subdomain-enum.sh -u <DOMAIN>"
    echo "EXAMPLE: ./subdomain-enum.sh -u google.com"
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

    # If output file is not passed, then set the name of the domains file to the name of the domain being searched
    if [[ -z $output_file ]]; then
        curl -s "https://crt.sh/?q=$domain&output=json" | jq -r '.[].common_name' | sort -u | tee "$domain"
    else
        curl -s "https://crt.sh/?q=$domain&output=json" | jq -r '.[].common_name' | sort -u | tee "$output_file"
    fi
}

domain=
output_file=

# Print Banner
banner

while getopts ":u:ho:" option; do
    options_used=1
    case $option in 
        h) 
            usage
            exit 0
            ;;
        u)
            domain=$OPTARG
            ;;
        o)
            output_file=$OPTARG
            ;;
        \?)
            echo "[*] ERROR: Invalid Option: $OPTARG" > /dev/stderr
            exit 1
            ;;
    esac
done

# Checn to make sure that options were passed
if ((options_used == 0)); then
    echo "[*] ERROR: NO OPTIONS PASSED" > /dev/stderr
    usage
    exit 1
fi

# If crt.sh is not reachable, then quit
if ! crt_reachable; then
    exit 1
fi

# Make sure neccessary packages are installed
check_dependencies

# Clean input
domain=$(clean_input "$domain")

# Perform subdomain search
found_domains=$(crt_search "$domain" "$output_file")

echo "$found_domains"