#!/bin/bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ -e /.dockerenv ]]; then
	err 'This file must be run on the host.'
	exit 1
fi

if ! git branch | grep -q 'main'; then
	err "Change the default branch to 'main'."
	exit 1
fi

# Setting up Git/GitHub
git update-ref -d HEAD
echo 'Setting up GitHub...'
## enable to automatically delete head branches
github_user="$(git config user.name)"
repo_name="$(basename -s .git $(git remote get-url origin))"
gh repo edit ${github_user}/${repo_name} --delete-branch-on-merge
echo 'Setting up Git...'
## enable to commit inside a container without 'Dev Containers'
git config --local user.name "${github_user}"
git config --local user.email "$(git config user.email)"
# setting up 'commit message template'
git config --local commit.template ./.github/commit/gitmessage.txt

# Reflect project name
set +u
if [[ -z "${project_name}" ]]; then
	echo -n 'What is your project named? > '
	read project_name
fi
set -u
echo "Reflecting your project name(${project_name})..."
grep -lr 'myapp-backend' | xargs sed -i '' "s/myapp-backend/${project_name}/g"

# Copying template files
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
