#!/bin/bash

# Set working directory
cd "$(dirname "$(realpath "$0")")" || exit
# Source necessary config files
. ./api_key

word="$1"

print_def() {
    defs_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/definitions?api_key=$api_key)
    echo "$defs_json" | jq -r '["SPEECH","DEFINITION"], ["------","----------"], (.[] | [.partOfSpeech, .text]) | @tsv' | sed 's/<[^>]*>//g'
}

# Output definition
echo "$word"
print_def | less

