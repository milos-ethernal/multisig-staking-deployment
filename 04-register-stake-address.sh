#!/bin/bash

. ./env

# Get stake address deposit amount from protocol parameters as stakeAddressDeposit or keyDeposit
# check protocol-parameters.json first, it could be listed as "keyDeposit" or "stakeAddressDeposit"
# depending on the cardano-cli version
KEY_REG_DEPOSIT_AMT=$(cat files/protocol-parameters.json | jq -r 'if has("stakeAddressDeposit") then .stakeAddressDeposit else .keyDeposit end')

# Create registration certificate
cardano-cli ${CARDANO_CLI_TAG} stake-address registration-certificate \
  --stake-script-file ${POLICY_PATH}/policy.script \
  --key-reg-deposit-amt ${KEY_REG_DEPOSIT_AMT} \
  --out-file ${STAKING_FILES_PATH}/registration.cert

ADDRESS=$(cat ${ADDRESSES_PATH}/script-with-stake.addr)

# Prepare tx input of script
TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${ADDRESS} | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
AMOUNT=$(echo ${TRANS} | awk '{print $3}')
TXIN=${UTXO}#${ID}

# Check if the amount is enough to cover the registration fee
MIN_AMOUNT=$((KEY_REG_DEPOSIT_AMT+1000000+300000))
if [ "${AMOUNT}" -lt "${MIN_AMOUNT}" ] ; then
    echo "Not enough funds to register stake address"
    echo "Amount: ${AMOUNT}"
    echo "Minimum amount: ${MIN_AMOUNT}"
    exit 1
fi

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

WITNESS_NUMBER=$((${MULTISIG_ADDRESS_WITNESSES}*2))
cardano-cli ${CARDANO_CLI_TAG} transaction build \
  --tx-in $TXIN \
  --change-address $ADDRESS \
  --certificate-file ${STAKING_FILES_PATH}/registration.cert \
  --tx-in-script-file ${POLICY_PATH}/policy.script \
  --witness-override ${WITNESS_NUMBER} \
  --out-file ${STAKING_FILES_PATH}/registration-tx.raw

# Create witnesses(signatures) payment
WITNESS_INDEX=$((${MULTISIG_ADDRESS_WITNESSES}-1))
for i in $(seq 0 ${WITNESS_INDEX})
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/payment-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/registration-tx.raw \
    --out-file ${STAKING_FILES_PATH}/payment-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Create witnesses(signatures) stake
WITNESS_INDEX=$((${MULTISIG_ADDRESS_WITNESSES}-1))
for i in $(seq 0 ${WITNESS_INDEX})
do
    cardano-cli ${CARDANO_CLI_TAG} transaction witness \
    --signing-key-file ${KEYS_PATH}/stake-${i}.skey \
    --tx-body-file ${STAKING_FILES_PATH}/registration-tx.raw \
    --out-file ${STAKING_FILES_PATH}/stake-${i}.witness \
    ${CARDANO_NET_PREFIX}
done

# Asemble final tx for submission
# we will add all but atLeast would suffice
cardano-cli ${CARDANO_CLI_TAG} transaction assemble \
   --tx-body-file ${STAKING_FILES_PATH}/registration-tx.raw \
   --witness-file ${STAKING_FILES_PATH}/payment-0.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-1.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-2.witness \
   --witness-file ${STAKING_FILES_PATH}/payment-3.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-0.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-1.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-2.witness \
   --witness-file ${STAKING_FILES_PATH}/stake-3.witness \
   --out-file ${STAKING_FILES_PATH}/registration-tx.signed

# Submit tx to chain
cardano-cli ${CARDANO_CLI_TAG} transaction submit \
   --tx-file ${STAKING_FILES_PATH}/registration-tx.signed \
   ${CARDANO_NET_PREFIX}