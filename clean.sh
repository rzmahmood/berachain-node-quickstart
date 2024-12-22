#!/bin/bash

set -exu
set -o pipefail

rm -r ./config || echo "failed to delete config dir"
rm geth.log || echo "failed to geth log file"
rm beaconkit.log || echo "failed to beaconkit log file"

# Kill any hanging geth or beaconkit instances to prevent port clashes
pkill geth || echo "No existing geth processes"
pkill beacond || echo "No existing beaconkit processes"