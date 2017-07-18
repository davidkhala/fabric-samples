#!/usr/bin/env bash
CURRENT=$PWD
CONFIG_OUTPUT=$CURRENT/crypto-config
CONFIG_INPUT=$CURRENT/cryptogen.yaml
# clear existing
MODE=$1

function clearOutput() {
	echo "clear CONFIG_OUTPUT $CONFIG_OUTPUT"
	rm -rf $CONFIG_OUTPUT
}

function gen() {
	cd ../../bin

	./cryptogen generate --config="$CONFIG_INPUT" --output="$CONFIG_OUTPUT"

	cd -
}
if [ "${MODE}" == "clear" ]; then
	clearOutput
fi
gen
