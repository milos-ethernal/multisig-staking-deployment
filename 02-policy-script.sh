#!/bin/bash

. ./env

set -e

KEYHASH0=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-0.vkey)
KEYHASH1=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-1.vkey)
KEYHASH2=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-2.vkey)
KEYHASH3=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/payment-3.vkey)

# Combine them into a labeled list
keyhashes=$(cat <<EOF
0:$KEYHASH0
1:$KEYHASH1
2:$KEYHASH2
3:$KEYHASH3
EOF
)

# Sort based on hash value
sorted=$(echo "$keyhashes" | sort -t ':' -k2)

# Print sorted key indexes and their hashes
echo "$sorted"

STAKE_KEYHASH0=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/stake-0.vkey)
STAKE_KEYHASH1=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/stake-1.vkey)
STAKE_KEYHASH2=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/stake-2.vkey)
STAKE_KEYHASH3=$(cardano-cli address key-hash --payment-verification-key-file ${KEYS_PATH}/stake-3.vkey)

# Combine them into a labeled list
stake_keyhashes=$(cat <<EOF
0:$STAKE_KEYHASH0
1:$STAKE_KEYHASH1
2:$STAKE_KEYHASH2
3:$STAKE_KEYHASH3
EOF
)

# Sort based on hash value
stake_sorted=$(echo "$stake_keyhashes" | sort -t ':' -k2)

# Print sorted key indexes and their hashes
echo "$stake_sorted"

if [ ! -f ${POLICY_PATH}/payment-policy.script ] ; then
cat << EOF >${POLICY_PATH}/policy-payment.script
{
 "type": "atLeast",
 "required": 3,
 "scripts":
 [
   {
     "type": "sig",
     "keyHash": "${KEYHASH0}"
   },
   {
     "type": "sig",
     "keyHash": "${KEYHASH1}"
   },
   {
     "type": "sig",
     "keyHash": "${KEYHASH2}"
   },
   {
     "type": "sig",
     "keyHash": "${KEYHASH3}"
   }
 ]
}
EOF
fi

if [ ! -f ${POLICY_PATH}/payment-policy.script ] ; then
cat << EOF >${POLICY_PATH}/policy-stake.script
{
 "type": "atLeast",
 "required": 3,
 "scripts":
 [
   {
     "type": "sig",
     "keyHash": "${STAKE_KEYHASH0}"
   },
   {
     "type": "sig",
     "keyHash": "${STAKE_KEYHASH1}"
   },
   {
     "type": "sig",
     "keyHash": "${STAKE_KEYHASH2}"
   },
   {
     "type": "sig",
     "keyHash": "${STAKE_KEYHASH3}"
   }
 ]
}
EOF
fi
