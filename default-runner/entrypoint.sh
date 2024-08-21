#!/usr/bin/env bash

export RUNNER_TOKEN=$(curl -L -X POST -H "Accept: application/vnd.github+json" \
     -H "Authorization: Bearer $ACCESS_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" \
     https://api.github.com/orgs/sliide/actions/runners/registration-token | jq -r .token)
/runner/config.sh --unattended --url $ORG_URL --token $RUNNER_TOKEN --labels $LABELS --ephemeral $EPHEMERAL && source /runner/run.sh
