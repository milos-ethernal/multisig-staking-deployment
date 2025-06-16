#!/bin/bash

set -e

. ./env

cardano-cli address build \
    --payment-script-file ${POLICY_PATH}/policy-payment.script \
    ${CARDANO_NET_PREFIX} \
    --out-file ${ADDRESSES_PATH}/script.addr

cardano-cli address build \
    --payment-script-file ${POLICY_PATH}/policy-payment.script \
    --stake-script-file ${POLICY_PATH}/policy-stake.script \
    ${CARDANO_NET_PREFIX} \
    --out-file ${ADDRESSES_PATH}/script-with-stake.addr

cardano-cli stake-address build \
  --stake-script-file ${POLICY_PATH}/policy-stake.script \
  ${CARDANO_NET_PREFIX} \
  --out-file ${ADDRESSES_PATH}/script-stake.addr