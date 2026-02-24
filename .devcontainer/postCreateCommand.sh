#!/usr/bin/env bash

set -eo pipefail

PREFIX="🍰  "
echo "$PREFIX Running $(basename $0)"

if [ -n "$GH_TOKEN" ]; then
  echo "$PREFIX  \$GH_TOKEN" defined. It takes precedens over \$GITHUB_TOKEN ...looking fine so far
else
  if [[ "$CODESPACES" == "true" ]]; then
      echo "$PREFIX No \$GH_TOKEN defined - using the standard ghu_*** token injected by the codespace into \$GITHUB_TOKEN"
  else
      echo "$PREFIX ⚠️ No \$GH_TOKEN defined - skipping GitHub CLI login."
      echo "$PREFIX    1) Run 'gh auth login -s project' to login with OAuth and sufficient permissions"
  fi
fi

set +e
gh auth status >/dev/null 2>&1
AUTH_OK=$?
set -e
if [ $AUTH_OK -ne 0 ]; then
  echo "$PREFIX ⚠️ Not logged into GitHub CLI"
  echo "$PREFIX    This is not loogking good  — we want GitHub CLI to work!"
else
  echo "$PREFIX GitHub Authnetication is working smooth!"
  echo "$PREFIX Installing the TakT gh cli extension from devx-cafe/gh-tt "
  gh extension install devx-cafe/gh-tt
  if [ -f ".devcontainer/.gh_alias.yml" ]; then
    echo "$PREFIX Installing the gh shorthand aliases"    
    gh alias import .devcontainer/.gh_alias.yml --clobber
  fi
fi

git config --global --add safe.directory $(pwd)
echo "$PREFIX ✅ Setting up safe git repository to prevent dubious ownership errors"

git config --local --get include.path | grep -e ../.gitconfig >/dev/null 2>&1 || git config --local --add include.path ../.gitconfig
echo "$PREFIX ✅ Setting up git configuration to support .gitconfig in repo-root"

if [ -f "Gemfile.lock" ]; then
    echo "$PREFIX Installing ruby gem...s"
    bundle config set frozen true
    bundle install
fi

if [ -f "package-lock.json" ]; then
    echo "$PREFIX Installing node modules..."
    npm ci
fi

# Install Go dependencies if go.mod exists
if [ -f "go.mod" ]; then
    echo "$PREFIX Installing Go dependencies..."
    go mod download

    echo "$PREFIX Installing golangci-lint"
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
    sh -s -- -b $(go env GOPATH)/bin latest
fi

echo "$PREFIX ✅ SUCCESS"
exit 0