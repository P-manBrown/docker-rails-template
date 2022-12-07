#!/bin/bash
set -eu

CONTAINER_USER="$(whoami)"

add_gitignore_pattern() {
	local ignore_pattern="$1"
	if ! grep -qx "${ignore_pattern}" ./.git/info/exclude; then
		echo "${ignore_pattern}" >> ./.git/info/exclude
	fi
}

echo 'Setting up Shell...'
cat <<-'EOF' | tee -a "${HOME}/.bashrc" >> "${HOME}/.zshrc"
	precmd() {
	  if [[ "$(history 1)" =~ ^.*bundle( +((install|-+).*$)| *$) ]]; then
	    echo 'Running `yard gems` to generate docs for gems...'
	    for i in {1..3}; do
	      yard gems -quiet && break
	    done
	  fi
	}
	export SHELL="$(readlink "/proc/$$/exe")"
	export HISTFILE="${HOME}/shell_log/.${SHELL##*/}_history"
	if [ "${SHLVL}" -eq 2 ]; then
	  create_date="$(date '+%Y%m%d%H%M%S')"
	  mkdir -p "${HOME}/shell_log/${SHELL##*/}"
	  script --flush "${HOME}/shell_log/${SHELL##*/}/${create_date}.log"
	fi
EOF
echo "export PROMPT_COMMAND='history -a && precmd'" >> "${HOME}/.bashrc"
git clone \
	https://github.com/zsh-users/zsh-autosuggestions \
	"${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
oh_my_plugins="(bundler gh git rails zsh-autosuggestions)"
sed -i "s/^plugins=(.*)/plugins=${oh_my_plugins}/" "${HOME}/.zshrc"
sudo chown -R "${CONTAINER_USER}" "${HOME}/shell_log"

echo 'Setting up Git...'
git config --global core.editor 'code --wait'
git config --local commit.template ./.github/commit/gitmessage.txt

echo 'Setting up GitHub CLI...'
gh config set editor 'code --wait'

echo 'Setting up VSCode...'
add_gitignore_pattern /.vscode/launch.json
cp -u ./.devcontainer/vscode/launch.json ./.vscode/launch.json

echo 'Setting up Lefthook...'
add_gitignore_pattern /lefthook-local.yml
cp -u ./.devcontainer/lefthook/lefthook-local.yml ./lefthook-local.yml
bundle exec lefthook install

echo 'Setting up Solargraph...'
gem install solargraph-rails
solargraph download-core
mkdir -p ./config
add_gitignore_pattern /.solargraph.yml
cp -u ./.devcontainer/solargraph/.solargraph.yml ./.solargraph.yml
add_gitignore_pattern /config/solargraph.rb
cp -u ./.devcontainer/solargraph/solargraph.rb ./config/solargraph.rb
sudo chown -R "${CONTAINER_USER}" "${HOME}/.yard"
for i in {1..3}; do
	yard gems -quiet && break
done
