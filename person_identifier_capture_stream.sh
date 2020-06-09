#!/bin/bash

SHARD_ID=$1;\
grep "${SHARD_ID}" /var/log/trucentric/awspersoncapture.log* | grep 'i:{' | awk '{ print $5 }' | cut -d , -f 2 | sort | uniq -c | sort -n
