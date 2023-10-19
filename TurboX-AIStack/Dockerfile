# 指明构建的新镜像的基础镜像
FROM public.ecr.aws/k5o4b3u5/thundercomm/turbox-sdkmanager-18.04:v1.0.0
 
# 通过镜像标签声明了作者信息
LABEL maintainer="xuemei.sun@thundercomm.com"
 
# 设置工作目录
#WORKDIR /usr/local
 
# 新镜像构建成功以后创建指定目录
#RUN  meta_dir=`pwd`
RUN  apt-get install -y software-properties-common && apt-get update -y &&  apt-get install -y openjdk-8-jdk
RUN echo "[safe]" >> /etc/skel/.gitconfig && echo "    directory = *" >>/etc/skel/.gitconfig && echo "turbox  ALL=(ALL:ALL)   NOPASSWD: ALL" >> /etc/sudoers
RUN sed -i "s/docker_version=sdkmanager-18.04-1.0.0/docker_version=sdkmanager-18.04-1.1.0/g" /etc/skel/.bashrc

COPY tools/usr/bin/* /usr/bin/ 

#====== v1.2.0 docker images==========
RUN pip3 install requests && apt-get update -y && apt-get install texinfo chrpath gcc-aarch64-linux-gnu libarchive-dev ssh libselinux1-dev fakechroot g++-aarch64-linux-gnu libiberty-dev qemu-user-static g++ gawk gcc make fakeroot diffstat libxml-simple-perl docbook2x zlib1g-dev libpam0g-dev libwayland-dev libwayland-bin -y && rm -rf /lib/ld-linux-aarch64.so.1 && ln -sf /usr/aarch64-linux-gnu/lib/ld-2.27.so /lib/ld-linux-aarch64.so.1 && ln -sf /bin/bash /bin/sh && cpan XML::LibXML::SAX 

RUN apt-get install bash-completion -y -q && /bin/bash -c "source /usr/share/bash-completion/bash_completion"

RUN sed -i "s%cp  /etc/skel/.gitconfig /home/turbox%#cp  /etc/skel/.gitconfig /home/turbox%g" /bin/create-user.sh && sed -i "s%chown -R turbox:turbox /home/turbox/.gitconfig%#chown -R turbox:turbox /home/turbox/.gitconfig%g" /bin/create-user.sh
RUN sed -i '$a su - turbox <<EOF \n\
if [ ! -d "/home/turbox/workspace/.sdkmanager.config/" ];then \n\
    mkdir  /home/turbox/workspace/.sdkmanager.config/ \n\
    if [ $? -ne 0 ];then \n\
            echo mkdir /home/turbox/workspace/.sdkmanager.config failed \n\
            exit 1 \n\
    fi \n\
    cp  /etc/skel/.gitconfig /home/turbox/workspace/.sdkmanager.config \n\
    chown -R turbox:turbox /home/turbox/workspace/.sdkmanager.config/.gitconfig \n\
    ln -s /home/turbox/workspace/.sdkmanager.config/.gitconfig /home/turbox/.gitconfig \n\
    touch /home/turbox/workspace/.sdkmanager.config/.netrc \n\
    ln -s /home/turbox/workspace/.sdkmanager.config/.netrc /home/turbox/.netrc \n\
else \n\
    if [ ! -f /home/turbox/.gitconfig ];then \n\
        ln -s /home/turbox/workspace/.sdkmanager.config/.gitconfig /home/turbox/.gitconfig \n\
    fi  \n\
    if [ ! -f /home/turbox/.netrc ];then \n\ 
        ln -s /home/turbox/workspace/.sdkmanager.config/.netrc /home/turbox/.netrc \n\
    fi \n\
fi \n\
EOF'  /bin/create-user.sh
