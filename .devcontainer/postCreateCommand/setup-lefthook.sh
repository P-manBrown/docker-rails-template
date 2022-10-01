set -eu

local_ignore_path=/lefthook-local.yml
if ! cat ./.git/info/exclude | grep -q $local_ignore_path; then
	echo $local_ignore_path >> ./.git/info/exclude
fi
cp --update ./.devcontainer/lefthook/lefthook-local.yml ./

bundle exec lefthook install
