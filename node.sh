#!/bin/bash

set -exu
set -o pipefail

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq first."
    exit 1
fi

trap 'echo "Error on line $LINENO"; exit 1' ERR
# Function to handle the cleanup
cleanup() {
    echo "Caught Ctrl+C. Killing active background processes and exiting."
    kill $(jobs -p)  # Kills all background processes started in this script
    exit
}
# Trap the SIGINT signal and call the cleanup function when it's caught
trap 'cleanup' SIGINT

# Kill any hanging geth or beaconkit instances to prevent port clashes
pkill geth || echo "No existing geth processes"
pkill beacond || echo "No existing beaconkit processes"

# Detect if a node has already been started before. If the config directory already exists, it is assumed that we will
# continue operations from a previously started node. Delete the 'config' directory to start from scratch
echo "🐻⛓️ BM. You're off to a bearilliant start 🐻⛓️"
if [ -d "config" ]; then
	echo "Config directory exists. Continuing from a previously started node."
  FRESH_START=false
else
  echo "Starting node from scratch."
  FRESH_START=true
fi


BEACON_CONFIG_DIR=./config/beacond
EL_CONFIG_DIR=./config/geth

# Make the configuration directories
mkdir -p $BEACON_CONFIG_DIR
mkdir -p $EL_CONFIG_DIR

############################## START: TWEAK THESE AS NECESSARY ###########################
# The CL network to operate on. Default is bArtio. Should be updated alongside the EL_CHAIN_ID
CL_CHAIN_ID=bartio-beacon-80084
EL_CHAIN_ID=80084

# The location of the beacond binary. This location is the default if following the README
BEACOND_BINARY=./dependencies/beacon-kit/build/bin/beacond

# The location of the geth binary. This location is the default if following the README
GETH_BINARY=./dependencies/go-ethereum/build/bin/geth

# Feel free to replace the name below with a node name of your choice. It has little impact. It will node be used
MONIKER_NAME=BIG_BERA_DEFAULT_QUICKSTART_NODE_$(date +"%s")

# If USE_SNAPSHOT is true, then a snapshot will be downloaded to bootstrap the state, allowing for faster sync time.
# Introduces a trust assumption that the snapshot provider is trustworthy
USE_SNAPSHOT=true
SNAPSHOTS_DIRECTORY=./snapshots

# Update to use a source closer to your geography. 
# Sources can be found here https://storage.googleapis.com/bartio-snapshot-as/index.html
CL_SNAPSHOT_SOURCE=https://storage.googleapis.com/bartio-snapshot-as/beacon/pruned/snapshot_beacond_pruned_20241216120039.tar
EL_SNAPSHOT_SOURCE=https://storage.googleapis.com/bartio-snapshot-as/exec/geth/pruned/snapshot_geth_pruned_20241216120535.tar
############################## END: TWEAK THESE AS NECESSARY ###########################

# Rename the jwt path in app.toml
JWT_PATH=$BEACON_CONFIG_DIR/jwt.hex;

# If starting node from scratch, execute the following for beaconkit
if [ "$FRESH_START" = true ]; then
	# Cleanup any dirty state or files
	
	# Initialise the config files necessary for beaconkit
	$BEACOND_BINARY init $MONIKER_NAME --chain-id $CL_CHAIN_ID --consensus-key-algo bls12_381 --home ./config/beacond


	# Copy network files for the chosen network into working config directory
	cp networks/$EL_CHAIN_ID/genesis.json $BEACON_CONFIG_DIR/config/genesis.json
	cp networks/$EL_CHAIN_ID/kzg-trusted-setup.json $BEACON_CONFIG_DIR/kzg-trusted-setup.json
	cp networks/$EL_CHAIN_ID/app.toml $BEACON_CONFIG_DIR/config/app.toml
	cp networks/$EL_CHAIN_ID/config.toml $BEACON_CONFIG_DIR/config/config.toml


	# Rename the moniker in config.toml to the one configured in this script
	sed -i '' "s/^moniker = \".*\"/moniker = \"$MONIKER_NAME\"/" "$BEACON_CONFIG_DIR/config/config.toml";

	sed -i '' "s|^jwt-secret-path = \".*\"|jwt-secret-path = \"$JWT_PATH\"|" "$BEACON_CONFIG_DIR/config/app.toml";

	# Add the CL seeds to the config.toml
	seeds=$(cat networks/$EL_CHAIN_ID/cl-seeds.txt | tail -n +2 | tr '\n' ',' | sed 's/,$//');
	sed -i '' "s/^seeds = \".*\"/seeds = \"$seeds\"/" "$BEACON_CONFIG_DIR/config/config.toml";

	# Comma separated list of nodes to keep persistent connections to
	sed -i '' "s/^persistent_peers = \".*\"/persistent_peers = \"$seeds\"/" "$BEACON_CONFIG_DIR/config/config.toml";

	# Create JWT token for auth between Consensus Client and Execution Client
	$BEACOND_BINARY jwt generate -o $JWT_PATH;

	# Initialise geth state from genesis file
	$GETH_BINARY init \
	--datadir=$EL_CONFIG_DIR \
	networks/$EL_CHAIN_ID/el-genesis.json


	# Check if there's a local snapshot. If there is use that to avoid downloading again, even though it may be a bit behind
	if [ "$USE_SNAPSHOT" = true ]; then
		# Check if the SNAPSHOTS_DIRECTORY directory exists
		if [ ! -d "$SNAPSHOTS_DIRECTORY" ]; then
			echo "Directory $SNAPSHOTS_DIRECTORY does not exist. Creating it and downloading files..."

			# Create the directory
			mkdir -p "$SNAPSHOTS_DIRECTORY/beacond"
			mkdir -p "$SNAPSHOTS_DIRECTORY/geth"

			# Download CL Snapshot file
			curl --parallel --parallel-max 10 -L $CL_SNAPSHOT_SOURCE > $SNAPSHOTS_DIRECTORY/CL_SNAPSHOT_FIILE.tar.lz4;
			# Download EL Snapshot file
			curl --parallel --parallel-max 10 -L $EL_SNAPSHOT_SOURCE > $SNAPSHOTS_DIRECTORY/EL_SNAPSHOT_FIILE.tar.lz4;

			echo "Files downloaded successfully."
		else
			echo "Directory $directory already exists. Continuing processing as normal."
		fi
	fi

	# Continue processing as normal
	echo "Processing complete."

fi

$BEACOND_BINARY start \
	--home=$BEACON_CONFIG_DIR > "beaconkit.log" 2>&1 &


el_bootnodes=$(cat networks/$EL_CHAIN_ID/el-bootnodes.txt | grep '^enode://' | tr '\n' ',' | sed 's/,$//');

# Start geth execution client for this node
$GETH_BINARY \
	--networkid=$EL_CHAIN_ID \
	--authrpc.vhosts="*" \
	--authrpc.addr=127.0.0.1 \
	--authrpc.jwtsecret=$JWT_PATH \
	--datadir=$EL_CONFIG_DIR \
	--bootnodes=$el_bootnodes \
	--identity=$MONIKER_NAME \
	--syncmode=snap \
	--verbosity=3 > "geth.log" 2>&1 &

echo "Sleeping for 10s"
sleep 10

while true; do
	$BEACOND_BINARY --home=./config/beacond status | jq .sync_info;
	sleep 10
done