#!/bin/bash
# Author: xuemei.sun<xuemei.sun@thundercomm.com>
# Date: 2023-05-15
# Copyright© 2023 Thundercomm Technology Co., Ltd. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary forms must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of The Linux Foundation nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Do not allow root execution.
if [ `id -u` -eq 0 ]; then
    echo -e "\033[1;31mDo not run this script with root privileges. Do not use 'sudo'.\033[0m"
    exit 1
fi

usage() {
echo -e "\033[1;37mUsage:\033[0m"
echo -e "    bash $0 [OPTIONS]"
echo -e ""
echo -e "\033[1;37mDescription:\033[0m"
echo -e "    Set up Thundercomm TurboX SOM SDK Manager."
echo -e ""
echo -e "\033[1;37mOPTIONS:\033[0m"
echo -e "    \033[1;37m-h, --help\033[0m       Display this help message"
echo -e "    \033[1;37m-u, --upgrade\033[0m    Upgrade the sdkmanager to the latest version"
echo -e "    \033[1;37m-v, --version\033[0m    Display the script version"
echo -e "    \033[1;37m-t, --tag\033[0m        Specify the version of sdkmanager(e.g. -t v1.0.0), default:'latest'"
echo -e "                     You can obtain the available versions from:"
echo -e "                     https://gallery.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-18.04"
echo -e "                     https://gallery.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-20.04"
echo -e "    \033[1;37m--os-version\033[0m     Specify the OS version that the sdkmanager is built based on"
echo -e "                     [--os-version 18.04]: Specify the sdkmanager built based on Ubuntu 18.04"
echo -e "                     [--os-version 20.04]: Specify the sdkmanager built based on Ubuntu 20.04"
echo -e "                     Default:'18.04'"
}

script_version=v4.0.0

uid=`id -u`
gid=`id -g`
os_ver="18.04"
repository="public.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-18.04"
tag="latest"
container_name_base="turbox-sdkmanager-18.04"
docker_version=""
workspace_dir=""


update_setup_versoin() {
    setup_realpath=`pwd`/$(dirname "$0")
    if [[ -d /tmp/sdkmanager-setup-version ]];then
        rm -rf /tmp/sdkmanager-setup-version 
    fi
    mkdir -p /tmp/sdkmanager-setup-version
    wget https://sdkgit.thundercomm.com/api/v4/projects/4649/repository/files/sdkmanager-setup-version.txt/raw?ref=main -O /tmp/sdkmanager-setup-version/sdkmanager-setup-version.txt
    wget https://sdkgit.thundercomm.com/api/v4/projects/4649/repository/files/turbox-sdkmanager-setup.sh/raw?ref=main -O /tmp/sdkmanager-setup-version/turbox-sdkmanager-setup.sh
    setup_latest_version=`cat /tmp/sdkmanager-setup-version/sdkmanager-setup-version.txt | awk 'NR == 2' | awk '{print $1}'`
    setup_force_update=`cat /tmp/sdkmanager-setup-version/sdkmanager-setup-version.txt | awk 'NR == 2' | awk '{print $2}'`
    if [ "$script_version" != "$setup_latest_version" ]; then
        if [ "$setup_force_update" == "true" ];then
            echo  -e "\033[1;31mA new version of the turbox-sdkmanager-setup.sh is available. Press any key to complete the update \033[0m"
	    read
	    cp -f /tmp/sdkmanager-setup-version/turbox-sdkmanager-setup.sh $setup_realpath
            rm -rf /tmp/sdkmanager-setup-version
	    echo  -e "\033[1;31mturbox-sdkmanager-setup.sh has been upgraded to version $setup_latest_version.\033[0m"
            echo  -e "\033[1;31mPlease run turbox-sdkmanager-setup.sh again\033[0m"
            exit 0
        else
            echo   -e "\033[1;31m A new version of the turbox-sdkmanager-setup.sh is available.  Update to version $setup_latest_version?(y/N)\033[0m"
            read user_update
            if [[ $(echo $user_update | tr '[:upper:]' '[:lower:]') == "y" || $(echo $user_update | tr '[:upper:]' '[:lower:]') == "yes"  ]];then
                cp -f /tmp/sdkmanager-setup-version/turbox-sdkmanager-setup.sh $setup_realpath
		rm -rf /tmp/sdkmanager-setup-version
		echo -e "\033[1;31mturbox-sdkmanager-setup.sh has been upgraded to version $setup_latest_version.\033[0m"
                echo -e "\033[1;31mPlease run turbox-sdkmanager-setup.sh again\033[0m"
                exit 0
            fi
        fi
    fi
}


