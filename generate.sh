#!/bin/bash

set -e

TEMPLATE="template.xml"

process_allowed_ips_to_output() {
    local conf_file=$1
    local allowed_ips=$2
    local output_file=$3

    awk -v new_ips="$allowed_ips" '
    /^AllowedIPs[[:space:]]*=/ {
        print "AllowedIPs = " new_ips
        next
    }
    { print }
    ' "$conf_file" > "$output_file"

    echo "✔ Replaced AllowedIPs in $conf_file"
}

generate_xml() {
    local processed_conf=$1
    local env_file=$2
    local output_file=$3
    local company=$4

    cp "$TEMPLATE" "$output_file"

    source "$env_file"

    local endpoint=$(grep 'Endpoint =' "$processed_conf" | cut -d ' ' -f 3)
    local conf_content=$(sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' "$processed_conf")
    local profile_id="com.${company}.vpn.profile"
    local payload_id="com.${company}.vpn.payload"

    xmlstarlet ed --inplace \
        -u "//key[text()='PayloadIdentifier' and following-sibling::string[1]='COMPANY_ID_PROFILE']/following-sibling::string[1]" -v "$profile_id" \
        -u "//key[text()='PayloadIdentifier' and following-sibling::string[1]='COMPANY_ID_PAYLOAD']/following-sibling::string[1]" -v "$payload_id" \
        -u "//key[text()='DNSServerAddressMatch']/following-sibling::array/string" -v "$DNS_SERVER" \
        -u "//key[text()='RemoteAddress']/following-sibling::string[1]" -v "$endpoint" \
        -u "//key[text()='WgQuickConfig']/following-sibling::string[1]" -v "$conf_content" \
        "$output_file"

    echo "✔ Generated mobileconfig for $output_file"

    # Clean up the intermediate file
    rm -f "$processed_conf"
}

main() {
    mkdir -p output

    for conf_file in configs/*.conf; do
        [[ "$conf_file" == *.processed.conf ]] && continue

        filename=$(basename "$conf_file" .conf)
        output_file="output/${filename}.mobileconfig"

        # Extract company name from filename
        company=$(echo "$filename" | awk -F'_' '{print $NF}')
        company_lower=$(echo "$company" | tr '[:upper:]' '[:lower:]')
        env_file="env/${company_lower}.env"

        if [[ -f "$env_file" ]]; then
            processed_conf="configs/${filename}.processed.conf"
            source "$env_file"
            process_allowed_ips_to_output "$conf_file" "$ALLOWED_IPS" "$processed_conf"
            generate_xml "$processed_conf" "$env_file" "$output_file" "$company"
        else
            echo "⚠️ Missing env file for $company (from $filename), skipping."
        fi
    done
}

main
