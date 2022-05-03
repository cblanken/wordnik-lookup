#!/bin/bash

# Set working directory
cd "$(dirname "$(realpath "$0")")" || exit
# Source necessary config files
. ./api_key

word="$1"
defs_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/definitions?api_key="$api_key")
def_exists=$(jq '.error' 2>/dev/null <<<"$defs_json")
if [ "$def_exists" = "\"Not Found\"" ]; then
    echo "No definitions exist on Wordnik for $word"
    exit 1
fi

pronunciations_json=$(curl -s -X GET --header Accept: application/json https://api.wordnik.com/v4/word.json/"$word"/pronunciations?api_key=$api_key)
pronunciations=$(echo "$pronunciations_json" | jq 'map(select(.rawType == "IPA"))' 2>/dev/null | jq -r '["PRONUNCIATION", "ALPHABET"], ["-------------", "--------"], (.[] | [.raw, .rawType]) | @tsv')
defs=$(echo "$defs_json" | jq -r '["SPEECH","DEFINITION"], ["------","----------"], (.[] | [.partOfSpeech, .text]) | @tsv' 2>/dev/null | sed 's/<[^>]*>//g')
print_defs() {
    echo -e "WORD\n----\n$word\n"
    # TODO: add top example
    echo "$pronunciations" | head -n5
    echo ""
    echo "$defs"
    echo ""
}

# Output definition
print_defs | less -cS
exit 0

