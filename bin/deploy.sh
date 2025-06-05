#!/bin/bash

export LC_ALL=C
set -u

my_name=${0##*/}
my_path=$(readlink -f "$0")
my_real_name=${my_path##*/}
bin_dir=${my_path%/*}
top_dir=${bin_dir%/*}

# be careful folder change
cd "$top_dir"

if [ "$my_name" = "$my_real_name" ]; then
    echo "Do not execute this script directy, use symlinks in rsync folder" >&2
    exit 1
fi

case "$my_name" in
  deploy-jdc-dev)
    ssh_server_host="h5p-jdc.numericlasse.fr"
    ssh_user="root"
    ssh_port="208"
    dst_dir="/var/www/${ssh_server_host}/wp-content/plugins/quiz-master-next"
  ;;
esac

if [ "$my_name" = "$my_real_name" ]; then
    echo "Ce script ne doit pas être appelé directement mais via un lien symbolique situé dans le répertoire rsync" >&2
    exit 1
fi

rsync_cmd=(
  rsync
  --rsh="ssh -p $ssh_port" --compress
  -rltD --hard-links
  --super --owner --group --chown=root:www-data
  --perms --chmod=Du=rwx,Dg=rx,Do=,Fu=rw,Fg=r,Fo=
  --verbose
  --force
  #--delete-after
)


echo "Data synchronization starts"
"${rsync_cmd[@]}" \
  --exclude '.git*' \
  --include /bin/postdeploy.sh \
  --exclude /bin/'*' \
  \
  . \
  "${ssh_user}@${ssh_server_host}:${dst_dir}/"

echo "Data synchronization finished"
postdeploy_script_path="$dst_dir/bin/postdeploy.sh"
echo "Post install script starts"
ssh -p "$ssh_port" "$ssh_user@${ssh_server_host}" "bash '$postdeploy_script_path'"
echo "Post install script finished"
