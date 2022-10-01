set -eu

GITHUB_PKG_CRED=$(cat ./.docker/api/secrets/github-pkg-cred.txt)
bundle config https://rubygems.pkg.github.com/P-manBrown $GITHUB_PKG_CRED
