#!/bin/bash

# NOTE: `column-new` is an updated version of column binary from util-linux-2.35.
#       Ubuntu has an outdated version by default and doesn't allow for easy 
#       installation via apt, so it must be compiled from source.

# Set working directory
cd "$(dirname "$(realpath "$0")")" || exit

# Source api key
. ./api_key

# Query API for word data
word="$1"
defs_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/definitions?api_key="$api_key")
def_exists=$(jq '.error' 2>/dev/null <<< "$defs_json")
if [ "$def_exists" = "\"Not Found\"" ]; then
    echo "No definitions exist on Wordnik for \"$word\""
    exit 1
fi

# Parse definition data from json
defs=$(echo "$defs_json" \
    | jq -r '(.[] | [.partOfSpeech, .text]) | @tsv' 2>/dev/null \
    | sed 's/<[^>]*>//g')

# Parse pronunciation data from json
pronunciations_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/pronunciations?api_key=$api_key)
pronunciations=$(echo "$pronunciations_json" \
    | jq 'map(select(.rawType == "IPA"))' 2>/dev/null \
    | jq -r '(.[] | [.raw, .rawType]) | @tsv')

println() {
    printf "%b\t%b\n" "$1" "$2"
}

columnize() {
    column-new \
        --table \
        --separator $'\t' \
        --output-width 90 \
        --table-noheadings \
        --table-columns C1,C2 \
        --table-wrap C2 \
        --table-empty-lines <<< "$1"
    printf "\n"
}

split=("---------------" "----------")
print_pronunciations() {
    # TODO: fix Unicode IPA output
    if [ "$pronunciations" != "" ]; then
        println ${split[0]} ${split[1]}
        println "PRONUNCIATION" "ALPHABET"
        println ${split[0]} ${split[1]}
        p=$(head -n 5 <<< "$pronunciations")
        printf "%b\n" "$p"
    else
        printf "No pronunciations found for \"%b\"" "$word"
    fi
}

print_defs() {
    println ${split[0]} ${split[1]}
    println "SPEECH" "DEFINITION"
    println ${split[0]} ${split[1]}
    printf "%b" "$defs"
}

print_all() {
    printf "WORD: %s\n\n" "$word"
    p=$(print_pronunciations)
    columnize "$p"
    d=$(print_defs)
    columnize "$d"
    # TODO: add top example
}

# Output definition
print_all | less -cS
exit 0

