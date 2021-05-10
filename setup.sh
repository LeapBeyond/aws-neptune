#!/usr/bin/env bash

cd $(dirname $0)

function banner {
  printf "\n========================================================================================================\n"
  printf "| $1\n"
  printf "========================================================================================================\n"
}

# logout on any exit
trap 'banner "Finished..."' EXIT

usage() {
  echo "Usage: $0 -n <name> [-p profile] [-r <region>] [-a <account> ] [-c <cidr>]" 1>&2
  exit 1
}

while getopts ":p:n:i:r:c:a:" o; do
  case "${o}" in
    r) REGION=${OPTARG}
        ;;
    n) NAME=${OPTARG}
        ;;
    c) CIDR=${OPTARG}
        ;;
    a) ACCOUNT=${OPTARG}
        ;;
    *) usage
        ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${NAME}" ]
then
  usage
fi

banner "Starting"

ROLE="lba_role"
ACCOUNT="${ACCOUNT:=422515236307}"

banner "Assuming admin role"

JSON=$(aws --profile ${PROFILE:=lba_group} sts assume-role --role-arn arn:aws:iam::${ACCOUNT}:role/admin-access --role-session-name $USER --output json)
if [ ! -z "$JSON" ]
then
  aws --profile ${ROLE} configure set aws_access_key_id "$(echo $JSON | jq -r .Credentials.AccessKeyId)"
  aws --profile ${ROLE} configure set aws_secret_access_key "$(echo $JSON | jq -r .Credentials.SecretAccessKey)"
  aws --profile ${ROLE} configure set aws_session_token "$(echo $JSON | jq -r .Credentials.SessionToken)"
  aws --profile ${ROLE} sts get-caller-identity
else
  echo "ERROR: failed to be able to assume the admin role in the target account ${ACCOUNT}"
  exit 1
fi

banner "Fetching test files"

mkdir -p data
cd data
wget https://raw.githubusercontent.com/krlawrence/graph/master/sample-data/air-routes-latest-edges.csv
wget https://raw.githubusercontent.com/krlawrence/graph/master/sample-data/air-routes-latest-nodes.csv
cd ..

banner "Executing terraform"

cat <<EOF |tee terraform.tfvars
aws_region     = "${REGION:=eu-west-2}"
aws_profile    = "${ROLE}"
aws_account_id = "${ACCOUNT}"
vpc_cidr       = "${CIDR:=172.18.0.0/16}"
vpc_name       = "${NAME}"
EOF

terraform init -upgrade=true
terraform apply -var-file=terraform.tfvars
