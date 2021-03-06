#!/bin/bash

tag_regex='v[0-9]+\.[0-9]+\.[0-9]+-osghotfix-[A-Za-z]+'
git tag -l | sort | egrep -x "$tag_regex" > git_tags

mkjson () {
  python -c '
import sys
import json

def esplit(x):
    return x.split("=", 1)

data = dict(map(esplit, sys.argv[1:]))
print(json.dumps(data, sort_keys=True))
' "$@"
}

json_auth=$(mkjson username="$DOCKER_USERNAME" password="$DOCKER_PASSWORD")

token=$(curl -s \
             -H "Content-Type: application/json" \
             -X POST \
             -d "$json_auth" \
             "https://hub.docker.com/v2/users/login/" | jq -r .token)

curl -s \
     -H "Authorization: JWT ${token}" \
     "https://hub.docker.com/v2/repositories/brianhlin/stash-cache/tags/?page_size=100" | \
    jq -r '.results|.[]|.name' | \
    sort | \
    egrep -x "$tag_regex" > dockerhub_tags

# cowardly only build one hotfix tag at a time
build_candidate=$(comm -23 git_tags dockerhub_tags | head -n 1)

echo "::set-output name=tag::$build_candidate"
