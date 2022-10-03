set -eux
export PS4="+[\D{%H:%M:%S}] ${BASH_SOURCE[0]##*/}:${LINENO}> "

file_list=(`ls ./.devcontainer/postCreateCommand/scripts/*`)

for f in "${file_list[@]}"
do
	bash "$f"
done
