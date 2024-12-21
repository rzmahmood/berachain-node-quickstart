#!/bin/bash

set -exu
set -o pipefail

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


# Make the configuration directories
mkdir -p config/beacond
mkdir -p config/geth


############################## START: TWEAK THESE AS NECESSARY ###########################
# The CL network to operate on. Default is bArtio. Should be updated alongside the EL_CHAIN_ID
CL_CHAIN_ID=bartio-beacon-80084
EL_CHAIN_ID=80084

# The location of the beacond binary. This location is the default if following the README
BEACOND_BINARY=./dependencies/beacon-kit/build/bin/beacond

# Feel free to replace the name below with a node name of your choice. It has little impact. It will node be used
MONIKER_NAME=BIG_BERA_DEFAULT_QUICKSTART_NODE_$(date +"%s")
############################## END: TWEAK THESE AS NECESSARY ###########################

BEACON_CONFIG_DIR=./config/beacond

# If starting node from scratch, execute the following for beaconkit
if [ "$FRESH_START" = true ]; then
	$BEACOND_BINARY init $MONIKER_NAME --chain-id $CL_CHAIN_ID --consensus-key-algo bls12_381 --home ./config/beacond


	# Copy network files for the chosen network into working config directory
	cp networks/$EL_CHAIN_ID/genesis.json $BEACON_CONFIG_DIR/genesis.json
	cp networks/$EL_CHAIN_ID/kzg-trusted-setup.json $BEACON_CONFIG_DIR/kzg-trusted-setup.json
	cp networks/$EL_CHAIN_ID/app.toml $BEACON_CONFIG_DIR/app.toml
	cp networks/$EL_CHAIN_ID/config.toml $BEACON_CONFIG_DIR/config.toml

	# Rename the moniker in config.toml to the one configured in this script
	sed -i '' "s/^moniker = \".*\"/moniker = \"$MONIKER_NAME\"/" "$BEACON_CONFIG_DIR/config/config.toml";

	# Rename the jwt path in app.toml
	JWT_PATH=$BEACON_CONFIG_DIR/jwt.hex;
	sed -i '' "s|^jwt-secret-path = \".*\"|jwt-secret-path = \"$JWT_PATH\"|" "$BEACON_CONFIG_DIR/config/app.toml";

	# Add the CL seeds to the config.toml
	seeds=$(cat networks/$EL_CHAIN_ID/cl-seeds.txt | tail -n +2 | tr '\n' ',' | sed 's/,$//');
	sed -i '' "s/^seeds = \".*\"/seeds = \"$seeds\"/" "$BEACON_CONFIG_DIR/config/config.toml";
	# Comma separated list of nodes to keep persistent connections to
	sed -i '' "s/^persistent_peers = \".*\"/persistent_peers = \"$seeds\"/" "$BEACON_CONFIG_DIR/config/config.toml";

	# Create JWT token for auth between Consensus Client and Execution Client
	$BEACOND_BINARY jwt generate -o $JWT_PATH;

fi

$BEACOND_BINARY start \
	--home=$BEACON_CONFIG_DIR \
	--beacon-kit.kzg.trusted-setup-path=$BEACON_CONFIG_DIR/kzg-trusted-setup.json | tee beaconkit.log


