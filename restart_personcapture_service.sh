#!/bin/bash

AWS_REGION=$1;\
EC2_INSTANCE_ID=$2;\
ENVIRONMENT=$3;\
sudo monit stop lift.${ENVIRONMENT}.${AWS_REGION}.kinesis-awspersoncapture-${EC2_INSTANCE_ID};\
sleep 20;\
sudo monit start lift.${ENVIRONMENT}.${AWS_REGION}.kinesis-awspersoncapture-${EC2_INSTANCE_ID}
