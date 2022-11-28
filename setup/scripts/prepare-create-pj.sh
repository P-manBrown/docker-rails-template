#!/bin/bash
set -e

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [ -e /.dockerenv ]; then
	err 'This file must be run on the host.'
	exit 1
fi

if ! git branch | grep -q 'main' ; then
	err "Change the default branch to 'main'."
	exit 1
fi

if [ -z "${PROJECT_NAME}" ]; then
	echo -n 'What is your project named? > '
	read PROJECT_NAME
fi

set -u

# Setting up Git/GitHub
GH_USER="$(git config user.name)"
REPO_NAME="$(basename -s .git $(git remote get-url origin))"
if [[ "${PROJECT_NAME}" =~ 'backend' ]]; then
echo 'Setting up GitHub...'
## checkout develop branch
	git checkout -b develop
## Protect main and develop branch
	repositoryId="$(
		gh api graphql \
			-f query='{repository(owner:"'${GH_USER}'",name:"'${REPO_NAME}'"){id}}' \
			-q .data.repository.id
	)"
	branches=(main develop)
	for branch in "${branches[@]}"
	do
		gh api graphql \
			-f query='
				mutation($repositoryId:ID!,$branch:String!,$requiredReviews:Int!) {
					createBranchProtectionRule(input: {
						repositoryId: $repositoryId
						pattern: $branch
						requiresApprovingReviews: true
						requiredApprovingReviewCount: $requiredReviews
						dismissesStaleReviews: true
						isAdminEnforced: true
					}) { clientMutationId }
				}' \
			-f repositoryId="${repositoryId}" \
			-f branch="${branch}" \
			-F requiredReviews=1
	done
## enable to automatically delete head branches
	gh repo edit ${GH_USER}/${REPO_NAME} --delete-branch-on-merge
fi
echo 'Setting up Git...'
## enable to commit inside a container without 'Dev Containers'
git config --local user.name "${GH_USER}"
git config --local user.email "$(git config user.email)"
# setting up 'commit message template'
git config --local commit.template ./.github/commit/gitmessage.txt

# Reflect project name
echo "Reflecting your project name(${PROJECT_NAME})..."
grep -lr 'test-backend' | xargs sed -i '' "s/test-backend/${PROJECT_NAME}/g"

# Create secret file
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

echo 'Done!!'

rm -f ./setup/scripts/prepare-create-pj.sh
