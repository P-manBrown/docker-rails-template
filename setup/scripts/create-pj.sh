#!/bin/bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ ! -e /.dockerenv ]]; then
	err 'This file must be run inside the container.'
	exit 1
fi

SETTINGS_DIR='./setup/settings'
PROJECT_NAME="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -d '=' -f 2)"

# creating project
echo 'Creating your project...'
rails new . --force --database=mysql --api

# installing gems
echo 'Installing gems...'
cp ./Gemfile /tmp/Gemfile
trap "find /tmp -maxdepth 1 -type f | xargs rm" EXIT
## dotenv
bundle add dotenv-rails \
	--group 'development, test' \
	--skip-install
## fuctory_bot
bundle add factory_bot_rails \
	--group 'development, test' \
	--skip-install
## Guard
bundle add guard \
	--group 'development' \
	--skip-install
bundle add guard-rspec \
	--group 'development' \
	--require 'false' \
	--skip-install
## Lefthook
bundle add lefthook \
	--group 'development' \
	--require 'false' \
	--skip-install
## Markdownlint
bundle add mdl \
	--group 'development' \
	--require 'false' \
	--skip-install
## Rack CORS Middleware
bundle add rack-cors \
	--skip-install
## RSpec
bundle add rspec-rails \
	--version '~> 6.0.0' \
	--group 'development, test' \
	--skip-install
## Rubocop
bundle add rubocop rubocop-performance rubocop-rails rubocop-rspec \
	--group 'development' \
	--require 'false' \
	--skip-install
## my_git-lint
sed -i "/group :development do/r ${SETTINGS_DIR}/gh-pkg-gem-decls" /tmp/Gemfile
## editing gem declarations in Gemfile
added_gem_decls="$(
	diff --old-line-format='' --unchanged-line-format='' /tmp/Gemfile ./Gemfile \
		| sed /^$/d \
		| tac
)"
if echo ${added_gem_decls} | grep -q ':group => :test'; then
	cat <<-EOF >> /tmp/Gemfile
		group :test do
		end
	EOF
fi
while read added_gem_decl; do
	decl_no_group="$(
		echo "${added_gem_decl}" \
			| sed -r 's/, :groups? => \[?:.*t]?//; s/:require =>/require:/'
	)"
	if [[ "${added_gem_decl}" =~ '[:development, :test]' ]]; then
		sed -i "/group :development, :test do/a \  ${decl_no_group}\n" /tmp/Gemfile
	elif [[ "${added_gem_decl}" =~ ':development' ]]; then
		sed -i "/group :development do/a \  ${decl_no_group}\n" /tmp/Gemfile
	elif [[ "${added_gem_decl}" =~ ':test' ]]; then
		sed -i "/group :test do/a \  ${decl_no_group}\n" /tmp/Gemfile
	else
		sed -i "/group :development, :test do/i ${decl_no_group}\n" /tmp/Gemfile
	fi
done < <(echo "${added_gem_decls}")
sed -r '/^(\s{2})?#/d;' /tmp/Gemfile | cat -s > ./Gemfile
printf '\x1b[1m%s\e[m\n' 'Check the contents of your Gemfile'
## installing gems via Gemfile
bundle install

# setting up project
echo 'Setting up your project...'
## setting up RSpec
rails generate rspec:install
## setting up time zone
cp ./config/application.rb /tmp/application.rb
rails_time_zone='config.time_zone = "Tokyo"'
sed -i "s/# config.time_zone.*/${rails_time_zone}/" /tmp/application.rb
sed -r '/^(\s{2})?#/d;' /tmp/Gemfile | cat -s > ./config/application.rb
## mv setting files
mv -f ${SETTINGS_DIR}/database.yml ./config/database.yml
mv -f ${SETTINGS_DIR}/puma.rb ./config/puma.rb
if [[ "${PROJECT_NAME}" =~ 'backend' ]]; then
	cp ./lefthook.yml /tmp/lefthook.yml
	sed -i \
		"/^commit-msg:$/e < ${SETTINGS_DIR}/lefthook/protect-branch.txt" \
		/tmp/lefthook.yml
	mv -f /tmp/lefthook.yml ./lefthook.yml
	cat ${SETTINGS_DIR}/lefthook/cleanup-branches.txt >> lefthook.yml
	cp ./.github/dependabot.yml /tmp/dependabot.yml
	sed -i 's/main/develop/' /tmp/dependabot.yml
	mv -f /tmp/dependabot.yml ./.github/dependabot.yml
	cat ${SETTINGS_DIR}/dependabot-bundler.txt >> ./.github/dependabot.yml
fi
rm -rf ${SETTINGS_DIR}

# adding gitignore patterns
cat <<-EOF >> ./.git/info/exclude
	/.vscode/setting.json
	/html_from_md
	.DS_Store
EOF

# If there are any changes in the main branch, move it to the develop branch.
current_branch="$(git branch --show-current)"
if [[ "${PROJECT_NAME}" =~ 'backend']] \
	&& [[ "${current_branch}" == 'main' ]]; then
		git stash push -q -u
		git checkout develop
		git stash pop -q
fi

echo 'Done!!'

rm -rf ./setup
