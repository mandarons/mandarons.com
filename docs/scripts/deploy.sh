#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Please enter a git commit message"
    exit
fi
current_branch=$(git branch --show-current)
echo "Current branch: ${current_branch}"
if [ ${current_branch} != "main" ]; then
    echo "Cannot deploy from non-main branch."
    exit
fi
rm -rf docs
rm -rf .jekyll-cache
bundle exec jekyll build &&
    git add doc/ &&
    git commit -m "$1" &&
    echo "Ready to deploy."
