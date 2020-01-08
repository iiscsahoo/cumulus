#!/bin/bash
set -ex
. ./bamboo/abort-if-not-pr.sh
. ./bamboo/set-bamboo-env-variables.sh

commit_message_contains_skip_audit_flag=false
commit_matches_version_tag=false


if [[ $(git log --pretty='format:%Creset%s' -1) =~ '[skip-audit]' ]]; then
  commit_message_contains_skip_audit_flag=true;
fi
if [[ $(git describe --exact-match HEAD 2>/dev/null |sed -n '1p') =~ ^v[0-9]+.* ]]; then
  commit_matches_version_tag=true;
fi

if [[ $commit_message_contains_skip_audit_flag = false && $commit_matches_version_tag = false && $SKIP_AUDIT != true ]]; then

 # If flag is set, use container-cached bootstrap env
 if [[ $USE_CACHED_BOOTSTRAP == true ]]; then
    echo "*** Using cached bootstrap"
    cd /cumulus/
 fi

  npm run install-locks;
  npm run audit;
else
  >&2 echo "******Skipping audit due to commit message/version tag/env var being present"
fi
