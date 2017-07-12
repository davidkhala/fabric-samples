#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

UP_DOWN="$1"
FILTER="hyperledger\|couchdb\|example.com"

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
	docker images | grep "dev\|none\|$FILTER"
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
	docker-compose down
	dkcl
	dkrm
	#Cleanup the material
	rm -rf /tmp/hfc-test-kvs_peerOrg* ~/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*
	cd -
	echo
	echo ===down finished
	echo =====images
	docker images -a
}

function networkUp() {
	# ccenv/tools is required before compose up!!!tricky
	#    docker pull hyperledger/fabric-tools
	# did it in docker-compose file
	cd artifacts
	#Start the network
	docker-compose up -d
		
	cd -
	echo ===up finished
	echo =====images
	docker images -a
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
