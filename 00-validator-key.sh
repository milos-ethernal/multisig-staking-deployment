#!/bin/bash

. ./env

PRIVATE_KEY_HEX0="66faa65bd29b7fb497f0f1412d7ebaea3eef29b6af5e243154237071defc215c"
PRIVATE_KEY_HEX1="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
PRIVATE_KEY_HEX2="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
PRIVATE_KEY_HEX3="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"
PRIVATE_KEY_HEX4="8c95059ceb5d992fb78fa34902ad826b06c633550ae5319a41025e0bf06a08eb"

for i in {0..4}
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