#!/bin/bash

set -exu
set -o pipefail

rm -r ./config || echo "failed to delete config dir"

# Kill any hanging geth or beaconkit instances to prevent port clashes
pkill geth || echo "No existing geth processes"
pkill beacond || echo "No existing beaconkit processes"