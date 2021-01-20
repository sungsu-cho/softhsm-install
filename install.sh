#!/bin/bash
OS_TYPE=`uname -s | tr A-Z a-z | sed 's/-.*//g'`
if [ $OS_TYPE != "linux" ]
then
    echo "Only Support LINUX"
    exit;
fi

if [ ! -d tokens ]; then
	mkdir tokens
fi

if [ ! -d conf ]; then
	mkdir conf
fi

OPENSSL_CONF=$PWD/conf/openssl.cnf
SOFTHSM2_CONF=$PWD/conf/softhsm2.conf

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

function GEN_OPENSSL_CONF {
echo "HOME = ." > $OPENSSL_CONF
echo "openssl_conf=conf_openssl" >> $OPENSSL_CONF
echo "" >> $OPENSSL_CONF 
echo "[ conf_openssl ]" >> $OPENSSL_CONF
echo "engines = engine_section" >> $OPENSSL_CONF
echo "" >> $OPENSSL_CONF 
echo "[ engine_section ]" >> $OPENSSL_CONF
echo "pkcs11 = engine_pkcs11" >> $OPENSSL_CONF
echo "" >> $OPENSSL_CONF 
echo "[ engine_pkcs11 ]" >> $OPENSSL_CONF
echo "engine_id = pkcs11" >> $OPENSSL_CONF

LIB_PKCS11=`find /usr -name libpkcs11.so|sed -n '1p'`
LIB_HSM2=`find / -name libsofthsm2.so|sed -n '1p'`
echo "dynamic_path=$LIB_PKCS11" >> $OPENSSL_CONF
echo "MODULE_PATH =$LIB_HSM2" >> $OPENSSL_CONF
}

function GEN_SOFTHSM_CONF {

echo "# SoftHSM v2 configuration file" > $SOFTHSM2_CONF
echo "directories.tokendir = $PWD/tokens/" >> $SOFTHSM2_CONF
echo "objectstore.backend = file" >> $SOFTHSM2_CONF
echo "# ERROR, WARNING, INFO, DEBUG" >> $SOFTHSM2_CONF
echo "log.level = INFO" >> $SOFTHSM2_CONF

}

OS_NAME=`cat /etc/*release* |grep ^NAME= |tr A-Z a-z | sed 's/"/ /g'|awk '{print $2}'`
if [ $OS_NAME = "centos" ]
then
    INSTALL_CENTOS
elif [ $OS_NAME = "ubuntu" ]
then
    INSTALL_UBUNTU
fi

if [ ! -f $OPENSSL_CONF ] ; then
	GEN_OPENSSL_CONF
fi

if [ ! -f $SOFTHSM2_CONF ] ; then
	GEN_SOFTHSM_CONF
fi

export SOFTHSM2_CONF=$SOFTHSM2_CONF
export PENSSL_CONF=$OPENSSL_CONF

echo
echo -n "softhsm version : "
softhsm2-util --version

echo
echo "softhsm --show-slots : "
softhsm2-util --show-slots


echo -n "Openssl Version : "
openssl version
echo

echo "Openssl Engine Info"
openssl engine -t pkcs11
echo

echo "Openssl Engine Rand"
openssl rand -engine pkcs11 64 |xxd

echo
echo "Set Environment"
echo "export SOFTHSM2_CONF=$SOFTHSM2_CONF"
echo "export OPENSSL_CONF=$OPENSSL_CONF"
echo
