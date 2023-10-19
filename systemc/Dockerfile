#Dockerfile for building risc on centos
#Author: Vivek Govindasamy 9/1/2021
#Author: Zhongqi Cheng 9/27/2019
#Author: Daniel Mendoza 5/16/2018
FROM centos:7.8.2003

############################
#Setup Environment Variables
############################
ENV RISC_VERSION=risc_v0.6.3

ENV RISC_LINK=http://www.cecs.uci.edu/~doemer/risc/v063/$RISC_VERSION.tar.gz

ENV TOP=/local/lecs/lecs/$RISC_VERSION/top

ENV RISC_HOME=$TOP/$RISC_VERSION
	
ENV RISC_PKG=$RISC_HOME/pkg

ENV SOURCES=/local/lecs/lecs/$RISC_VERSION/sources

ENV RISC_DOWNLOAD=$SOURCES/download \
	RISC_BUILD=$SOURCES/build

ENV BOOST_HOME=$RISC_PKG/boost_1_61_0 \
	ROSE_HOME=$RISC_PKG/edg4x-rose \
	SYSTEMC_HOME=$RISC_PKG/systemc-2.3.1_pt

ENV BOOST_TARGET=$BOOST_HOME/include/boost/version.hpp \
	ROSE_TARGET=$ROSE_HOME/lib/librose.so \
	SYSTEMC_TARGET=$SYSTEMC_HOME/include/systemc.h

ENV RISC_TARGET=$RISC_HOME/bin/risc \
	SYSTEMC_LW_HOME=$RISC_PKG/systemc-2.3.1_lw \
	SYSTEMC_OOP_HOME=$RISC_PKG/systemc-2.3.1_oop \
	SYSTEMC_MIC_HOME=$RISC_PKG/systemc-2.3.1_mic


#####################################
#Create RISC Installation Directories
#####################################
RUN mkdir -p $RISC_DOWNLOAD && \
	mkdir -p $RISC_BUILD && \
	mkdir -p $RISC_HOME && \
	mkdir -p $RISC_PKG && \
	yum install SDL SDL-devel -y && \
	yum install epel-release -y && \
	yum install python36 python36-pip -y && \
	pip3 install --user graphviz && \
	yum install -y python36-gobject python36-beautifulsoup4 python36-pygraphviz
	#yum install python3-devel boost-python36 -y && \


#######################################################
#Download and Install Boost_1_47_0 and its dependencies
#######################################################
RUN yum install wget -y

RUN cd $RISC_DOWNLOAD && \
	rm -f boost_1_61_0.tar.gz && \
	wget -nv http://downloads.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.tar.gz

RUN yum install gcc gcc-c++ -y

RUN cd $RISC_BUILD && \
	tar xvzf ../download/boost_1_61_0.tar.gz && \
	cd $RISC_BUILD/boost_1_61_0 && \
	./bootstrap.sh --prefix=$BOOST_HOME \
		--with-libraries=chrono,date_time,filesystem,iostreams,program_options,random,regex,signals,system,thread,wave && \
	cd $RISC_BUILD/boost_1_61_0 && \
	./b2 -prefix=$BOOST_HOME -sNO_BZIP2=1 install


##################################
#Install ROSE and its dependencies
##################################
RUN yum install git -y && \
	yum install autoconf automake -y && \
	yum groupinstall "Development Tools" -y && \
	yum install tar which -y && \
	yum install gtk3 -y && \
	yum install libcanberra-gtk2 -y 

RUN cd $TOP && \
	wget -nv http://ftp.gnu.org/gnu/libtool/libtool-2.4.tar.gz && \
	tar xvzf libtool-2.4.tar.gz && \
	cd $TOP/libtool-2.4 && \
	./configure && \
	make && \
	make install

RUN yum install flex bison byacc -y && \
	yum install ghostscript -y

RUN cd $RISC_DOWNLOAD && \
	git clone https://github.com/rose-compiler/rose.git edg4x-rose && \
	cd $RISC_DOWNLOAD/edg4x-rose && \
	git checkout 88e95f3ef8891e4d43f395f866a54182f771531e && \
	cd $RISC_DOWNLOAD/edg4x-rose && \
	./build && \
	mkdir -p $RISC_BUILD/edg4x-rose && \
	cd $RISC_BUILD/edg4x-rose && \
	LD_LIBRARY_PATH=$BOOST_HOME/lib $RISC_DOWNLOAD/edg4x-rose/configure \
		--prefix=$ROSE_HOME --with-boost=$BOOST_HOME \
		--without-java --enable-languages=c,c++ \
		--with-C_OPTIMIZE=-O2 --with-CXX_OPTIMIZE=-O2 --with-C_DEBUG=-DNDEBUG --with-CXX_DEBUG=-DNDEBUG && \
	cd $RISC_BUILD/edg4x-rose && \
	LD_LIBRARY_PATH=$BOOST_HOME/lib make -j4 && \
	cd $RISC_BUILD/edg4x-rose && \
	LD_LIBRARY_PATH=$BOOST_HOME/lib make install-rose-library


