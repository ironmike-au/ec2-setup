## Synopsis

EC2-Setup is a simple bash script that will:

* Set the local hostname to the instance-id OR an EC2 instance tag you specify

* Build an FQDN for the instance using your domain name, hostname, and optionally the current availability zone

* Maps the FQDN to either public or private IPv4 address

* Set the FQDN in /etc/hosts (currently overwrites /etc/hosts every time)

* Securely publish the FQDN to Route 53

## Prerequisites

This script relies upon IAM Roles to gain access to read EC2 tags and push Route 53 DNS changes.

You'll need to create an IAM Role with the Role Type set to Amazon EC2, to allow your instance to call Route 53 (change-resource-record-sets) and EC2 (describe-tags) on your behalf.

The included example.iam can be used to help you create the necessary permissions for your IAM role.

Locally on the host, you will need to install curl and the AWS CLI, and configure it to use the instance's local region.

## How To Use

The script needs to run with elevated permissions so that it can modify /etc/hosts and /etc/hostname

ec2-setup.sh is designed to be run at boot. I like to bake it into my custom AMIs. An example upstart file is included. You need to ensure that it runs after networking is up.

## Contributors

Improvements to this script are warmly welcomed. Best way to reach me is @otakumike


