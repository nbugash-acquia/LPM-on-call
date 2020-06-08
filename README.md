# LPM-on-call
These are just a few commands that are frequently used when I'm on call

## Capture stream latency
### Step 1:
Type the instance id

    export EC2_INSTANCE_ID=<instance id> ;\
    ssh $(aws --profile production --region us-east-1 ec2 describe-instances --instance-ids $EC2_INSTANCE_ID --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)

### Step 2:
Type the shard id

    export SHARD_ID=<shard id> ;\
    grep "shardId-${SHARD_ID}" /var/log/trucentric/awspersoncapture.log* | grep 'i:{' | awk '{ print $5 }' | cut -d , -f 2 | sort | uniq -c | sort -n
