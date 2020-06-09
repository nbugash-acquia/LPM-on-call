# LPM-on-call
These are just a few commands that are frequently used when I'm on call

## Setup
Prior to running this "runbooks" you need to configure your ssh config

```
## Prod Account
Host 10.14.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.prod

Host 10.13.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.prod

Host 10.11.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.prod

Host 10.21.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.prod


## Dev Account
Host 10.73.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.dev

Host 10.61.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.dev

Host 10.81.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.dev

Host 10.0.*.*
        IdentitiesOnly yes
        User ec2-user
        IdentityFile ~/.ssh/nbugash-acquia.aws.dev
```
(Optional)
You can link the bash scripts (e.g person_identifier_capture_stream.sh) to your PATH so that you can run it anywhere

## Capture stream latency

        export EC2_INSTANCE_ID=i-<instance id>;\
        export SHARD_ID=shardId-<shard id>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        ssh $(aws --profile $AWS_PROFILE --region $AWS_REGION \
                ec2 describe-instances --instance-ids $EC2_INSTANCE_ID \
                                       --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)\
               'bash -s' < person_identifier_capture_stream.sh $SHARD_ID
