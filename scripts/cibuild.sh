#!/usr/bin/env bash
set -e # halt script on error

bundle exec jekyll build
aws s3 sync public/ s3://mandarons.com --acl public-read --delete
aws cloudfront create-invalidation --distribution-id ${AWS_CLOUDFRONT_DISTRIBUTION_ID} --paths "/*"
