<div align="center">

# 🐻⛓️ The Easiest Way To Run A Berachain Node 🐻⛓️



![alt text](./assets//hero.png)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#experimental)![node-CI](https://github.com/rzmahmood/berachain-node-quickstart/actions/workflows/node.yml/badge.svg)
</div>

BM. This opinonated repository allows you to quickly run a Berachain Node on one of the existing live networks, with the default as BArtio. With no modifications, you'll end up with a Go-Ethereum full node on BArtio (not an archive node and not a validator!)

This is great if you expect to do high throughput RPC interactions or don't trust RPC providers.

## Installation
This project utilizes Git submodules to reference the client code, notably Go-Ethereum and BeaconKit.
However, the scripts can be configured to reference binaries you build locally, making development quicker.

 **You will need Go 1.23 and JQ installed**.

 ```bash
git clone --recursive https://github.com/rzmahmood/berachain-node-quickstart.git
```

A helper script that builds the submodules, saving the binaries in a known path

```bash
./build-dependencies.sh
```

## Running
Start the Node. Make sure you've already finished the installation. If a node was previously started, it will continue from there.

Logs are stored in `beaconkit.log` and `geth.log`

```bash
./node.sh
```

By default, this will start a sync from genesis without bootstrapping from a snapshot. For long running networks, this can take a long time depending on your network latency and geography. Syncing from a snapshot support will come soon.

## Coming Soon
- Syncing from a snapshot
- State Sync (if possible)

## FAQ / Common Issues
- Downloading snapshot is too slow
    - Try changing the CL_SNAPSHOT_SOURCE or EL_SNAPSHOT_SOURCE snapshot sources in `node.sh` to a source from https://github.com/berachain/beacon-kit/blob/main/testing/networks/80084/snapshots.md that is geographically closer

