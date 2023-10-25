#!/bin/bash

# This is a Bash script by Afxin Amini.
# You can use, modify, and distribute this script under the terms of the MIT License.

# MIT License
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF,
# OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Function to display a usage message
usage() {
  cat << EOF
Usage: $0 <command> <arguments> [options]

Commands:
  list   List nexus3 components
  delete Delete nexus3 components

Required Arguments:
  -a, --url      Specify the URL
  -u, --username Specify the username
  -p, --password Specify the password
  -r, --repo     Specify the repository

For the 'delete' command:
  -k, --keep     Keep a backup (optional)

Example usage:
  List items:
  $0 list -a https://example.com -u user -p pass -r my-docker-repo

  Delete items:
  $0 delete -a https://example.com -u user -p pass -r my-docker-repo -k 3
EOF
  exit 1
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to use this script."
    exit 1
fi

get_components() {
  # get list of all components in the repository and store it temporary
  json_response=`curl -s -u "$1:$2" -X GET "$3/service/rest/v1/components?repository=$4"`
  continuationToken=`echo "$json_response" | jq -r '.continuationToken'`
  components_list=`echo "$json_response" | jq -r '[.items[] | select(.format == "docker")']`

  while [[ $continuationToken != 'null' ]]; do
    json_response=`curl -s -u "$1:$2" -X GET "$3/service/rest/v1/components?repository=$4&continuationToken=$continuationToken"`
    continuationToken=`echo "$json_response" | jq -r '.continuationToken'`

    tmp_list=`echo "$json_response" | jq -r '[.items[] | select(.format == "docker")]'`
    components_list=`jq --argjson tmp_list "${tmp_list}" '. += $tmp_list' <<< "$components_list"`
  done
  echo "$components_list" > /tmp/nexus3_components.json
}

# Function to implement function1
list_components() {
  
  #get_components $1 $2 $3 $4
  # cat /tmp/nexus3_components.json \
  #   | jq '[.[] | { "name": .name, "version": .version }] 
  #         | group_by(.name)
  #         | map({name: .[0].name, "versions": [.[].version]})'

  cat /tmp/nexus3_components.json \
    | jq ''
    # [.[] | { "name": .name, "version": .version, "assets": {"id": .assets[].id,"blobCreated": .assets[].blobCreated}}]
    #       | group_by(.name)
    #       | map({name: .[0].name, version: .[].version, assets: [.[].assets]})
    #       | .[] | .assets |= sort_by(.blobCreated)'

  
}

# Function to implement function2
delete_component() {
  echo "Running delete_component"
  # Add code for function2 here
  cat /tmp/nexus3_components.json \
    | jq --arg keep_last "$5" \
          '[.[] | { "name": .name, "assets": {"id": .assets[].id,"blobCreated": .assets[].blobCreated}}]
           | group_by(.name)
           | map({name: .[0].name, assets: [.[].assets]})
           | .[] | .assets |= sort_by(.blobCreated)[:-($keep_last|tonumber)]'
}

# Parse the command
if [ $# -eq 0 ]; then
  usage
fi

command="$1"
shift

# Parse command-line options
case "$command" in
  list)
    # Parse options for the 'list' command
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -a | --url)
          url="$2"
          shift 2
          ;;
        -u | --username)
          username="$2"
          shift 2
          ;;
        -p | --password)
          password="$2"
          shift 2
          ;;
        -r | --repo)
          repo="$2"
          shift 2
          ;;               
        *)
          echo "Unknown option for 'list' command: $1"
          usage
          ;;
      esac
    done
    # code for 'list' command here
    list_components $username $password $url $repo
    ;;

  delete)
    # Parse options for the 'delete' command
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -a | --url)
          url="$2"
          shift 2
          ;;
        -u | --username)
          username="$2"
          shift 2
          ;;
        -p | --password)
          password="$2"
          shift 2
          ;;
        -r | --repo)
          repo="$2"
          shift 2
          ;;
        -k | --keep)
          keep="yes"
          shift
          ;;
        *)
          echo "Unknown option for 'delete' command: $1"
          usage
          ;;
      esac
    done
    # Add code for 'delete' command here
    echo "Delete items:"
    echo "URL: $url"
    echo "Username: $username"
    echo "Password: $password"
    echo "Repository: $repo"
    echo "Keep Backup: $keep"
    ;;

  *)
    echo "Unknown command: $command"
    usage
    ;;
esac

# Check if the required options are provided
if [ -z "$url" ] || [ -z "$username" ] || [ -z "$password" ] || [ -z "$repo" ]; then
  usage
fi












# for component in `curl -s -u "$NEXUS_AUTH" \
#                        -X GET "$NEXUS_URL/service/rest/v1/components?repository=$NEXUS_REPOSITORY_NAME" \
#                        | jq -r '.items[] | select(.format == "docker") | .name'`; do
#   echo $component
#   curl -s -u "$NEXUS_AUTH" \
#        -X GET "$NEXUS_URL/service/rest/v1/search?repository=$NEXUS_REPOSITORY_NAME&name=$component" | \
#        jq -r '.items[] | select(.format == "docker") | .version + " " + .assets[].id' | grep 'build' | sort -r > tmp_assets
#   sed -i -n "$(($NEXUS_KEEP_LAST + 1)),\$p" tmp_assets
#   for asset_id in `cat tmp_assets | awk '{print $2}'`;do
#     curl -s -X DELETE -u "$NEXUS_AUTH" "$NEXUS_URL/service/rest/v1/assets/$asset_id"
#   done
# done