assert() {
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo $1
        exit 1
    fi
}

update_workspace_dir() {
    if [ -f $HOME/.thundercomm/turbox-sdkmanager/workspace_dir ];then
        workspace_dir=`cat $HOME/.thundercomm/turbox-sdkmanager/workspace_dir`
    fi

    if [ "$workspace_dir"x = "x" ];then
        workspace_dir=$HOME/turbox-sdkmanager-ws
    else
        echo -e "\033[1;37mTarget storage directory of workspace: $workspace_dir, continue with this path[Y/n]?\033[0m"
        read use_stored_workspace_dir
    fi

    if [ "$use_stored_workspace_dir" != "Y" ];then

        echo -e ""
        echo -e "\033[1;32mInput an absolute target storage directory for your workspace (default: $workspace_dir).\033[0m"
        echo -e "\033[1;32mOwner of the target directory should be the current user.\033[0m"
        echo -e "\033[1;32mFree space of the target directory should be at least 1TB (for Android 12/13 SDK) / 300GB (for SDKs other than Android 12/13).\033[0m"
        echo -e "\033[1;32mDo not use any directory that has been used by other users on your PC.\033[0m"
        echo -e "[Input 'Enter' to select the default target directory or simply input an absolute path.]"

        while read workspace_dir_r
        do
            if [ "$workspace_dir_r"x = "x" ];then
                break
            elif [[ $workspace_dir_r =~ ^/.* ]];then
                workspace_dir=$workspace_dir_r
                break
            else
                echo -e "\033[1;37m You are not entering an absolute path. Please re-enter an absolute path or input 'Enter' to select the default target directory($workspace_dir):\033[0m"
            fi
        done

        if [ ! -d "$HOME/.thundercomm/turbox-sdkmanager" ];then
            mkdir -p $HOME/.thundercomm/turbox-sdkmanager
        fi

        echo $workspace_dir > $HOME/.thundercomm/turbox-sdkmanager/workspace_dir
    fi

    if [ ! -d "$workspace_dir" ];then
        set +e
        mkdir -p $workspace_dir
        set -e
        if [ ! -d "$workspace_dir" ];then
            echo "Creating $workspace_dir with root privilege..."
            sudo mkdir -p $workspace_dir
            sudo chown $uid:$gid $workspace_dir
        fi

        if [ ! -d "$workspace_dir" ];then
            echo "Failed to create workspace_dir."
            exit 1
        fi
    else
        if [ ! -O $workspace_dir ];then
            echo -e "\033[1;37mOwner of $workspace_dir is not the current user. Replace the owner of $workspace_dir with the current user[Y/n]?\033[0m"
            read change_workspace_dir_owner
            if [ "$change_workspace_dir_owner" = "Y" ];then
                sudo chown $uid:$gid -P $workspace_dir
            else
                echo -e "Please re-run this script and input a correct target directory for your workspace."
                exit 0
            fi
        fi
    fi
}

docker_run() {
    echo "sudo docker run --name ${container_name_base}_$1_${uid} -it -d -v $workspace_dir:/home/turbox/workspace -v /lib/modules:/lib/modules --privileged -v /dev/:/dev -v /run/udev:/run/udev $repository:$1 /bin/bash"
    sudo docker run --name ${container_name_base}_$1_${uid} -it -d -v $workspace_dir:/home/turbox/workspace -v /lib/modules:/lib/modules --privileged -v /dev/:/dev -v /run/udev:/run/udev $repository:$1 /bin/bash
}

get_version() {
    #$1:tag
    if [ $1 = 'latest' ];then
        image_version=`sudo docker history $repository:$1 |head -n 2 |tail -n 1 |awk -F :  '{print $1}' | awk '{print $NF}'`
    else
        image_version=`sudo docker history $1 | head -n 2 |tail -n 1 |awk -F :  '{print $1}' | awk '{print $NF}'`
    fi
    echo $image_version
}

