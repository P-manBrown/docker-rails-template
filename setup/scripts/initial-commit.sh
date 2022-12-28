#!/usr/bin/env bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if ! ps -p "$$" | grep -q 'bash'; then
	err 'This file must be run with Bash.'
	exit 1
fi

if [[ ! -e ./README.md ]]; then
	err 'Create ./README.md before running this file.'
	exit 1
fi

echo 'Running pre-commit...'
git add .
if [[ -e /.dockerenv ]]; then
	LEFTHOOK_EXCLUDE=protect-branch bundle exec lefthook run pre-commit
else
	LEFTHOOK_EXCLUDE=protect-branch lefthook run pre-commit
fi

rm -rf ./setup

echo 'Creating initial commit...'
git restore --staged .
git rm -r --cached .
git update-ref -d HEAD
git add .
(
	export LEFTHOOK=0
	git commit -m 'Initial commit'
	git push -f origin main
)

project_name="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -d '=' -f 2)"
if [[ "${project_name}" == *'backend'* ]]; then
	echo 'Creating develop branch...'
	git switch -c develop
	LEFTHOOK=0 git push origin develop
	echo 'Setting up protected branches...'
	owner="$(git config --get user.name)"
	repo="$(basename -s .git "$(git remote get-url origin)")"
	repositoryId="$(
		gh api graphql \
			-f query='{repository(owner:"'${owner}'",name:"'${repo}'"){id}}' \
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
fi

echo 'Done!!'