######################
#Install Systemc-2.3.1
######################
RUN cd $RISC_DOWNLOAD && \
	rm -f systemc-2.3.1.tgz && \
	wget -nv http://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.1.tgz && \
	cd $RISC_BUILD && \
	tar xvzf $RISC_DOWNLOAD/systemc-2.3.1.tgz && \
	mkdir -p $RISC_BUILD/systemc-2.3.1/objdir && \
	cd $RISC_BUILD/systemc-2.3.1/objdir && \
	CXX=g++ ../configure --prefix=$RISC_PKG/systemc-2.3.1 && \
	make -C $RISC_BUILD/systemc-2.3.1/objdir all && \
	make -C $RISC_BUILD/systemc-2.3.1/objdir install && \
	make -C $RISC_BUILD/systemc-2.3.1/objdir check && \
	mkdir -p $RISC_BUILD/systemc-2.3.1/objdir_pt && \
	cd $RISC_BUILD/systemc-2.3.1/objdir_pt && \
	CXX=g++ ../configure --prefix=$SYSTEMC_HOME --enable-pthreads && \
	make -C $RISC_BUILD/systemc-2.3.1/objdir_pt all && \
	make -C $RISC_BUILD/systemc-2.3.1/objdir_pt install && \
	make -C $RISC_BUILD/systemc-2.3.1/objdir_pt check


##############################################
#Install RISC and the rest of its dependencies
##############################################
RUN yum install patch -y && \
	yum install doxygen -y && \
	yum install man -y && \
	yum install gtk2-devel -y && \
	yum install time -y

RUN cd $RISC_DOWNLOAD && \
	rm -f $RISC_VERSION.tar.gz && \
	wget -nv $RISC_LINK && \
	cd $RISC_BUILD && \
	tar xvzf $RISC_DOWNLOAD/$RISC_VERSION.tar.gz && \
	cd $RISC_BUILD/$RISC_VERSION && \
		mv -f source_me.csh source_me.csh.bak && \
		echo > source_me.csh "# source_me.csh: generated by dockerfile build" && \
		echo >> source_me.csh "setenv RISC_HOME $RISC_HOME" && \
		echo >> source_me.csh "setenv RISC_BUILD $RISC_BUILD" && \
		echo >> source_me.csh "setenv RISC_DOWNLOAD $RISC_DOWNLOAD" && \
		echo >> source_me.csh "setenv ROSE_HOME $ROSE_HOME" && \
		echo >> source_me.csh "setenv BOOST_HOME $BOOST_HOME" && \
		echo >> source_me.csh "setenv SYSTEMC_HOME $SYSTEMC_HOME" && \
		echo >> source_me.csh "setenv SYSTEMC_LW_HOME $SYSTEMC_LW_HOME" && \
		echo >> source_me.csh "setenv SYSTEMC_OOP_HOME $SYSTEMC_OOP_HOME" && \
		echo >> source_me.csh "setenv SYSTEMC_MIC_HOME $SYSTEMC_MIC_HOME" && \
		echo >> source_me.csh 'if ( $?LD_LIBRARY_PATH ) then' && \
		echo >> source_me.csh '  setenv LD_LIBRARY_PATH ${RISC_HOME}/lib:${BOOST_HOME}/lib:${SYSTEMC_HOME}/lib-linux64:${LD_LIBRARY_PATH}' && \
		echo >> source_me.csh 'else' && \
		echo >> source_me.csh '  setenv LD_LIBRARY_PATH ${RISC_HOME}/lib:${ROSE_HOME}/lib:${BOOST_HOME}/lib:${SYSTEMC_HOME}/lib-linux64' && \
		echo >> source_me.csh 'endif' && \
	cd $RISC_BUILD/$RISC_VERSION && \
		mv -f source_me.sh source_me.bak && \
		echo > source_me.sh "# source_me.sh: generated by dockerfile build" && \
		echo >> source_me.sh "export RISC_HOME=$RISC_HOME" && \
		echo >> source_me.sh "export RISC_BUILD=$RISC_BUILD" && \
		echo >> source_me.sh "export RISC_DOWNLOAD=$RISC_DOWNLOAD" && \
		echo >> source_me.sh "export ROSE_HOME=$ROSE_HOME" && \
		echo >> source_me.sh "export BOOST_HOME=$BOOST_HOME" && \
		echo >> source_me.sh "export SYSTEMC_HOME=$SYSTEMC_HOME" && \
		echo >> source_me.sh "export SYSTEMC_LW_HOME=$SYSTEMC_LW_HOME" && \
		echo >> source_me.sh "export SYSTEMC_OOP_HOME=$SYSTEMC_OOP_HOME" && \
		echo >> source_me.sh "export SYSTEMC_MIC_HOME=$SYSTEMC_MIC_HOME" && \
		echo >> source_me.sh 'export LD_LIBRARY_PATH=${RISC_HOME}/lib:${ROSE_HOME}/lib:${BOOST_HOME}/lib:${SYSTEMC_HOME}/lib-linux64${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH}' && \
	source $RISC_BUILD/$RISC_VERSION/source_me.sh && \
	make "\"DEBUG=-O2 -DNDEBUG\"" -C $RISC_BUILD/$RISC_VERSION clean && \
	make "\"DEBUG=-O2 -DNDEBUG\"" -C $RISC_BUILD/$RISC_VERSION build && \
	make "\"DEBUG=-O2 -DNDEBUG\"" -C $RISC_BUILD/$RISC_VERSION install


#####################
#Setup demo directory
#####################
RUN source $RISC_BUILD/$RISC_VERSION/source_me.sh && \
	make "\"DEBUG=-O2 -DNDEBUG\"" -C $RISC_BUILD/$RISC_VERSION test && \
	mkdir -p /home/root/demodir && \
	cp $RISC_HOME/examples/demo/* /home/root/demodir && \
	rm -rf $SOURCES && \
	rm -rf /local/lib*

ENV LD_LIBRARY_PATH=$RISC_HOME/lib:${ROSE_HOME}/lib:$BOOST_HOME/lib:$SYSTEMC_HOME/lib-linux64 \
	MANPATH=$RISC_HOME/man \
	PATH=$RISC_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CMD cd /home/root && \ 
	bash
