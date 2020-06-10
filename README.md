# LPM-on-call
These are just a few commands that are frequently used when I'm on call

## Requirements
1. Python 3.x
2. Pip
3. aws cli
4. bash (if running on windows, install WSL 2)

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
Update with your correct `IdentityFile` locations

Next you need to clone this repo

        export PROJECT_NAME="LPM-on-call" ;\
        git clone https://github.com/nbugash-acquia/LPM-on-call.git $PROJECT_NAME;\
        cd $PROJECT_NAME

(Optional - Not Tested)
You can link the bash scripts (e.g person_identifier_capture_stream.sh) to your PATH so that you can run it anywhere


## Runbooks
#### General workflow
To run these "runbooks" command
1. Update all environment variable specified (e.g SHARD_ID, AWS_PROFILE, etc)
2. Copy the command
3. Paste command into the terminal

### SSH into an instance

        export EC2_INSTANCE_ID=<instance id>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        ssh $(aws --profile $AWS_PROFILE --region $AWS_REGION \
                ec2 describe-instances --instance-ids $EC2_INSTANCE_ID \
                                       --query "Reservations[*].Instances[*].PrivateIpAddress" \
                                       --output text)

### Capture stream latency
This will show which person identifier that has a lot of profile

        export EC2_INSTANCE_ID=<instance id>;\
        export SHARD_ID=<shard id>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        ssh $(aws --profile $AWS_PROFILE --region $AWS_REGION \
                ec2 describe-instances --instance-ids $EC2_INSTANCE_ID \
                                       --query "Reservations[*].Instances[*].PrivateIpAddress" \
                                       --output text) \
               'bash -s' < person_identifier_capture_stream.sh $SHARD_ID
               
Once you know the person identifier 
1. You need to go to the LPM dashbord (e.g [US-EAST-1 PROD](us-east-1.lift.acquia.com), [EU-CENTRAL-1 PROD](eu-central-1.lift.acquia.com), etc)
2. Sign in
3. Navigate to Configure >> System Applications (in the System Data screen) >> Kinesis
4. Look for `kinesis.recordProcessor.personCapture.personIdentifierSkipList` and add the person identitifier (found from the script above)
5. Save and wait for at most 15 mins (cache gets expired every 15 mins)

### Restarting a person capture processor service
This will restart the awspersoncapture service in the instance

        export EC2_INSTANCE_ID=<instance id>;\
        export ENVIRONMENT=<environment>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        ssh $(aws --profile $AWS_PROFILE --region $AWS_REGION \
                    ec2 describe-instances --instance-ids $EC2_INSTANCE_ID \
                                           --query "Reservations[*].Instances[*].PrivateIpAddress"\
                                           --output text)\
                   'bash -s' < restart_personcapture_service.sh $AWS_REGION $EC2_INSTANCE_ID $ENVIRONMENT
