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

# Sort based on hash value and extract sorted hashes
sorted=$(echo "$keyhashes" | sort -t ':' -k2)
SORTED_KEYHASHES=($(echo "$sorted" | cut -d':' -f2))

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

# Sort based on hash value and extract sorted hashes
stake_sorted=$(echo "$stake_keyhashes" | sort -t ':' -k2)
SORTED_STAKE_KEYHASHES=($(echo "$stake_sorted" | cut -d':' -f2))

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
     "keyHash": "${SORTED_KEYHASHES[0]}"
   },
   {
     "type": "sig",
     "keyHash": "${SORTED_KEYHASHES[1]}"
   },
   {
     "type": "sig",
     "keyHash": "${SORTED_KEYHASHES[2]}"
   },
   {
     "type": "sig",
     "keyHash": "${SORTED_KEYHASHES[3]}"
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
     "keyHash": "${SORTED_STAKE_KEYHASHES[0]}"
   },
   {
     "type": "sig",
     "keyHash": "${SORTED_STAKE_KEYHASHES[1]}"
   },
   {
     "type": "sig",
     "keyHash": "${SORTED_STAKE_KEYHASHES[2]}"
   },
   {
     "type": "sig",
     "keyHash": "${SORTED_STAKE_KEYHASHES[3]}"
   }
 ]
}
EOF
fi
