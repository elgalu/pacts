#!/usr/bin/env bash

GIT_AUTHOR=elgalu
GIT_URL="https://github.com/zalando/pacts"
GIT_SHA1=$(git rev-parse HEAD)
# Optional SCM working directory status information. Might contain git status output for example
# GIT_STATUS=$(git describe --all)

cat >scm-source.json <<EOF
{
    "url": "${GIT_URL}",
    "revision": "${GIT_SHA1}",
    "author": "${GIT_AUTHOR}",
    "status": ""
}
EOF
