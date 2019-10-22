#!/bin/sh

set -e

rm -rf dist
mkdir dist

zip dist/terraform-aws-cumulus-distribution.zip \
  *.tf \
  bucket_map.yaml.tmpl \
  dist/src.zip
