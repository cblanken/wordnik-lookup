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
    echo "No definitions exist on Wordnik for $word"
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
    printf "%s\t%s\n" "$1" "$2"
}

split=("--------------" "----------")
print_all() {
    println "WORD: $word"
    println ${split[0]} ${split[1]}
    println "PRONUNCIATION" "ALPHABET"
    println ${split[0]} ${split[1]}
    # TODO: add top example
    #echo -n "$pronunciations" | tail -n +2
    if [ "$pronunciations" != "" ]; then
        echo "$pronunciations" | head -n 5
        echo ""
    else
        println "" "No pronunciations found for \"$word\""
    fi
    println ${split[0]} ${split[1]}
    println "SPEECH" "DEFINITION"
    println ${split[0]} ${split[1]}
    printf "%b\n" "$defs"
}

# Output definition
print_all | column-new \
    --table \
    --separator $'\t' \
    --output-width 90 \
    --table-noheadings \
    --table-columns C1,C2 \
    --table-wrap C2 \
    --table-empty-lines \
    | less -cS
exit 0

