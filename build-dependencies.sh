#!/bin/bash

set -exu
set -o pipefail

# Check if go is installed
if ! command -v go &> /dev/null; then
    echo "Error: go is not installed. Please install Go first."
    exit 1
fi

go version

# Check for version is greater than 1.23
MIN_GO_VERSION="1.23"
GO_VERSION=$(go version | awk '{print $3}' | tr -d "go")
if [[ $(echo "$MIN_GO_VERSION $GO_VERSION" | tr " " "\n" | sort -V | head -n 1) != "$MIN_GO_VERSION" ]]; then
    echo "Error: Go version $GO_VERSION is installed, but version $MIN_GO_VERSION or higher is required."
    exit 1
fi


# Build BeaconKit
BEACONKIT_DIR=./dependencies/beacon-kit
( cd $BEACONKIT_DIR && make build )
echo "BeaconKit Version:"
$BEACONKIT_DIR/build/bin/beacond version

# Build Go-Ethereum
GETH_DIR=./dependencies/go-ethereum
( cd $GETH_DIR && make geth )
echo "Go-Ethereum Version:"
$GETH_DIR/build/bin/geth version

echo "🐻⛓️ BM. Node built SUCCESSFULLY. Unbearlievable work 🐻⛓️"