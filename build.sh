#!/bin/bash

# Usage
while getopts ":p:b:c:" opt; do
        case $opt in
                p) PULL_ID="${OPTARG}" ;;
                b) BRANCH="${OPTARG}" ;;
                c) COMMIT_ID="${OPTARG}" ;;
                \?) ;;
        esac
done

echo "$0" \
        "-p \"${PULL_ID}\"" \
        "-b \"${BRANCH}\"" \
        "-c \"${COMMIT_ID}\"" \

# Define the packager installion function
# For Ubuntu only in this first version : apt-get
function pkg_install () { sudo apt-get -y install $@ ; }

# Define and create the default building directory
export SDS=/home/openio/build
mkdir -p ${SDS}

# Define and create the default working directory
export TMPDIR=/home/openio/tmp
mkdir -p ${TMPDIR}
cd ${TMPDIR}

# required everywhere
pkg_install git autoconf libtool make gcc cmake pkg-config libglib2.0-dev

# asn1c
git clone https://github.com/open-io/asn1c.git
cd asn1c
autoreconf -vif && ./configure --enable-{static,shared} --prefix=$SDS
make && make install
cd ..

# gridinit and its dependencies
pkg_install libevent-dev

echo "Building GridInit ..."
git clone https://github.com/open-io/gridinit.git
mkdir build-gridinit && cd build-gridinit
cmake \
  -DCMAKE_INSTALL_PREFIX=$SDS \
  -DGRIDINIT_SOCK_PATH=/run/gridinit/gridinit.sock\
  -DLD_LIBDIR=lib \
  ../gridinit
make && make install
cd ..

# Dependencies common to the client and the backend
pkg_install \
    flex bison \
    libcurl4-openssl-dev \
    libjson-c-dev \
    libapr1-dev \
    curl

# Dependencies specific to the backend
pkg_install \
    libneon27-dev \
    sqlite3 libsqlite3-0 libsqlite3-dev libsqlite0-dev \
    libzmq3-dev \
    libapr1-dev libaprutil1-dev \
    apache2 apache2-dev \
    libattr1-dev \
    liblzo2-dev \
    libpython-dev \
    libleveldb1v5 libleveldb-dev \
    libzookeeper-mt-dev

# Required since the SDK_ONLY installation now brings the python part.
pkg_install python-setuptools python-cffi

# Build SDS
echo "Building OpenIO SDS ..."
git clone https://github.com/open-io/oio-sds.git
if [ ${COMMIT_ID} ]
 then
         echo "Checkout commit id ${COMMIT_ID}"
         cd oio-sds
         git checkout -f ${COMMIT_ID} 
         cd ..
fi
if [ ${BRANCH} ]
 then
         echo "Checkout from branch ${BRANCH}"
         cd oio-sds
         git checkout -b LOCAL_BRANCH origin/${BRANCH}
         cd ..
fi
if [ ${PULL_ID} ]
 then
	 echo "Checkout Pull Request ${PULL_ID} from branch ${BRANCH}"
	 cd oio-sds
	 git fetch origin +refs/pull/${PULL_ID}/merge:
	 git checkout -qf FETCH_HEAD
	 cd ..
fi
mkdir build-oio-sds && cd build-oio-sds
cmake \
        -DCMAKE_INSTALL_PREFIX=$SDS \
        -DLD_LIBDIR=lib \
        -DEXE_PREFIX=oio \
        -DAPACHE2_MODDIR=$SDS/lib/apache2 \
        -DAPACHE2_LIBDIR=/usr/lib/apache2 \
        -DAPACHE2_INCDIR=/usr/include/apache2 \
        -DASN1C_EXE=$SDS/bin/asn1c \
        -DASN1C_INCDIR=$SDS/share/asn1c \
        -DASN1C_LIBDIR=$SDS/lib \
        -DLIBRAIN_INCDIR=$SDS/include \
        -DLIBRAIN_LIBDIR=$SDS/lib \
        -DGRIDINIT_INCDIR=$SDS/include \
        -DGRIDINIT_LIBDIR=$SDS/lib \
        ../oio-sds
make && make install
(cd ../oio-sds && sudo python ./setup.py develop)
cd ..
