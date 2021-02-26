#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Please enter a git commit message"
    exit
fi
current_branch=$(git branch --show-current)
echo "Current branch: ${current_branch}"
rm -rf public
bundle exec jekyll build &&
    cd public &&
    git checkout gh-pages &&
    git add . &&
    git commit -m "$1" &&
    # git push origin gh-pages &&
    cd .. &&
    echo "Ready to deploy."
# echo "Successfully deployed to GitHub."
if [ ${current_branch} != "gh-pages" ]; then
    echo "Checking out previous branch ..." &&
        git checkout ${current_branch}
fi
echo "All good."
