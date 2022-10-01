set -eu

function copy_and_ignore() {
	file_path=$1
	target_dir=$2
	file_name=$(basename "$file_path")
	ignore_path=$(echo $target_dir$file_name | sed -e "s:^./:/:; /^[^/]/s:^:/:")
	if ! cat ./.git/info/exclude | grep -q $ignore_path; then
		echo -e "$ignore_path" >> ./.git/info/exclude
	fi
	cp --update $file_path $target_dir
}

mkdir -p ./config
copy_and_ignore ./.devcontainer/solargraph/.solargraph.yml ./
copy_and_ignore ./.devcontainer/solargraph/solargraph.rb ./config
