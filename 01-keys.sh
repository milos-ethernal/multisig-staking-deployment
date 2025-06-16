#!/bin/bash

set -e

. ./env

for i in {0..2}
do
 if [ -f "${KEYS_PATH}/payment-${i}.skey" ] ; then
   echo "Key already exists!"
 else
   cardano-cli ${CARDANO_CLI_TAG} address key-gen --verification-key-file ${KEYS_PATH}/payment-${i}.vkey --signing-key-file ${KEYS_PATH}/payment-${i}.skey
 fi
done