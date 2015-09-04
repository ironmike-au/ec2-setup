#!/bin/bash

#####
# Define your preferences below
#####

# Enter your top-level domain name
DOMAIN="example.com"

# If true, the hostname will be pulled from an the instance tag you specify
# If false, the hostname will use the current instance id
HOSTNAME_USE_TAG=true

# If you want to read the hostname from an EC2 instance tag, specify the tag name here.
HOSTNAME_TAG="hostname"

# Specify if the FQDN will include the availability zone this instance lives in
# For example, hostname.ap-southeast-2a.example.com
# If you set this false, the FQDN is just hostname.example.com
APPEND_ZONE=true

# Define if this instance DNS will be set using it's private or public IP
USE_PUBLIC_IPV4=true

# Specify the Route 53 "hosted zone id" to push these records to.
# You can find this in the list of hosted zones in the AWS Management Console
R53_HOSTED_ZONE_ID="B6UN4N53A3N1ZO"


#####
# Collect initial data about this instance
#####

INSTANCE_PUBLIC_IPV4=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
INSTANCE_ID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
INSTANCE_ZONE=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`


#####
# PERFORM INITIAL SETUP
####

if $HOSTNAME_USE_TAG;
then
   echo $INSTANCE_ID
    HOSTNAME=`/usr/local/bin/aws ec2 describe-tags \
    --filters "Name=resource-type,Values=instance" \
    "Name=resource-id,Values=$INSTANCE_ID" \
    "Name=key,Values=hostname" | grep -Po '(?<="Value": ")[^"]*'`
else
    HOSTNAME=$INSTANCE_ID
fi

if $USE_PUBLIC_IPV4;
then
    IP=$INSTANCE_PUBLIC_IPV4
else
    IP=`ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'`
fi

if $APPEND_ZONE;
then
    FQDN=$HOSTNAME.$INSTANCE_ZONE.$DOMAIN
else
    FQDN=$HOSTNAME.$DOMAIN
fi

#####
# PUSH HOSTNAME
####

# Set our local hostname
hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname

# Add FQDN to hosts file
cat<<EOF > /etc/hosts
# This file is automatically genreated by ec2-hostname script
127.0.0.1 localhost
$IP $FQDN $HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

#####
# PUSH R53 DNS
#####

cat<<EOF > /usr/local/ec2/r53-request.json
{
  "Comment": "Auto-published DNS from ec2-setup.sh",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$FQDN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id $R53_HOSTED_ZONE_ID --change-batch file:///usr/local/ec2/r53-request.json
