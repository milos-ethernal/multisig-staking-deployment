#!/bin/bash

. ./env

set -e

STAKE_ADDRESS="stake_test17zwznsyzt7xpynewnulmzzr0qf43jqd3rs8pzla447gmf8q578s23"
ADDRESS=$(cat ${ADDRESSES_PATH}/script-with-stake.addr)

REWARDS="$(cardano-cli conway query stake-address-info --address $STAKE_ADDRESS | jq .[].rewardAccountBalance)"

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

cardano-cli ${CARDANO_CLI_TAG} transaction build \
  --tx-in $TXIN \
  --withdrawal $STAKE_ADDRESS+$REWARDS \
  --change-address $ADDRESS \
  --tx-in-script-file ${POLICY_PATH}/policy.script \
  --witness-override 3 \
  --out-file ${STAKING_FILES_PATH}/withdraw-tx.raw

  # Create witnesses(signatures)
for i in {0..2}
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/payment-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/withdraw-tx.raw \
    --out-file ${STAKING_FILES_PATH}/payment-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Asemble final tx for submission
# we need only two witneses
cardano-cli ${CARDANO_CLI_TAG} transaction assemble \
   --tx-body-file ${STAKING_FILES_PATH}/withdraw-tx.raw \
   --witness-file ${STAKING_FILES_PATH}/payment-0.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-1.witness \
   --out-file ${STAKING_FILES_PATH}/withdraw-tx.signed

# Submit tx to chain
cardano-cli ${CARDANO_CLI_TAG} transaction submit \
   --tx-file ${STAKING_FILES_PATH}/withdraw-tx.signed \
   ${CARDANO_NET_PREFIX}