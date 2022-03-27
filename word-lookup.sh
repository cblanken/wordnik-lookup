#!/bin/bash

# Set working directory
cd "$(dirname "$(realpath "$0")")" || exit
# Source necessary config files
. ./api_key

word="$1"

print_defs() {
    pronunciations_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/pronunciations?api_key=$api_key)
    defs_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/definitions?api_key=$api_key)

    echo -e "WORD\n----\n$word\n"
    echo "$pronunciations_json" | jq 'map(select(.rawType == "IPA"))' | jq -r '["PRONUNCIATION", "ALPHABET"], ["-------------", "--------"], (.[] | [.raw, .rawType]) | @tsv'
    echo ""
    echo "$defs_json" | jq -r '["SPEECH","DEFINITION"], ["------","----------"], (.[] | [.partOfSpeech, .text]) | @tsv' | sed 's/<[^>]*>//g'
}

# Output definition
print_defs | less -S

