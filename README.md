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
                   

### Finding the number of records that still needs to be processed by REDSHIFT
This will give you the number of records in the `unprocessedData`

        export ENVIRONMENT=<environment>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        export DATE=<today's date in the format YYYY-MM-DD e.g: 2020-08-20> ;\
        aws --profile $ENVIRONMENT --region $AWS_REGION s3 ls s3://lift.$ENVIRONMENT.$AWS_REGION.runtime/kinesisredshift/unprocessedData/$DATE --recursive --human-readable --summarize

Note: This will take a **really long time** if it was run in production on us-east-1. What I suggest is to run the above commands in `nohup`
Steps:
1. Connect to an instance in the right region (see [SSH into an instance](#ssh-into-an-instance))
2. Run the command using `nohup`
        
        export ENVIRONMENT=<environment>;\
        export AWS_PROFILE=<aws profile>;\
        export AWS_REGION=<aws region>;\
        export DATE=<today's date in the format YYYY-MM-DD e.g: 2020-08-20> ;\
        nohup aws --profile $ENVIRONMENT --region $AWS_REGION s3 ls s3://lift.$ENVIRONMENT.$AWS_REGION.runtime/kinesisredshift/unprocessedData/$DATE --recursive --human-readable --summarize &
        
### Moving files back from processedData to unprocessedData
This is not a perfect solution but given how late we worked to stabilizing the system, this is best that we can do

First you need to get a list of accounts.

I ran aws command below
		
	export ENVIRONMENT=<environment>;\
	export AWS_PROFILE=<aws profile>;\
	export AWS_REGION=<aws region>;\
	export DATE=<date in the format YYYY-MM-DD e.g: 2020-08-20> ;\
	aws --profile $ENVIRONMENT --region $AWS_REGION s3 ls s3://lift.$ENVIRONMENT.$AWS_REGION.runtime/kinesisredshift/unprocessedData/$DATE

This will print out the list of all accounts. Next we need to format the output and place them in the python script below

```python
#!/bin/python

accounts = [
	"ACQUIAWEB", "ACROMEDIA", "AFPM", "AMA", "AMCP", "AMD", "AVETTA", "BACredomatic", "BCBSMN", "BESSEMER", "BLACKBOARD", "CASE", "CCF", "CDW", "CHARLESRIVERLABS", "CHEP", "CHEVRON", "COMMUNITYHEALTH", "CONAGRA", "CORELLE", "CUMMINS", "DONNELLEY", "EASTERNBANK", "EGNYTE", "ELEVATEDTHIRD", "ENTERPRISEBANK", "FAMILYTALK", "FANNIEMAE", "FFW", "FIRSTHAWAIIANBANK", "FSU", "GLOBALATLANTIC", "GRANDCANYONUNI", "ILAO", "INFOVISTA", "JCCMANHATTAN", "JEWELERSMUTUAL", "JohnnsonOutdoors", "KBR", "KCTS", "KRONOS", "LODGECASTIRON", "MARS", "MDVIP", "MSK", "MULESOFT", "NABORS", "NASDAQ", "NEWELL", "NJPA", "NORTHWELL", "NYITS", "OOMPH", "OSU", "PANASONIC", "PAYCHEX", "PERFORCE", "PHASE2", "PatientPoint", "RELATEDCOMPANIES", "RLHC", "RODANFIELDS", "SECURITYBENEFIT", "STAPLES", "STAPLESINC", "STEWARD", "SUMMIT", "TEC", "TEXASCAPITAL", "UCLAEXT", "UNITEDRENTALS", "UNIVOFWASHINGTON", "UNIVUTAHHEALTH", "UNLEASHED", "UnderwritersLaborat", "Videotron", "Voya", "WEBSTERBANK", "WENDYS", "WRF"]

tables = ["kinesis_staged_campaign_event", "kinesis_staged_event", "kinesis_staged_matched_segment", "kinesis_staged_person", "kinesis_staged_person_identifier", "kinesis_staged_person_ranking", "kinesis_staged_person_ranking_item", "kinesis_staged_person_ranking_summary", "kinesis_staged_touch"]

multiTentant_tables = ["kinesis_staged_campaign_event", "kinesis_staged_customer_content", "kinesis_staged_event", "kinesis_staged_matched_segment", "kinesis_staged_person", "kinesis_staged_person_identifier", "kinesis_staged_person_link", "kinesis_staged_person_ranking", "kinesis_staged_person_ranking_item", "kinesis_staged_person_ranking_summary", "kinesis_staged_touch"]

dates = ["2020-07-21", "2020-07-22", "2020-07-23"]

region = "us-east-1"

print("FOR SINGLE TENTANT TABLES: \n")
for date in dates:
	for account in accounts:
		for table in multiTentant_tables:
			print("aws s3 mv s3://lift.production."+region+".runtime/kinesisredshift/processedData/" + date +"/" + account + "/"+ table + "/ s3://lift.production."+region+".runtime/kinesisredshift/unprocessedData/"+ date + "/" + account + "/"+ table +"/ --recursive ;\\")

print("==========================\n")

print("FOR MULTI TENTANT TABLES: \n")
print("============================ ")
for date in dates:
	for table in multiTentant_tables:
		print("aws s3 mv s3://lift.production."+region+".runtime/kinesisredshift/processedData/"+ date +"/" + table + "/ s3://lift.production." + region + ".runtime/kinesisredshift/unprocessedData/"+ date + "/" + table + "/ --recursive ;\\")
```

This will generate a list of aws commands that you need to copy and pasted into a terminal
