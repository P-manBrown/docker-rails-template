set -eu

GITHUB_PAT=$(cut -f 2 -d ":" ./.docker/api/secrets/github-pkg-cred.txt)
echo $GITHUB_PAT | gh auth login --with-token
