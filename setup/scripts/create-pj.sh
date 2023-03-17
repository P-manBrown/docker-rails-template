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
cp -f ./Gemfile /tmp/Gemfile
## dotenv
bin/bundle add dotenv-rails \
	--group 'development, test' \
	--skip-install
## fuctory_bot
bin/bundle add factory_bot_rails \
	--group 'development, test' \
	--skip-install
## Guard
bin/bundle add guard \
	--group 'development' \
	--skip-install
bin/bundle add guard-rspec \
	--group 'development' \
	--require 'false' \
	--skip-install
## Lefthook
bin/bundle add lefthook \
	--group 'development' \
	--require 'false' \
	--skip-install
## Markdownlint
bin/bundle add mdl \
	--group 'development' \
	--require 'false' \
	--skip-install
## Rack CORS Middleware
bin/bundle add rack-cors \
	--skip-install
## Rails i18n
bin/bundle add rails-i18n \
	--skip-install
## RSpec
bin/bundle add rspec-rails \
	--group 'development, test' \
	--skip-install
## Rubocop
bin/bundle add rubocop rubocop-performance rubocop-rails rubocop-rspec \
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
bin/bundle install

# setting up project
echo 'Setting up your project...'
## adding files to be ignored by Git
echo '' >> ./.gitignore
cat <<-EOF >> ./.gitignore
	# Ignore local env files.
	.env*.local
EOF
## setting up RSpec
rails generate rspec:install
echo '--format documentation' >> ./.rspec
## setting up Lefthook
bin/bundle exec lefthook install
post_create_command='.devcontainer/postCreateCommand.sh'
set +u
if [[ "${REMOTE_CONTAINERS}" == 'true' ]]; then
	echo '' >> "${post_create_command}"
	cat <<-EOF >> "${post_create_command}"
		echo 'Setting up Lefthook...'
		bin/bundle exec lefthook install
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
cp -f "${post_create_command}" /tmp/postCreateCommand.sh
sed -i 's/^yard gems/\tyard gems/' /tmp/postCreateCommand.sh
cp -f /tmp/postCreateCommand.sh "${post_create_command}"
## preparing configuration files
app_time_zone='config.time_zone = "Tokyo"'
app_default_locale='config.i18n.default_locale = :ja'
cp -f ./config/application.rb /tmp/application.rb
sed -i "s/# config.time_zone.*/${app_time_zone}/" /tmp/application.rb
sed -i "/^end$/i \\\n  ${app_default_locale}" /tmp/application.rb
cp -f /tmp/application.rb ./config/application.rb
permitted_host='config.hosts << "host.docker.internal"'
cp -f ./config/environments/development.rb /tmp/development.rb
sed -i "/^end$/i \\\n  ${permitted_host}" /tmp/development.rb
cp -f /tmp/development.rb ./config/environments/development.rb
mv -f "${CONFIG_DIR}/database.yml" ./config/database.yml
mv -f "${CONFIG_DIR}/puma.rb" ./config/puma.rb

rm -rf "${CONFIG_DIR}"

rm ./setup/scripts/create-pj.sh

echo 'Done!!'
