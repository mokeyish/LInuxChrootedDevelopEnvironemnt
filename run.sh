#!/bin/bash

###################################################################
#Script Name    : run                                                                                           
#Description    : A script to run a Linux chrooted develop environement.                                                                              
#Args           :                                                                                           
#Author         : YISH                                                
#Email          : mokeyish@hotmail.com                                           
###################################################################

user=${1:-$USER}

dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

display=$DISPLAY

function init() {
  user=${1:-$USER}
  dir=$2
  display=$3

  echo "Enter Linux Dev Environments"

  cd $dir

  # begin dev
  if [ ! -d dev ]; then
    mkdir dev
  fi
  if [ ! -r dev/console ] ; then
    mknod dev/console c 5 1
    chmod 640 dev/console
  fi
  if [ ! -r dev/full ]; then
    mknod dev/full c 1 7
    chmod 666 dev/full
  fi
  if [ ! -r dev/null ]; then
    mknod dev/null c 1 3
    chmod 666 dev/null
  fi
  if [ ! -r dev/random ]; then
    mknod dev/random c 1 8
    chmod 666 dev/random
  fi
  if [ ! -r dev/tty ]; then
    mknod dev/tty c 5 0
    chmod 666 dev/tty
    chgrp tty dev/tty
  fi
  if [ ! -r dev/urandom ]; then
    mknod dev/urandom c 1 9
    chmod 666 dev/urandom
  fi
  if [ ! -r dev/zero ]; then
    mknod dev/zero c 1 5
    chmod 666 dev/zero
  fi
  if [ ! -r dev/core ]; then
    ln -s /proc/kcore dev/core
  fi
  if [ ! -r dev/fd ]; then
    ln -s /proc/self/fd dev/fd
  fi
  if [ ! -r dev/stderr ]; then
    ln -s /proc/self/fd/2 dev/stderr
  fi
  if [ ! -r dev/stdin ]; then
    ln -s /proc/self/fd/0 dev/stdin
  fi
  if [ ! -r dev/stdout ]; then
    ln -s /proc/self/fd/1 dev/stdout
  fi
  
  
  # end dev

  if ! id $user >/dev/null 2>&1; then
    echo "User '$user' does not exist, use root user instead."
    user=root
  fi

  echo "USER: $user"
  home_dir=$(sudo -u $user sh -c 'echo $HOME')

  if ! grep -q $user: etc/passwd; then
    getent passwd yish >> etc/passwd
  fi
  if ! grep -q $user: etc/group; then
    getent group yish >> etc/group
  fi

  if [ ! -d .$home_dir ]; then
    mkdir -p .$home_dir
    chown `id $user -u`:`id $user -g` .$home_dir
    chmod 755 .$home_dir
  fi

  
  if [ -f mount_dirs ]; then
    mount_dirs=`cat mount_dirs`
  fi


  # exit 0

  mounted_dirs=""
  for mount_dir in $mount_dirs
  do
    if [ -d $home_dir/$mount_dir ]; then
      mkdir -p .$home_dir/$mount_dir
      mount --bind $home_dir/$mount_dir .$home_dir/$mount_dir
      mounted_dirs="$mounted_dirs $mount_dir"
    fi
  done
  
  [[ $mounted_dirs != "" ]] && echo "mount dirs: $mounted_dirs"


  mount -t proc /proc proc/
  mount -t sysfs /sys sys/

  if grep -q "ID=debian" etc/os-release; then
    chroot $dir /usr/bin/env -i DISPLAY="$display"  TERM=xterm-256color /bin/su -w DISPLAY  - $user || true
  elif grep -q "ID=alpine" etc/os-release; then
    chroot $dir /bin/busybox env -i DISPLAY="$display" TERM=xterm-256color /bin/su  - $user || true
  else
    echo "Not implelemented"
  fi
  
  umount proc/
  umount sys/

  for mounted_dir in $mounted_dirs
  do
    umount .$home_dir/$mounted_dir
  done

  [[ $mounted_dirs != "" ]] && echo "umount dirs: $mounted_dirs"

  echo "Exit Linux Dev Environments"
  
}

sudo bash -c "$(declare -f init); init $user $dir $display"
