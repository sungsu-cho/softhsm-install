#!/bin/bash
OS_TYPE=`uname -s | tr A-Z a-z | sed 's/-.*//g'`
if [ $OS_TYPE != "linux" ]
then
    echo "Only Support LINUX"
    exit;
fi

function INSTALL_CENTOS {
yum -y install git
yum -y install automake autoconf libtool make gcc-c++
yum -y install openssl-devel 
# install xxd
yum -y install vim

if [ ! -d SoftHSMv2 ] ; then
    git clone https://github.com/opendnssec/SoftHSMv2
    cd SoftHSMv2 && sh autogen.sh && ./configure && make && make install
fi

}

function INSTALL_UBUNTU {
    apt -y install vim softhsm2 libengine-pkcs11-openssl openssl
}

OS_NAME=`cat /etc/*release* |grep ^NAME= |tr A-Z a-z | sed 's/"/ /g'|awk '{print $2}'`
if [ $OS_NAME = "centos" ]
then
    INSTALL_CENTOS
elif [ $OS_NAME = "ubuntu" ]
then
    INSTALL_UBUNTU
fi

echo
echo -n "softhsm version : "
softhsm2-util --version


#dynamic_path = /usr/lib64/engines-1.1/pkcs11.so
#MODULE_PATH = /usr/local/lib/softhsm/libsofthsm2.so
