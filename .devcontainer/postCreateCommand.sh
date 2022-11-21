set -eux

# setup Bundler
GITHUB_PKG_CRED_PATH='./.docker/api/secrets/github-pkg-cred.txt'
GITHUB_PKG_CRED=$(cat "$GITHUB_PKG_CRED_PATH")
bundle config https://rubygems.pkg.github.com/P-manBrown "$GITHUB_PKG_CRED"

# setup GitHub CLI
GITHUB_PAT=$(cut -f 2 -d ':' "$GITHUB_PKG_CRED_PATH")
echo "$GITHUB_PAT" | gh auth login --with-token

copy_and_ignore() {
	source_file="$1"
	target_dir="$2"
	file_name=$(basename "$source_file")
	ignore_path=$(
		echo "$target_dir/$file_name" \
		| sed -e "s:^./:/:; /^[^/]/s:^:/:; /\/\//s:^//:/:"
	)
	if ! grep -qx "$ignore_path" ./.git/info/exclude | ; then
		echo "$ignore_path" >> ./.git/info/exclude
	fi
	cp --update "$source_file" "$target_dir"
}

# setup VSCode
copy_and_ignore ./.devcontainer/vscode/launch.json ./.vscode

# setup Lefthook
copy_and_ignore ./.devcontainer/lefthook/lefthook-local.yml ./
bundle exec lefthook install

# setup Solargraph
mkdir -p ./config
copy_and_ignore ./.devcontainer/solargraph/.solargraph.yml ./
copy_and_ignore ./.devcontainer/solargraph/solargraph.rb ./config
for i in {1..5}
do
	yard gems -quiet && break
done
