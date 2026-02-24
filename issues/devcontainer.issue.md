---
title: Add a Devcontainer

---

## Bootstap

We will use the safe, always-works-out-of-the-box Universal Devcontainer image that you get from a blank CodeSpace to start a codespave, where we can configure the container we rather want: One based on Ubuntu Latest, and which we know can run on both Linux, MacOS and Windows an buth AMD64 and ARM64 chipsets (Universal cant do that, it's optimized for CodeSpaces).


- [ ] Open a standard CodeSpace


<details><summary>Shorcut to open the command palette...</summary>

**Mac**: ⬆⌘P (shift+command+P)<br/>
**Windows/Linux**: ⬆^P (shift+ctrl+P)

</details>

- [ ] From the command palette **Codespaces: Add Devcontainer Configuration Files...**
  - **Create a new configuration...**
    - **Ubuntu** (devcontainers)
      - **Noble**
    - **Common Utilities** (devcontainers)
    - **GitHub CLI** (devcontainers)
    - **Go** (devcontainers)
    - **Python** (devcontainers)
    - **Keep Defaults**

<details><summary>You should end up with...</summary>
Effectively something like this:

```json
{
	"name": "Ubuntu",
	"image": "mcr.microsoft.com/devcontainers/base:noble",
	"features": {
		"ghcr.io/devcontainers/features/common-utils:2": {},
		"ghcr.io/devcontainers/features/github-cli:1": {},
		"ghcr.io/devcontainers/features/go:1": {},
		"ghcr.io/devcontainers/features/python:1": {}
	}
}
```

In `.devcontainers/devcontainer.json`
</details>

- [ ] From the command palette **Codespaces: Rebuild Container**

## Setup a `postCreateCommand` script

We want certain things to happen _after_ the Devcontainer is started. I have a generic script that I developed over time. I'll share it with you. You can improve it and make it your own.  What it does at this point is the following:

- Verifies if the GitHub CLI is sufficently authenticated (it should be we use it a lot).
- Installs the GitHub CLI extension `devx-cafe/gh-tt` (...more on this later).
- Installs some GitHub CLI aliases (if the are defined).
- Tells git that the _this_ repo is safe.
- Sets git up to read additional configuration settings from `./.gitconfig` (if it doens't exist it's simply ignored)
- Looks for language specific stuff to load
  - `Gemfile.lock` ...loadeded with `bundle`
  - `package-lock.json` ...loaded with `npm`
  - `go.mod` ...loaded with `go mod` (if found, it also installs `golangci-lint`)


- [ ] In the CodeSpace create the file `.devcontainer/postCreateCommand.sh`
- [ ] Copy the content of my script below into the file. Save it.
- [ ] In the terminal make it executable by running...
  ```bash
  chmod +x .devcontainer/postCreateCommand.sh 
  ```
- [ ] Test it by running...    
  ```bash
  .devcontainer/postCreateCommand.sh 
  ```
- [ ] Instruct the `.devcontainer/devcontainer.json` to run the `postCreateCommandsh` script. Add the json key/values:
  ```json
  "postCreateCommand": ".devcontainer/postCreateCommand.sh",
  "remoteEnv": {
    "GH_TOKEN": "${localEnv:GH_TOKEN}"
  }
  ```
⚠️ JSON is super sensitive that you get your commas right...

- [ ] From the command palette **Codespaces: Rebuild Container**

- [ ] commit your changes and push

<details><summary><code>.devcontainer/postCreateCommand.sh</code></summary>

```bash
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
```

</details>
