<div align="center">

# 🐻⛓️ The Easiest Way To Run A Berachain Node 🐻⛓️



![alt text](./assets//hero.png)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#experimental)
</div>

BM. This opinonated repository allows you to quickly run a Berachain Node on one of the existing live networks, with the default as BArtio. With no modifications, you'll end up with a Go-Ethereum full node on BArtio (not an archive node and not a validator!)

This is great if you expect to do high throughput RPC interactions or don't trust RPC providers.

## Installation
This project utilizes Git submodules to reference the client code, notably Go-Ethereum and BeaconKit.
However, the scripts can be configured to reference binaries you build locally, making development quicker.

 **You will need Go 1.23 installed**.

 ```bash
git clone --recursive https://github.com/rzmahmood/berachain-node-quickstart.git
```

A helper script that builds the submodules, saving the binaries in a known path

```bash
./build-dependencies.sh
```

## Running
Start the Node. Make sure you've already finished the installation. If a node was previously started, it will continue from there.


