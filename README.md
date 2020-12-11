# aws-neptune

This repository is used to standup a demonstration of AWS Neptune, their graph database solution. It creates a VPC to hold everything in, a Neptune cluster, an instance that can access Neptune, a Juypter notebook etc for accessing Neptune with examples, and an S3 bucket for storing test data in.

## Prerequisites

It is assumed that:

 - you are running on a Unix-like environment (c.f. MacOS);
 - `aws-cli` client 2.1.7 or later is in the execution path;
 - Terraform 0.13.4 or later is in the execution path;
 - `wget` is in the execution path.

It is also assumed that you are executing with a profile that has suitable access in the LB "group" AWS account, and have permissions to assume the `admin-access` role in the target AWS account.

## Usage

By default the scripts try to build the environment in the "training" account, but that can be overwritten. To setup the environment, execute `setup.sh`

```
% ./setup.sh
Usage: ./setup.sh -n <name> [-p profile] [-r <region>] [-a <account> ] [-c <cidr>]
```

for example:

```
./setup.sh -n neptunedemo
```

Tearing down is similar:

```
./teardown.sh -n neptunedemo
```

Both setting up and tearing down takes quite a few minutes - expect around 10 minutes - to complete.

Once the environment is built, various useful pieces of information are reported by Terraform, e.g.:

```
Outputs:

eip_public_address = 18.133.16.175
jupiter_ro = rahneptune20201211102942965200000006.cluster-ro-ce6eqomcqsmi.eu-west-2.neptune.amazonaws.com
jupiter_rw = rahneptune20201211102942965200000006.cluster-ce6eqomcqsmi.eu-west-2.neptune.amazonaws.com
private_subnet = [
  "172.18.96.0/19",
  "172.18.128.0/19",
  "172.18.160.0/19",
]
public_subnet = [
  "172.18.0.0/19",
  "172.18.32.0/19",
  "172.18.64.0/19",
]
vpc_arn = arn:aws:ec2:eu-west-2:422515236307:vpc/vpc-0d4d115c1194f773f
vpc_id = vpc-0d4d115c1194f773f
```

At this stage it's possible to access both the Juypter notebook, and the instance, via the AWS console in the target account. It is recommended that the instance is accessed that way via Instance Connect, however if you have the Instance Connect client installed locally then the `mssh` tool can be used to SSH into it.

Once on the instance, you can run Gremlin via

```
 ./apache-tinkerpop-gremlin-console-3.4.8/bin/gremlin.sh
```

then from the Gremlin console you can connect to the target Neptune cluster

```
gremlin> :remote connect tinkerpop.server conf/neptune-remote.yaml
gremlin> :remote console
gremlin> g.V().label().groupCount()
gremlin> :quit
```

You may like to refer to this site for some introductory examples of queries with Gremlin: https://www.sungardas.com/en-us/cto-labs-blog/a-beginners-walkthrough-for-building-and-querying-aws-neptune-with-gremlin/

The data used by that site is available in the S3 bucket we have created, and can be bulk loaded into the target cluster from the EC2 instance (see https://docs.aws.amazon.com/neptune/latest/userguide/bulk-load-data.html for more details), e.g.

```
$ curl -X POST \
    -H 'Content-Type: application/json' \
    https://rahneptune20201211102942965200000006.cluster-ce6eqomcqsmi.eu-west-2.neptune.amazonaws.com:8182/loader -d '
    {
      "source" : "s3://rahneptune20201211102937488800000001/air-routes-latest-nodes.csv",
      "format" : "csv",
      "iamRoleArn" : "arn:aws:iam::422515236307:role/rahneptune",
      "region" : "eu-west-2",
      "failOnError" : "FALSE",
      "parallelism" : "MEDIUM",
      "updateSingleCardinalityProperties" : "FALSE",
      "queueRequest" : "TRUE"
    }'

$ curl -X POST \
    -H 'Content-Type: application/json' \
    https://rahneptune20201211102942965200000006.cluster-ce6eqomcqsmi.eu-west-2.neptune.amazonaws.com:8182/loader -d '
    {
      "source" : "s3://rahneptune20201211102937488800000001/air-routes-latest-edges.csv",
      "format" : "csv",
      "iamRoleArn" : "arn:aws:iam::422515236307:role/rahneptune",
      "region" : "eu-west-2",
      "failOnError" : "FALSE",
      "parallelism" : "MEDIUM",
      "updateSingleCardinalityProperties" : "FALSE",
      "queueRequest" : "TRUE"
    }'

$ curl -G 'https://rahneptune20201211102942965200000006.cluster-ce6eqomcqsmi.eu-west-2.neptune.amazonaws.com:8182/loader'
```
