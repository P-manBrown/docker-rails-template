set -eu

ignore_path=/.vscode/launch.json
if ! cat ./.git/info/exclude | grep -q $ignore_path; then
	echo $ignore_path >> ./.git/info/exclude
fi
cp --update ./.devcontainer/vscode/launch.json ./.vscode
