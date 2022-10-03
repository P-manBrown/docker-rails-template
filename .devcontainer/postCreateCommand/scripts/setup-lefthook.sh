set -eux

ignore_path=/lefthook-local.yml
if ! cat ./.git/info/exclude | grep -q $ignore_path; then
	echo $ignore_path >> ./.git/info/exclude
fi
cp --update ./.devcontainer/lefthook/lefthook-local.yml ./

bundle exec lefthook install
