#!/bin/bash

. ./env

# Define some stake pool id, choose arbitrary one
# https://preview.cexplorer.io/pool
STAKE_POOL_ID="pool1zzcrjzyrjf6glwhg8em2qpne0rjkurvshplazhmrzqtfun7s5k9"

# Create delegation certificate for multisig address and specific stake pool 
cardano-cli ${CARDANO_CLI_TAG} stake-address stake-delegation-certificate\
    --stake-script-file ${POLICY_PATH}/policy.script \
    --stake-pool-id ${STAKE_POOL_ID} \
    --out-file ${STAKING_FILES_PATH}/delegation.cert

ADDRESS=$(cat ${ADDRESSES_PATH}/script-with-stake.addr)

# Prepare tx input of script
TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${ADDRESS} | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
AMOUNT=$(echo ${TRANS} | awk '{print $3}')
TXIN=${UTXO}#${ID}

# Check if the amount is enough to cover the registration fee
MIN_AMOUNT=$((1000000+300000))
if [ "${AMOUNT}" -lt "${MIN_AMOUNT}" ] ; then
    echo "Not enough funds to register stake address"
    echo "Amount: ${AMOUNT}"
    echo "Minimum amount: ${MIN_AMOUNT}"
    exit 1
fi

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Generate draft tx
# --ttl == --invalid-hereafter 
cardano-cli ${CARDANO_CLI_TAG} transaction build-raw \
    --tx-in $TXIN \
    --tx-in-script-file ${POLICY_PATH}/policy.script \
    --tx-out $ADDRESS+0 \
    --ttl $EXPIRE \
    --fee 0 \
    --certificate-file ${STAKING_FILES_PATH}/delegation.cert \
    --out-file ${STAKING_FILES_PATH}/delegation-tx.raw

# Calculate (min) fee for a tx
WITNESS_NUMBER=$((${MULTISIG_ADDRESS_WITNESSES}*2))
FEE=$(cardano-cli ${CARDANO_CLI_TAG} transaction calculate-min-fee \
   --tx-body-file ${STAKING_FILES_PATH}/delegation-tx.raw \
   --tx-in-count 1 \
   --tx-out-count 1 \
   --witness-count ${WITNESS_NUMBER} \
   --protocol-params-file $PROTOCOL_PARAMETERS)
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# We need to pay for tx fee, we keep the rest
CHANGE=$((AMOUNT-$FEE_AMOUNT))

# Now build raw tx with corect data
cardano-cli ${CARDANO_CLI_TAG} transaction build-raw \
    --tx-in $TXIN \
    --tx-out $ADDRESS+$CHANGE \
    --ttl $EXPIRE \
    --tx-in-script-file ${POLICY_PATH}/policy.script \
    --out-file ${STAKING_FILES_PATH}/delegation-tx.raw \
    --fee $FEE_AMOUNT \
    --certificate-file ${STAKING_FILES_PATH}/delegation.cert

# Create witnesses(signatures) payment
WITNESS_INDEX=$((${MULTISIG_ADDRESS_WITNESSES}-1))
for i in $(seq 0 ${WITNESS_INDEX})
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/payment-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/delegation-tx.raw \
    --out-file ${STAKING_FILES_PATH}/payment-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Create witnesses(signatures) stake
WITNESS_INDEX=$((${MULTISIG_ADDRESS_WITNESSES}-1))
for i in $(seq 0 ${WITNESS_INDEX})
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/stkae-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/delegation-tx.raw \
    --out-file ${STAKING_FILES_PATH}/stake-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Asemble final tx for submission
cardano-cli ${CARDANO_CLI_TAG} transaction assemble \
   --tx-body-file ${STAKING_FILES_PATH}/delegation-tx.raw \
   --witness-file ${STAKING_FILES_PATH}/payment-0.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-1.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-2.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-3.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-0.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-1.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-2.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-3.witness \
   --out-file ${STAKING_FILES_PATH}/delegation-tx.signed

# Submit tx to chain
cardano-cli ${CARDANO_CLI_TAG} transaction submit \
   --tx-file ${STAKING_FILES_PATH}/delegation-tx.signed \
   ${CARDANO_NET_PREFIX}