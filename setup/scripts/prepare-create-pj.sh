#!/usr/bin/env bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ -e /.dockerenv ]]; then
	err 'This file must be run on the host.'
	exit 1
fi

if ! ps -p "$$" | grep -q 'bash'; then
	err 'This file must be run with Bash.'
	exit 1
fi

if ! git branch | grep -q 'main'; then
	err "Change the default branch to 'main'."
	exit 1
fi

# Set up Git/GitHub
echo 'Setting up GitHub...'
## Enable to automatically delete head branches
github_user="$(git config --get user.name)"
repo_name="$(basename -s .git "$(git remote get-url origin)")"
gh repo edit "${github_user}/${repo_name}" --delete-branch-on-merge
echo 'Setting up Git...'
## Reflect global ignore
gitignore_global="${XDG_CONFIG_HOME:-${HOME}}/.config/git/ignore"
if [[ ! -e "${gitignore_global}" ]]; then
	set +e
	gitignore_global="$(git config --get core.excludesfile)"
	set -e
fi
if [[ -n "${gitignore_global}" ]]; then
	git_exclude="$(git rev-parse --git-path info/exclude)"
	cat "${gitignore_global}" >> "${git_exclude}"
fi
## Enable to commit inside a container without 'Dev Containers'
git config --local user.name "${github_user}"
git config --local user.email "$(git config --get user.email)"
## Set up 'commit message template'
git config --local commit.template ./.github/commit/gitmessage.txt

# Reflect project name
set +u
if [[ -z "${project_name}" ]]; then
	echo -n 'What is your project named? > '
	read -r project_name
fi
set -u
echo "Reflecting your project name (${project_name})..."
grep -lr 'myapp-backend' . \
	| LC_ALL=C xargs sed -i '' "s/myapp-backend/${project_name}/g"

# Copy template files
echo 'Copying template files...'
cd ./Docker/api/environment
cp ./github-credentials.env.template ./github-credentials.env
cd ../../db/environment
cp ./mysql.env.template ./mysql.env
cd ../../../
printf '\x1b[1m%s\e[m\n' 'Overwrite the following files!'
cat <<-EOF
	Docker/api/environment/github-credentials.env
	Docker/db/environment/mysql.env
EOF

rm ./setup/scripts/prepare-create-pj.sh

echo 'Done!!'
