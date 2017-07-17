#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

UP_DOWN="$1"
FILTER="dev\|fabric\|hyperledger\|couchdb\|example.com"
VERS="$2"
COMPOSE_FILENAME="docker-compose"
COMPOSE_FILE=""
COMPOSE_FILE_SUFFIX=".yaml"

function dockerView(){

    echo =====container
    docker ps -a
    echo =====images
    docker images -a
}
function dkcl() {
	echo "=====containers to delete:"
	docker ps -a | grep "$FILTER"
	CONTAINER_IDS=$(docker ps -a | grep "$FILTER" | awk '{ print $1 }')
	if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
		echo "========== No containers available for deletion =========="
	else
		docker rm -f $CONTAINER_IDS
	fi
}

function dkrm() {
	echo "=====images to delete:"
	docker images | grep "none\|$FILTER"
	DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|$FILTER" | awk '{print $3}')
	# FIXME: hyperledger images cannot be removed here???
	echo
	if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
		echo "========== No images available for deletion ==========="
	else
		docker rmi -f $DOCKER_IMAGE_IDS
	fi
	echo
}

function networkDown() {
	#teardown the network and clean the containers and intermediate images
	cd artifacts
	docker-compose -f $COMPOSE_FILE down
	dkcl
	dkrm
	#Cleanup the material
	rm -rf /tmp/hfc-test-kvs_peerOrg* ~/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*
	cd -
	echo
	echo ===down finished
	dockerView
}

function networkUp() {
	# did it in docker-compose file
	# ccenv is required for success instantiate !!!tricky
	#   docker pull hyperledger/fabric-ccenv:x86_64-1.0.0

	cd artifacts
	#Start the network
	docker-compose -f $COMPOSE_FILE up -d
		
	cd -
	echo ===up finished
	dockerView
	installNodeModules

	PORT=4000 node app
}

function installNodeModules() {
	echo
	if [ -d node_modules ]; then
		echo "============== node modules installed already ============="
	else
		echo "============== Installing node modules ============="
		npm install
	fi
	echo
}

if [ ! -z "$VERS" ]; then
    COMPOSE_FILENAME=$COMPOSE_FILENAME-$VERS
fi
COMPOSE_FILE=$COMPOSE_FILENAME$COMPOSE_FILE_SUFFIX
echo docker compose file: $COMPOSE_FILE
# check file existence
cd artifacts
if [ ! -f $COMPOSE_FILE ]; then
    echo Compose file not found!!
    exit 1
fi
cd -

if [ "${UP_DOWN}" == "up" ]; then
	networkUp
elif [ "${UP_DOWN}" == "down" ]; then ## Clear the network
	networkDown
elif [ "${UP_DOWN}" == "restart" ]; then ## Restart the network
	networkDown
	networkUp
else

	exit 1
fi