tag_docker_images(){
    echo "Making a new tag for none docker image..."
    none_image_id=`sudo docker images | grep $repository  |grep none |awk '{print $3}'`
    if [ "$none_image_id"x = "x" ];then
        echo "No need to retag for docker image."
    else
        for i in $none_image_id; do
            old_docker_version=`get_version $i`
            echo "docker tag $i $repository:$old_docker_version"
            sudo docker tag $i $repository:$old_docker_version
        done
    fi
}

#========================================================================
long_opts="help,upgrade,version,tag:,os-version:"
getopt_cmd=$(getopt -o huvt: --long "$long_opts" \
            -n $(basename $0) -- "$@") || \
            { echo -e "\nERROR: Getopt failed. Extra args\n"; usage; exit 1;}
eval set -- "$getopt_cmd"

echo -e "\033[33m
******************************************************************
Welcome to $0 version $script_version
This script is used to set up Thundercomm TurboX SOM SDK Manager.

Thundercomm TurboX SOM SDK Manager is an all-in-one tool that
bundles developer software and provides an end-to-end development
environment solution for all TurboX SOM SDKs.

This script requires root privileges. Please enter the sudo password.

You can obtain the help information via $0 -h, or get more details from:
https://docs.thundercomm.com/turbox_doc/documents/common/tools/turbox-sdkmanager-user-guide
******************************************************************
\033[0m
"
while true; do
    case "$1" in
        -h|--help)     usage; exit 0;;
        -u|--upgrade)  rename=true; update_image=true;;
        -v|--version)  echo "$0 version is" $script_version; exit 0;;
        -t|--tag)      tag=$2; docker_version=$2; update_image=true;;
        --os-version)  os_ver=$2;;
        --)            break;;
    esac
    shift

    if [ "$1" = "" ]; then
        break
    fi
done

update_setup_versoin

#pull qemu-user-static
echo "install qemu-user-static"
sudo docker run --rm --privileged public.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-tools:register --reset > /dev/null

if [ "$os_ver" == "18.04" ];then
    echo "Docker image built based on Ubuntu 18.04 is selected"
elif [ "$os_ver" == "20.04" ];then
    echo "Docker image built based on Ubuntu 20.04 is selected"
    repository="public.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-20.04"
    container_name_base="turbox-sdkmanager-20.04"
else
    echo "Please input the correct os-version: ('--os-version 18.04','--os-version 20.04', default:'18.04')."
    exit 1
fi

docker_image=`sudo docker images |grep -w $repository`
if [ "$docker_image"x == "x" ];then
    update_image=true
fi

if [ "$update_image" = "true" ];then
    echo "Pulling docker image..."
    echo "docker pull  $repository:$tag"
    sudo docker pull  $repository:$tag
    if [ $? -ne 0 ];then
        if [ "$os_ver" == "18.04" ];then
            echo "Please enter the correct version number (e.g. -t v1.0.0). For available versions, go to: https://gallery.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-18.04"
        elif [ "$os_ver" == "20.04" ];then
            echo "Please enter the correct version number (e.g. -t v1.0.0). For available versions, go to: https://gallery.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-20.04"
        fi
        exit 1
    fi
fi

tag_docker_images

#get docker image version
if [ "$docker_version"x = "x" ];then
    docker_version=`get_version latest`
    echo "docker_version $docker_version"
fi

container_name=`sudo docker ps -a |awk '{print $NF}' |grep -w ${container_name_base}_${docker_version}_${uid}`
if [ "$container_name"x = 'x' ];then
    update_workspace_dir
    docker_run $docker_version
else
    echo "The container name "${container_name_base}_${docker_version}_${uid}" is already in use."
fi

echo "docker start ${container_name_base}_${docker_version}_${uid}"
sudo docker start ${container_name_base}_${docker_version}_${uid}

echo "docker exec -it ${container_name_base}_${docker_version}_${uid} /bin/create-user.sh $uid $gid"
sudo docker exec -it ${container_name_base}_${docker_version}_${uid}  /bin/create-user.sh $uid $gid

echo "docker exec -it -u $uid:$gid -w /home/turbox ${container_name_base}_${docker_version}_${uid}  /bin/bash"
sudo docker exec -it -u $uid:$gid -w /home/turbox ${container_name_base}_${docker_version}_${uid}  /bin/bash

