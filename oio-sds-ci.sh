#!/bin/bash

CIREPO=racciari

# Usage
while getopts ":r:g:p:b:c:R:" opt; do
	case $opt in
		r) REPLICATION_LEVEL="-r ${OPTARG}" ;;
		g) GIT_COMMIT="-g ${OPTARG}" ;;
		p) PULL_ID="-p ${OPTARG}" ;;
		b) BRANCH="-b ${OPTARG}" ;;
		c) COMMIT_ID="-c ${OPTARG}" ;;
		R) CIREPO="${OPTARG}" ;;
		\?) ;;
	esac
done

echo "$0" \
	"${REPLICATION_LEVEL}" \
	"${GIT_COMMIT}" \
	"${PULL_ID}" \
	"${BRANCH}" \
	"${COMMIT_ID}" \

# Define the packager installion function
# For Ubuntu only in this first version : apt-get
function pkg_install () { sudo apt-get -q -y install $@ ; }

sudo apt-get -q update
pkg_install git

export OIO_HOME="/home/openio"
sudo useradd openio -m -d ${OIO_HOME}
sudo echo "openio ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/openio
sudo su - openio -c "git clone https://github.com/${CIREPO}/oio-sds-ci ${OIO_HOME}/oio-sds-ci"
sudo ${OIO_HOME}/oio-sds-ci/build.sh ${PULL_ID} ${BRANCH} ${COMMIT_ID}
sudo ${OIO_HOME}/oio-sds-ci/setup.sh
sudo su - openio -c "${OIO_HOME}/oio-sds-ci/run_tests.sh ${REPLICATION_LEVEL} ${PULL_ID} ${BRANCH} ${COMMIT_ID}"
