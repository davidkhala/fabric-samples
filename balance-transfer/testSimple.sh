#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

TARGET="$1"
ACTION="$2"
ORG="$3"

jq --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi
starttime=$(date +%s)
if [ -z "$ORG" ]; then
	ORG='org1'
fi

echo "POST request Enroll on $ORG  ..."
if [ "${ACTION}" == "Enroll" ]; then
	ORG_TOKEN=$(curl -s -X POST \
		http://localhost:4000/users \
		-H "content-type: application/x-www-form-urlencoded" \
		-d "username=$TARGET&orgName=$ORG")
	ORG_TOKEN=$(echo $ORG_TOKEN | jq ".token" | sed "s/\"//g")
	echo "$ORG token is $ORG_TOKEN"
	exit 0
else
	ORG_TOKEN=$(curl -s -X POST \
		http://localhost:4000/users \
		-H "content-type: application/x-www-form-urlencoded" \
		-d "username=Jim&orgName=$ORG")
	ORG_TOKEN=$(echo $ORG_TOKEN | jq ".token" | sed "s/\"//g")
	echo "$ORG token is $ORG_TOKEN"
fi

# TODO how to dynamic createChannel
if [ "${ACTION}" == "create" ] && ["${TARGET}"=="channel"]; then
	echo "POST request Create channel  ..."
	curl -s -X POST \
		http://localhost:4000/channels \
		-H "authorization: Bearer $ORG_TOKEN" \
		-H "content-type: application/json" \
		-d '{
	"channelName":"mychannel",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
	echo
	exit 0
fi

echo
sleep 1
echo "POST request Join channel on $ORG"
echo
curl -s -X POST \
	http://localhost:4000/channels/mychannel/peers \
	-H "authorization: Bearer $ORG_TOKEN" \
	-H "content-type: application/json" \
	-d '{
	"peers": ["localhost:7051","localhost:7056"]
}'
echo
echo

echo "POST Install chaincode on $ORG"
# ENOENT: no such file or directory, lstat
# '/home/david/Documents/fabric-release/1.0beta/fabric-sdk-node/test/fixtures/src/{chaincodePath}'
# FIXME: to change it, modify /config.json::GOPATH

echo
curl -s -X POST \
	http://localhost:4000/chaincodes \
	-H "authorization: Bearer $ORG_TOKEN" \
	-H "content-type: application/json" \
	-d '{
	"peers": ["localhost:7051","localhost:7056"],
	"chaincodeName":"mycc",
	"chaincodePath":"github.com/example_cc",
	"chaincodeVersion":"v0"
}'
echo
echo

echo "POST instantiate chaincode on peer1 of $ORG"
echo
curl -s -X POST \
	http://localhost:4000/channels/mychannel/chaincodes \
	-H "authorization: Bearer $ORG_TOKEN" \
	-H "content-type: application/json" \
	-d '{
	"chaincodeName":"mycc",
	"chaincodeVersion":"v0",
	"functionName":"init",
	"args":["a","100","b","200"]
}'
echo
echo

echo "POST invoke chaincode on peers of $ORG: move"
TRX_ID=$(curl -s -X POST \
	http://localhost:4000/channels/mychannel/chaincodes/mycc \
	-H "authorization: Bearer $ORG_TOKEN" \
	-H "content-type: application/json" \
	-d '{
	"peers": ["localhost:7051", "localhost:7056"],
	"fcn":"move",
	"args":["a","b","0"]
}')

echo "Transacton ID is $TRX_ID"
echo
echo

echo "GET query chaincode on peer1 of $ORG"
echo
curl -s -X GET \
	"http://localhost:4000/channels/mychannel/chaincodes/mycc?peer=peer1&args=%5B%22query%22%2C%22a%22%5D" \
	-H "authorization: Bearer $ORG_TOKEN" \
	-H "content-type: application/json"
echo
echo
