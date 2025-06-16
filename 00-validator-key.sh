#!/bin/bash

. ./env

set -e

PRIVATE_KEY_HEX0="66faa65bd29b7fb497f0f1412d7ebaea3eef29b6af5e243154237071defc215c"
PRIVATE_KEY_HEX1="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
PRIVATE_KEY_HEX2="9d8f7e6c5b4a3d2c1b0a9f8e7d6c5b4a3d2c1b0a9f8e7d6c5b4a3d2c1b0a9f8e"
PRIVATE_KEY_HEX3="1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"

for i in {0..3}
do
 if [ -f "${KEYS_PATH}/payment-${i}.skey" ] ; then
    echo "Key already exists!"
 else
    jq -n \
        --arg skey "$(eval echo \$PRIVATE_KEY_HEX$i)" \
        '{
            "type": "PaymentSigningKeyShelley_ed25519",
            "description": "Payment Signing Key",
            "cborHex": ("5820" + $skey)
        }' > ${KEYS_PATH}/payment-${i}.skey

    cardano-cli key verification-key \
        --signing-key-file ${KEYS_PATH}/payment-${i}.skey \
        --verification-key-file ${KEYS_PATH}/payment-${i}.vkey
 fi
done

STAKE_PRIVATE_KEY_HEX0="66faa65bd29b7fb497f0f1412d7ebaea3eef29b6af5e243154237071defc215c"
STAKE_PRIVATE_KEY_HEX1="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
STAKE_PRIVATE_KEY_HEX2="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
STAKE_PRIVATE_KEY_HEX3="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
STAKE_PRIVATE_KEY_HEX4="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"

for i in {0..3}
do
 if [ -f "${KEYS_PATH}/stake-${i}.skey" ] ; then
    echo "Key already exists!"
 else
    jq -n \
        --arg skey "$(eval echo \$STAKE_PRIVATE_KEY_HEX$i)" \
        '{
            "type": "PaymentSigningKeyShelley_ed25519",
            "description": "Payment Signing Key",
            "cborHex": ("5820" + $skey)
        }' > ${KEYS_PATH}/stake-${i}.skey

    cardano-cli key verification-key \
        --signing-key-file ${KEYS_PATH}/stake-${i}.skey \
        --verification-key-file ${KEYS_PATH}/stake-${i}.vkey
 fi
done