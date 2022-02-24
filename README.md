# Ways to secure an AWS Account
## Overview
As we are using AWS cloud, I would like to provide best-practices along with the high level tasks that can be applied with AWS and other tools.

**Assumption:** Task explicitly didnt mention about MFA, root account usage, possible usage of AWS creds (secret and secret access key) that dont expire.

**Solution:** 1. Enable 2-factor authentication on all web console AWS accounts including root account. Apply an IAM in-line policy ex: "IAM-POLICY-MFA" such that you can enforce users to authenticate 2 times (1st time with their console password and then MFAA token) along with additional rule that deny all services if user didnt setup MFA).

**Task:** 
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowViewAccountInfo",
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy",
                "iam:ListVirtualMFADevices"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowManageOwnPasswords",
            "Effect": "Allow",
            "Action": [
                "iam:ChangePassword",
                "iam:GetUser"
            ],
            "Resource": "arn:aws:iam::*:user/${aws:username}"
        },
        {
            "Sid": "AllowManageOwnAccessKeys",
            "Effect": "Allow",
            "Action": [
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:ListAccessKeys",
                "iam:UpdateAccessKey"
            ],
            "Resource": "arn:aws:iam::*:user/${aws:username}"
        },
        {
            "Sid": "AllowManageOwnSigningCertificates",
            "Effect": "Allow",
            "Action": [
                "iam:DeleteSigningCertificate",
                "iam:ListSigningCertificates",
                "iam:UpdateSigningCertificate",
                "iam:UploadSigningCertificate"
            ],
            "Resource": "arn:aws:iam::*:user/${aws:username}"
        },
        {
            "Sid": "AllowManageOwnSSHPublicKeys",
            "Effect": "Allow",
            "Action": [
                "iam:DeleteSSHPublicKey",
                "iam:GetSSHPublicKey",
                "iam:ListSSHPublicKeys",
                "iam:UpdateSSHPublicKey",
                "iam:UploadSSHPublicKey"
            ],
            "Resource": "arn:aws:iam::*:user/${aws:username}"
        },
        {
            "Sid": "AllowManageOwnGitCredentials",
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceSpecificCredential",
                "iam:DeleteServiceSpecificCredential",
                "iam:ListServiceSpecificCredentials",
                "iam:ResetServiceSpecificCredential",
                "iam:UpdateServiceSpecificCredential"
            ],
            "Resource": "arn:aws:iam::*:user/${aws:username}"
        },
        {
            "Sid": "AllowManageOwnVirtualMFADevice",
            "Effect": "Allow",
            "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice"
            ],
            "Resource": "arn:aws:iam::*:mfa/${aws:username}"
        },
        {
            "Sid": "AllowManageOwnUserMFA",
            "Effect": "Allow",
            "Action": [
                "iam:DeactivateMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ResyncMFADevice"
            ],
            "Resource": "arn:aws:iam::*:user/${aws:username}"
        },
        {
            "Sid": "DenyAllExceptListedIfNoMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:GetUser",
                "iam:ListMFADevices",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice",
                "sts:GetSessionToken"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
```
--- 
**Assumption:** Dont use root account to manage the AWS Infrastructure

**Task:** Root user should have MFA. Root user should create new User with required access to maintain infra i.e. by creating a seperate account for managing infrastructure and create least permissive IAM Users.

---

**Assumption:** Dont use AWS creds (secret and secret access key) that dont expire and dont configure them in local or in remote CI-CD or IaC or CaC server

**Solution:** Use temporary token that gets generated by the use if a role.

**Task:** To use terraform to setup temporary AWS credentials in Hashicorp's Vault i.e. integrate Vault with Infrastructure as Code using Terraform to use temporary AWS credentials instead of a locally stored AWS Profile.

I dont want to "export AWS_PROFILE=terraform" since it poses risk without extra layer of security i.e. without use of username and password, just with help of access keys in local which usually dont expire unless deactivated from console manually or via aws-cli, user can connect to AWS. 

Vault token will be stored in Parameter store in AWS SSM with key "/app/vault/token". The value of this key will be picked up in vault provider.tf with data reference i.e. dta.aws_ssm_parameter.token.value

Apart from couple of above Best practices, now i am focused on providing ELK to monitor logs and app information with its ip address. we can even integrate grafana using helm charts and integrate to current code.

## The high level steps are as follows:

I configured terraform to create a VPC (on us-west-1 by default) with two availability zones, each one with two subnets, one public and one private. The public subnets contain a single NAT, a bastion host and two ELBs - one for Jenkins and one for ELK. 

The bastion host is used as an SSH jump host. The private subnets contain an EKS master and a worker group with two autoscaling groups, one in each subnet, three Consul servers, an ELK server, a Jenkins master and Jenkins node and a MySQL server. 

All servers except for the bastion host are configured as Consul clients with the appropriate health checks. 

Filebeats is installed on all servers except the bastion host, and on kubernetes. The MySQL and system modules are enabled, and the sample application logs are collected and shipped to elasticsearch. Logstash is installed but currently not in use.

The Jenkins node is automatically configured to the Jenkins master.

Metrics server is installed on EKS for HPA.

Once the Jenkins is up and the required credentials are entered, you can configure a pipeline job to get the phonebook app from git, docker it, test it, and deploy it to EKS, on two pods with a load-balancer. The deployment includes and liveliness and readiness probe, and HPA definitions. The Jenkins pipeline also runs a basic load test on the application automatically.

### Steps-to-produce:

Provisioning is done by terraform, as is the initial python installation and all the Consul definitions on non-k8s servers. Everything else is done via Ansible, running modules, scripts, helm installation, etc.

Once the Jenkins server is up, an SSH node is defined with credentials. Docker credentials and a git SSH key are required, before a Jenkins pipeline that pulls a Jenkinsfile from the sample code.

Define Slack credentials via a secret text to Jenkins, and then configure the Jenkins master to use them (via Manage Jenkins) to get a Slack message with the ELB DNS of the application. It takes the ELB several minutes to become available after the initial build.

Requirements:
You will need a machine with the following installed on it to run the enviroment:

AWS CLI
python 3.6
terraform 0.12.20
eks 17.24.0
aws provider v3.74
ansible 2.9.2
git
Ansible vault

To run:
git clone https://github.com/Shashankreddysunkara/instaFreight-task.git

Create terraform statefile S3 bucket:
cd terraform/global/s3
terraform init
terraform validate
terraform plan -out S3_state.tfplan
terraform apply "S3_state.tfplan"

Provision:
cd ../VPC
sudo ansible-vault encrypt_string --name mysql_root_pass
sudo ansible-vault encrypt_string --name mysql_app_pass
sudo ansible-vault encrypt_string --name mysqld_exporter_pass
terraform init
terraform validate
terraform plan -out VPC_project.tfplan
terraform apply "VPC_project.tfplan"

Configure/Install:
chmod 400 VPC-demo-key.pem ansible-playbook ../../../Ansible/jenkins_playbook.yml -i hosts.INI

## To run the Jenkins playbook:
logon to Jenkins master on port 8080 (u/p admin)
add dockerhub credentials with the id "dockerhub.creds"
add git credentials.
add slack credentials (secret text) and configure them to Jenkins (manage Jenkins, scroll all the way to the bottom, and define slack)
configure node to work with existing ubuntu credentials and no non-verifying host strategy
create pipeline from scm, choose git, give it the repo to run a sample app and your git credentials, and set it up to be triggered by git push. Then set up a webhook in GitHub on your copy of the phonebook repo.
run the build job.

The build also sends the address via Slack, if you have that configured in your Jenkins.

## To load the ELK dashboard:
To get to the ELK server, use the ELK load-balancer DNS address printed out by terraform and access it on the 5601 port.
Go to Kibana
Click on Management
Click on Saved Objects
Click on the Import button
Browse ELKdashboards.ndjson in this repo
Import. 

The dashboards and info all start with sample app.

## To bring everything down:
Terraform may have issues bringing the load balancers down. To avoid these issues,try by deleting the load balancers through the AWS console.
Once the load-balancers is down, cd into the terraform/global/VPC directory and run:
terraform destroy

The s3 statefile bucket is set to not allow it to be accidentaly destroyed. Make sure you know what you're doing before destroying it.

##Challenges faced
1. Hashicorp aws provider version >~4.0.0 is having issues, so used ~>3.74
Issue link: https://github.com/hashicorp/terraform-provider-aws/issues/23125
2. EKS module version: Most of keys became unsupportive with 18.7.2, so used explicit version 17.24.0. 
Issue Link: https://github.com/hashicorp/learn-terraform-provision-eks-cluster/issues/55


## END Results: Please access below URLs which are still active. I will destroy entire infra after you viewed it.

In total 75 resources got created.
## Kibana URLs:
	1. Kibana Discover for Logs:  http://elk-elb-1506963224.us-west-1.elb.amazonaws.com:5601/app/kibana
	2. Kibana Dashboard for app info: http://elk-elb-1506963224.us-west-1.elb.amazonaws.com:5601/goto/2cb4ba92df03433347f7c595e8a55d71



## Output of Ansible playbooks run:
Ansible playbook output:


sunny@sunny:~/instafreight_task/instafreight/terraform/global/VPC$ sudo ansible-playbook ../../../Ansible/jenkins_playbook.yml -i hosts.INI
[sudo] password for sunny:
Vault password:

PLAY [jenkins_server, all_nodes, db_servers, ELK_server, consul_servers] ********************************************

TASK [Gathering Facts] **********************************************************************************************
ok: [10.0.3.41]
ok: [10.0.3.94]
ok: [10.0.4.50]
ok: [10.0.3.27]
ok: [10.0.4.160]
ok: [10.0.3.17]
ok: [10.0.4.13]

TASK [include_role : docker] ****************************************************************************************
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]

TASK [Create docker group] ******************************************************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [docker : Ensure old versions of Docker are not installed.] ****************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [docker : Ensure dependencies are installed.] ******************************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [docker : Add Docker apt key.] *********************************************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [docker : Add Docker repository.] ******************************************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [Add the docker group to ubuntu] *******************************************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [docker : Install version specific Docker on Ubuntu.] **********************************************************
skipping: [10.0.3.27]
skipping: [10.0.4.50]

TASK [docker : Install Docker.] *************************************************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [docker : Ensure Docker is started and enabled at boot.] *******************************************************
ok: [10.0.3.27]
ok: [10.0.4.50]

TASK [Ensure docker users are added to the docker group.] ***********************************************************

TASK [include_role : mysql] *****************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.4.50]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]

TASK [mysql : Install the MySQL packages] ***************************************************************************
ok: [10.0.3.94]

TASK [mysql : Update MySQL root password for all root accounts] *****************************************************
ok: [10.0.3.94] => (item=ip-10-0-3-94)
ok: [10.0.3.94] => (item=127.0.0.1)
ok: [10.0.3.94] => (item=::1)
ok: [10.0.3.94] => (item=localhost)
[WARNING]: Module did not set no_log for update_password

TASK [mysql : Copy the templates to their respective destination] ***************************************************
ok: [10.0.3.94] => (item={u'dest': u'/etc/mysql/my.cnf', u'src': u'my.cnf.j2'})
ok: [10.0.3.94] => (item={u'dest': u'~/.my.cnf', u'src': u'root.cnf.j2', u'mode': u'600'})
changed: [10.0.3.94] => (item={u'dest': u'/etc/.mysqld_exporter.cnf', u'src': u'mysqld_exporter.cnf.j2'})

TASK [mysql : Ensure Anonymous user(s) are not in the database] *****************************************************
ok: [10.0.3.94] => (item=localhost)
ok: [10.0.3.94] => (item=ip-10-0-3-94)

TASK [mysql : Create phonebook app MySQL user] **********************************************************************
ok: [10.0.3.94]

TASK [mysql : Create MySQL exporter user] ***************************************************************************
ok: [10.0.3.94]

TASK [mysql : Copy database creation file] **************************************************************************
ok: [10.0.3.94]

TASK [mysql : Create the phonebook database] ************************************************************************
changed: [10.0.3.94]

TASK [mysql : Remove the test database] *****************************************************************************
ok: [10.0.3.94]

TASK [mysql : Install MySQL node exporter] **************************************************************************
changed: [10.0.3.94]

TASK [include_role : ELK] *******************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]

TASK [Install basic ELK stack] **************************************************************************************
changed: [10.0.4.160]

TASK [ELK : Copy elasticsearch configs] *****************************************************************************
ok: [10.0.4.160]

TASK [ELK : Copy kibana configs] ************************************************************************************
ok: [10.0.4.160]

TASK [ELK : Copy logstash configs] **********************************************************************************
ok: [10.0.4.160]

RUNNING HANDLER [mysql : Restart MySQL] *****************************************************************************
changed: [10.0.3.94]

TASK [Install Java for Debian on all nodes.] ************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Copy jenkins docker YAML file] ********************************************************************************
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.3.27]

TASK [Run Jenkins] **************************************************************************************************
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.3.27]

TASK [Add an apt signing key for Kubernetes] ************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Adding apt repository for Kubernetes] *************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Install kubectl] **********************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Install iam authenticator] ************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Install aws cli] **********************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Create SSH key and known host key for node] *******************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Fetch the know host key to local machine] *********************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy known host key to Jenkins master] ************************************************************************
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.3.27]

TASK [Copy create node credentials script] **************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Creates directory] ********************************************************************************************
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.3.27]

TASK [Update Jenkins master known hosts] ****************************************************************************
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.3.27]

TASK [Wait for port 8080 to become open on the jenkins master.] *****************************************************
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.4.160]
skipping: [10.0.3.17]
ok: [10.0.3.27]

TASK [Create node credentials] **************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy create node script] **************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Create node] **************************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy kubeconfig to node] **************************************************************************************
skipping: [10.0.3.27] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)
skipping: [10.0.3.94] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)
skipping: [10.0.4.160] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)
skipping: [10.0.3.41] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)
skipping: [10.0.4.13] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)
skipping: [10.0.3.17] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)
ok: [10.0.4.50] => (item=/home/sunny/instafreight_task/instafreight/Ansible/../terraform/global/VPC/kubeconfig_ops-eks-y5ZFfX3G)

TASK [Copy helm-consul-values.yaml to node] *************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy prometheus-values.yml to node] ***************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy grafana-values.yml to node] ******************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy grafana-dashboards.yml to node] **************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Copy filebeat-kubernetes.yaml to node] ************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Run consul helm install] **************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Run coreDNS update] *******************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
changed: [10.0.4.50]

TASK [Install jmeter] ***********************************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
skipping: [10.0.3.41]
skipping: [10.0.4.13]
skipping: [10.0.3.17]
ok: [10.0.4.50]

TASK [Copy filebeat.yml to servers] *********************************************************************************
changed: [10.0.3.27]
changed: [10.0.4.160]
changed: [10.0.3.41]
changed: [10.0.3.94]
changed: [10.0.4.50]
changed: [10.0.4.13]
changed: [10.0.3.17]

TASK [Copy system.yml to servers] ***********************************************************************************
changed: [10.0.3.41]
changed: [10.0.3.27]
changed: [10.0.3.94]
changed: [10.0.4.50]
changed: [10.0.4.160]
changed: [10.0.4.13]
changed: [10.0.3.17]

TASK [Copy mysql.yml to servers] ************************************************************************************
changed: [10.0.3.94]
changed: [10.0.4.50]
changed: [10.0.3.27]
changed: [10.0.3.41]
changed: [10.0.4.160]
changed: [10.0.3.17]
changed: [10.0.4.13]

TASK [Run filebeat installation] ************************************************************************************
changed: [10.0.3.94]
changed: [10.0.4.160]
changed: [10.0.3.41]
changed: [10.0.4.50]
changed: [10.0.3.27]
changed: [10.0.3.17]
changed: [10.0.4.13]

TASK [Run consul_exporter installation] *****************************************************************************
skipping: [10.0.3.27]
skipping: [10.0.4.50]
skipping: [10.0.3.94]
skipping: [10.0.4.160]
changed: [10.0.3.41]
changed: [10.0.4.13]
changed: [10.0.3.17]

PLAY RECAP **********************************************************************************************************
10.0.3.17                  : ok=6    changed=5    unreachable=0    failed=0    skipped=30   rescued=0    ignored=0
10.0.3.27                  : ok=19   changed=8    unreachable=0    failed=0    skipped=26   rescued=0    ignored=0
10.0.3.41                  : ok=6    changed=5    unreachable=0    failed=0    skipped=30   rescued=0    ignored=0
10.0.3.94                  : ok=16   changed=8    unreachable=0    failed=0    skipped=30   rescued=0    ignored=0
10.0.4.13                  : ok=6    changed=5    unreachable=0    failed=0    skipped=30   rescued=0    ignored=0
10.0.4.160                 : ok=9    changed=5    unreachable=0    failed=0    skipped=30   rescued=0    ignored=0
10.0.4.50                  : ok=34   changed=15   unreachable=0    failed=0    skipped=11   rescued=0    ignored=0


### Terraform output is large, so couldnt provide it in this file but will share it if required.