#!/bin/bash

set -e

. ./env

STAKE_ADDRESS=$(cat ${ADDRESSES_PATH}/script-stake.addr)
ADDRESS=$(cat ${ADDRESSES_PATH}/script-with-stake.addr)

REWARDS="$(cardano-cli $CARDANO_CLI_TAG query stake-address-info --address $STAKE_ADDRESS | jq .[].rewardAccountBalance)"

if [ $REWARDS -eq 0 ] ; then
    echo "No rewards avaialable for withdrawal"
    exit 1
fi

# Prepare tx input of script
# required to pay transaction fee
TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${ADDRESS} | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
AMOUNT=$(echo ${TRANS} | awk '{print $3}')
TXIN=${UTXO}#${ID}

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

WITNESS_NUMBER=$((${MULTISIG_ADDRESS_WITNESSES}*2))
cardano-cli ${CARDANO_CLI_TAG} transaction build \
  --tx-in $TXIN \
  --withdrawal $STAKE_ADDRESS+$REWARDS \
  --change-address $ADDRESS \
  --tx-in-script-file ${POLICY_PATH}/policy-payment.script \
  --witness-override ${WITNESS_NUMBER} \
  --certificate-file ${STAKING_FILES_PATH}/delegation.cert \
  --certificate-script-file ${POLICY_PATH}/policy-stake.script \
  --out-file ${STAKING_FILES_PATH}/withdraw-tx.raw

# Create witnesses(signatures) payment
WITNESS_INDEX=$((${MULTISIG_ADDRESS_WITNESSES}-1))
for i in $(seq 0 ${WITNESS_INDEX})
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/payment-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/withdraw-tx.raw \
    --out-file ${STAKING_FILES_PATH}/payment-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Create witnesses(signatures) stake
for i in $(seq 0 ${WITNESS_INDEX})
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/stake-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/withdraw-tx.raw \
    --out-file ${STAKING_FILES_PATH}/stake-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Asemble final tx for submission
cardano-cli ${CARDANO_CLI_TAG} transaction assemble \
   --tx-body-file ${STAKING_FILES_PATH}/withdraw-tx.raw \
   --witness-file ${STAKING_FILES_PATH}/payment-0.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-1.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-2.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-3.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-0.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-1.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-2.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-3.witness \
   --out-file ${STAKING_FILES_PATH}/withdraw-tx.signed

# Submit tx to chain
cardano-cli ${CARDANO_CLI_TAG} transaction submit \
   --tx-file ${STAKING_FILES_PATH}/withdraw-tx.signed \
   ${CARDANO_NET_PREFIX}