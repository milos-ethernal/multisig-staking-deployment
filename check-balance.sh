#!/bin/bash

set -e

. ./env

ADDRESS=$(cat ${ADDRESSES_PATH}/script-with-stake.addr)

echo multisig:
cardano-cli query utxo --address $ADDRESS ${CARDANO_NET_PREFIX}

echo stake:
STAKE_ADDRESS=$(cat ${ADDRESSES_PATH}/script-stake.addr)
cardano-cli query stake-address-info --address $STAKE_ADDRESS ${CARDANO_NET_PREFIX}
