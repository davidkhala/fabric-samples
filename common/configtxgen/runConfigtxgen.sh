#!/usr/bin/env bash
CURRENT=$PWD

BIN_PATH="../../bin"
export FABRIC_CFG_PATH=$PWD
outputDir=$CURRENT/ # if not set, output file will be created in BIN_PATH

PROFILE_DEFAULT_CHANNEL="SampleEmptyInsecureChannel"
PROFILE_DEFAULT_BLOCK="SampleInsecureSolo"

PARAM_profile=""
PARAM_channelID=""
PARAM_asOrg=""

function usage() {
	echo "usage: ./runConfigtxgen.sh block|channel view|create <target_file>"
	echo " configtx.yaml will be indexed under env var: FABRIC_CFG_PATH "
}


function genBlock() {
	local CMD="./configtxgen -outputBlock $outputDir$1"
    $CMD
}
function viewBlock() {
    local CMD="./configtxgen -inspectBlock $outputDir$1 $MORE_PARAMS"
    echo CMD $CMD
	if [ -z "$VIEW_LOG" ]; then
	    $CMD
	elif [ "$VIEW_LOG" == "default" ]; then
		$CMD >"$outputDir$1.block.config"
	else
		$CMD >"$VIEW_LOG"
	fi
}
function viewChannel() {
    local CMD="./configtxgen -inspectChannelCreateTx $outputDir$1 $MORE_PARAMS"
    echo CMD $CMD
	if [ -z "$VIEW_LOG" ]; then
		$CMD
	elif [ "$VIEW_LOG" == "default" ]; then
		$CMD >"$outputDir$1.channel.config"
	else
		$CMD >"$VIEW_LOG"
	fi
}
function genChannel() {
	# TODO: Cannot define a new channel with no Application section
	local CMD="./configtxgen -outputCreateChannelTx $outputDir$1 $MORE_PARAMS"
	if [ -z $PARAM_profile ]; then
	    CMD="$CMD -profile $PROFILE_DEFAULT_CHANNEL"
	fi
	$CMD
}

remain_params=""
for((i=4;i<=$#;i++)); do
    j=${!i}
    remain_params="$remain_params $j"
done


while getopts "ai:t:p:c:o:" shortname $remain_params ; do
	case $shortname in
	a)
		echo "using Absolute path"
		outputDir=""
		;;
	p)
		echo "profile $OPTARG"
		PARAM_profile=" -profile $OPTARG"
		;;
	c)
		echo "channelID $OPTARG"
		PARAM_channelID=" -channelID $OPTARG"
		;;
	o)
		echo "asOrg $OPTARG"
		PARAM_asOrg=" -asOrg $OPTARG"
		;;
	t)
		echo "saving view output: $OPTARG"
		if [ -z "$OPTARG" ]; then
			VIEW_LOG="default"
		else
			VIEW_LOG=$OPTARG
		fi
		;;

	i)

		echo "set parent directory of configtx.yaml: $OPTARG "
		echo " !!! value will be set to env var FABRIC_CFG_PATH"
		echo " please make sure '\$FABRIC_CFG_PATH/configtx.yaml' exist"
		export FABRIC_CFG_PATH=$OPTARG
		;;
	?) #当有不认识的选项的时候arg为?
		echo "unknown argument"
		exit 1
		;;
	esac
done

MORE_PARAMS=$PARAM_profile$PARAM_channelID$PARAM_asOrg



cd $BIN_PATH
if [ "$1" == "block" ]; then
	if [ "$2" == "view" ]; then
		viewBlock $3
	elif [ "$2" == "create" ]; then
		genBlock $3
	else echo "invalid arg2: $2";usage
	fi
elif [ "$1" == "channel" ]; then
	if [ "$2" == "view" ]; then
		viewChannel $3
	elif [ "$2" == "create" ]; then
		genChannel $3
	else echo "invalid arg2: $2"; usage
	fi
else
	echo "invalid arg1: $1";usage
fi
cd -
