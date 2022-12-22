#!/usr/bin/env bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ -e ./README.md ]]; then
	err 'Create ./README.md before running this file.'
	exit 1
fi

echo 'Running pre-commit...'
if [[ -e /.dockerenv ]]; then
	LEFTHOOK_EXCLUDE=protect-branch bundle exec lefthook run pre-commit
else
	LEFTHOOK_EXCLUDE=protect-branch lefthook run pre-commit
fi

rm -rf ./setup

echo 'Creating initial commit...'
git update-ref -d HEAD
git restore --staged .
git rm --cached .
git add .
(
	export LEFTHOOK=0
	git commit -m 'Initial commit'
	git push -f origin main
	git switch -c develop
	git push origin develop
)

project_name="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -d '=' -f 2)"
if [[ "${project_name}" =~ 'backend' ]]; then
	echo 'Setting up protected branches...'
	owner="$(git config user.name)"
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
