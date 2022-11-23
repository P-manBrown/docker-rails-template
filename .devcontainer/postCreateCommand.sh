set -eu

echo 'Setting up Git...'
git config --global core.editor 'code --wait'
git config --local commit.template ./.github/commit/gitmessage.txt

echo 'Setting up GitHub CLI...'
gh config set editor 'code --wait'

copy_and_ignore() {
	source_file="$1"
	target_dir="$2"
	file_name=$(basename "$source_file")
	ignore_path=$(
		echo "$target_dir/$file_name" \
		| sed -e "s:^./:/:; /^[^/]/s:^:/:; /\/\//s:^//:/:"
	)
	if ! grep -qx "$ignore_path" ./.git/info/exclude ; then
		echo "$ignore_path" >> ./.git/info/exclude
	fi
	cp --update "$source_file" "$target_dir"
}

echo 'Setting up VSCode...'
copy_and_ignore ./.devcontainer/vscode/launch.json ./.vscode

echo 'Setting up Lefthook...'
copy_and_ignore ./.devcontainer/lefthook/lefthook-local.yml ./
bundle exec lefthook install

echo 'Setting up Solargraph...'
mkdir -p ./config
copy_and_ignore ./.devcontainer/solargraph/.solargraph.yml ./
copy_and_ignore ./.devcontainer/solargraph/solargraph.rb ./config
for i in {1..3}
do
	yard gems -quiet && break
done
