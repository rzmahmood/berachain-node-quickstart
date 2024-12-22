#!/bin/bash

BEACON_CONFIG_DIR=./config/beacond
BEACOND_BINARY=./dependencies/beacon-kit/build/bin/beacond
INTERVAL=5  # Interval in seconds between checks
TRIES=5     # Number of times to check

# Initialize the previous block height
previous_block_height=0

for ((i = 1; i <= TRIES; i++)); do
  # Get the latest block height
  latest_block_height=$($BEACOND_BINARY --home=$BEACON_CONFIG_DIR status | jq -r .sync_info.latest_block_height)

  # Validate the block height is a number
  if ! [[ "$latest_block_height" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to fetch latest_block_height. Received: $latest_block_height"
    exit 1
  fi

  echo "Check $i: Latest Block Height = $latest_block_height"

  # Compare with the previous block height
  if (( i > 1 )) && (( latest_block_height <= previous_block_height )); then
    echo "Block height is not increasing (previous: $previous_block_height, current: $latest_block_height)."
    exit 1
  fi

  # Update the previous block height
  previous_block_height=$latest_block_height

  # Sleep before the next iteration (skip sleep after the last iteration)
  if (( i < TRIES )); then
    sleep $INTERVAL
  fi
done

echo "Block height is increasing consistently over $TRIES checks."
exit 0
