#!/usr/bin/env bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ ! -e /.dockerenv ]]; then
	err 'This file must be run inside the container.'
	exit 1
fi

if ! ps -p "$$" | grep -q 'bash'; then
	err 'This file must be run with Bash.'
	exit 1
fi

CONFIG_DIR='./setup/config'
PROJECT_NAME="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -d '=' -f 2)"

# creating project
echo 'Creating your project...'
rails new . --api --database=mysql --force --skip-test

# adding file contents to the index
echo 'Adding file contents to the index...'
repo_root="$(git rev-parse --show-toplevel)"
git config --global --add safe.directory "${repo_root}"
git add .

# installing gems
echo 'Installing gems...'
cp ./Gemfile /tmp/Gemfile
trap "rm /tmp/Gemfile" EXIT
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
sed -i "/group :development do/r ${CONFIG_DIR}/gh-pkg-gem-decls" /tmp/Gemfile
## editing gem declarations in Gemfile
added_gem_decls="$(
	diff --old-line-format='' --unchanged-line-format='' /tmp/Gemfile ./Gemfile \
		| sed /^$/d \
		| tac
)"
if echo "${added_gem_decls}" | grep -q ':group => :test'; then
	cat <<-EOF >> /tmp/Gemfile
		group :test do
		end
	EOF
fi
while read -r added_gem_decl; do
	decl_no_group="$(
		echo "${added_gem_decl}" \
			| sed -r 's/, :groups? => \[?:.*t]?//; s/:require =>/require:/'
	)"
	if [[ "${added_gem_decl}" == *':development, :test'* ]]; then
		sed -i "/group :development, :test do/a \  ${decl_no_group}\n" /tmp/Gemfile
	elif [[ "${added_gem_decl}" == *':development'* ]]; then
		sed -i "/group :development do/a \  ${decl_no_group}\n" /tmp/Gemfile
	elif [[ "${added_gem_decl}" == *':test'* ]]; then
		sed -i "/group :test do/a \  ${decl_no_group}\n" /tmp/Gemfile
	else
		sed -i "/group :development, :test do/i ${decl_no_group}\n" /tmp/Gemfile
	fi
	current_gem="$(echo "${decl_no_group}" | cut -d '"' -f 2)"
	set +u
	if [[ -n "${current_gem}" ]] \
		&& [[ "${current_gem}" == "${previous_gem%%-*}"* ]]; then
			sed -i "/${decl_no_group}/{n;d}" /tmp/Gemfile
	fi
	set -u
	previous_gem="${current_gem}"
done < <(echo "${added_gem_decls}")
sed -r '/^(\s{2})?#/d' /tmp/Gemfile | cat -s > ./Gemfile
printf '\x1b[1m%s\e[m\n' 'Check the contents of your Gemfile'
## installing gems via Gemfile
bundle install

# setting up project
echo 'Setting up your project...'
## setting up RSpec
rails generate rspec:install
## setting up Lefthook
bundle exec lefthook install
post_create_command='.devcontainer/postCreateCommand.sh'
set +u
if [[ "${REMOTE_CONTAINERS}" == 'true' ]]; then
	echo '' >> "${post_create_command}"
	cat <<-EOF >> "${post_create_command}"
		echo 'Setting up Lefthook...'
		bundle exec lefthook install
	EOF
fi
set -u
## setting up Solargraph
set +u
if [[ "${REMOTE_CONTAINERS}" == 'true' ]]; then
	for _ in {1..3}; do
		yard gems -quiet && break
	done
	echo '' >> "${post_create_command}"
	cat <<-EOF >> "${post_create_command}"
		echo 'Setting up Solargraph...'
		for _ in {1..3}; do
			yard gems -quiet && break
		done
	EOF
fi
set -u
sed -i 's/^yard gems/\tyard gems/' "${post_create_command}"
## preparing configuration files
app_time_zone='config.time_zone = "Tokyo"'
sed -i "s/# config.time_zone.*/${app_time_zone}/" ./config/application.rb
mv -f "${CONFIG_DIR}/database.yml" ./config/database.yml
mv -f "${CONFIG_DIR}/puma.rb" ./config/puma.rb
if [[ "${PROJECT_NAME}" == *'backend'* ]]; then
	sed -i 's/main/develop/' ./.github/dependabot.yml
else
	sed -i '/protect-branch:$/,/fail_text:.*branch\."$/d' ./lefthook.yml
fi
rm -rf "${CONFIG_DIR}"

rm ./setup/scripts/create-pj.sh

echo 'Done!!'
