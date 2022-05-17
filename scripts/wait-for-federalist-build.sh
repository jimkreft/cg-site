#!/bin/bash

if [ -z "$GITHUB_API_URL" ]; then
    echo "GITHUB_API_URL is required as environment variable" >&2
    exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
    echo "GITHUB_REPOSITORY information is required as environment variable" >&2
    exit 1
fi

if [ -z "$GITHUB_SHA" ]; then
    echo "GITHUB_SHA is required as environment variable" >&2
    exit 1
fi

debug() {
	if [[ -n ${DEBUG} && ${DEBUG} != '0' ]];
		then echo >&2 '>> ' "$*"
	fi
}

# Query for Federalist build success and return the preview URL if successful
is_federalist_build_successful() {
    GH_RESPONSE=$(curl --silent "$GITHUB_API_URL/repos/${GITHUB_REPOSITORY}/commits/$GITHUB_SHA/status")
    echo "$GH_RESPONSE"

    jq --version

    BUILD_INFO=$(echo "$GH_RESPONSE" \
        | jq --exit-status -c '.statuses[] | select(.context | contains("federalist/build"))')

    echo "$BUILD_INFO"

    BUILD_STATE=$(echo "$BUILD_INFO" | jq -r '.state')
    debug "build state: $BUILD_STATE"

    if [ "$BUILD_STATE" = "success" ]; then
        echo "$BUILD_INFO" | jq -r '.target_url'
        exit 0
    fi

    exit 1
}

attempt_counter=0
max_attempts=20

while ! is_federalist_build_successful; do
    if [ ${attempt_counter} -eq ${max_attempts} ]; then
      debug "Max attempts reached"
      exit 1
    fi

    debug "Did not find successful Federalist build, retrying"
    attempt_counter=$((attempt_counter+1))
    sleep 30
done