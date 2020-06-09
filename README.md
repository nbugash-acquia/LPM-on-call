# LPM-on-call
These are just a few commands that are frequently used when I'm on call

## Capture stream latency

        export EC2_INSTANCE_ID=i-<instance id>;\
        export SHARD_ID=shardId-<shard id>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        ssh $(aws --profile $AWS_PROFILE --region $AWS_REGION ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query "Reservations[*].Instances[*].PrivateIpAddress" --output text) 'bash -s' < person_identifier_capture_stream.sh $SHARD_ID
