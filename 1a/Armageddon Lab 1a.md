Armageddon Lab 1a

Goal
Deploy a simple web app on an EC2 instance that can:
Insert a note into RDS MySQL
List notes from the database

Requirements
RDS MySQL instance in a private subnet (or publicly accessible if you want ultra-simple)
EC2 instance running a Python Flask app
Security groups allowing EC2 → RDS on port 3306
Credentials stored in AWS Secrets Manager (recommended) or plain env vars (simpler)

PLEASE MAKE SURE NAMES FOR THE MySQL ARE CONSISTENT

VPC (VPC > create VPC)
1. VPC & more
Custom IPv4 CIDR block
IPv6 CIDR block and Tenancy: default
AZ: choose 1/2/3(Number of private and public subnets is base on the number of AZ chosen, CIDR blocks must be customized and end in /24, 3 is preferred for this)
Nat Gateway: None
VPC Endpoints: None


Security Groups (Security Groups > Create security group)
1. EC2 Security Group Inbound Rules
Name: ec2-lab-sg
Type: HTTP(80)
Protocol: TCP
Source: Everywhere(0.0.0.0/0)
Type: SSH(22)
Protocol: TCP
Source: MyIP

EC2 Security Group Outbound Rules
Leave alone

2. RDS Security Group Inbound Rules
Name: private-db-sg
Type: MySQL/Aurora(3306)
Protocol: TCP
Source: EC2 SG

EC2 Security Group Outbound Rules
Leave alone


RDS Subnet Groups (Aurora and RDS > subnet groups > create DB subnet group)
1. Create DB Subnet Group
Name: armageddon-rds-subnet-group
Description: RDS subnet group
VPC: Select target VPC

2. Subnets
Select at least two private subnets. This lab only uses single-AZ but multiple AZ is scalable and a good practice
Those should be the fully private/data-tier subnets


RDS MySQL Database Creation (Databases > create database)
1. Database Config
Creation method: Standard(Full Config)
Engine type: MySQL
Engine Version:  Default(MySQL 8.0.43)
Template: Sandbox/Free Tier
Availability: Single AZ DB instance

2. Settings
DB instance identifier: lab-MySQL
Master username: admin
Credential mgmt.: Self managed
Master password: strong password (Store that password in a secure password vault)(For the database credentials, Self Managed is simpler and more reliable. "Managed in AWS Secrets Manager" enables automatic password rotation but it requires advanced setup to work (Lambda function, VPC networking, security group rules, etc.). If not properly configured, the database password won't be synced and will cause connection errors.

3. Instance Config
Instance class: Burstable (db.t4g.micro or db.t3.micro)
Storage: Defaults
Allocated storage: Defaults

4. Connectivity
Compute Resource: Don't connect to EC2
VPC: Same VPC as EC2
DB subnet group: armageddon-rds-subnet-group
Public Access: No
Security Groups(firewall): Remove default, attach private-db-sg
Leave remaining settings default
Create database


Secrets Manager Config (Secrets Manager > store a new secret)
1. Store Database Credentials
Secret type: Credentials for Amazon RDS database
Username: admin
Password: Same password used for RDS
Encryption key: Default
Database: Created database

2. Config Secret
Secret name: lab/rds/mysql
Description: DB credentials for lab-MySQL
Store secret
Record the Secret Name and ARN


IAM Policy and Role (IAM > Policies > create policy > JSON editor)
1. Create IAM Policy
Copy/Paste Inline Policy into JSON editor
Use this line policy to replace the one the one above, replace the * with the secret ARN in Secret manager
Secret Manager  Secrets  Secret names 

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadSpecificSecret",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "arn:aws:secretsmanager:us-west-2:950876749850:secret:lab/rds/mysql*"
        }
    ]
}

Policy name: read-specific{or policy}-secret > create policy

2. Create IAM Role (IAM > Roles > Create Role)
Trusted entity: AWS Service
Use Case: EC2 > EC2 > next(JSON code is auto generated in the next step)
Attach policy: read-specific{or policy}-secret
Role name: ec2-get-db-secret-lab-1a (ec2-get-secret-role)
Description: Allows EC2 instances to retrieve RDS secret


Modify EC2 User Data Script
1. Local Prep
Navigate to preferred working directory
create file named updated_script
open file in VS code
Copy user data script
Update region value to match VPC
save file (autosave helps)


Launch EC2 Instance (EC2 > Instance > Launch instances)
1. EC2 Config
AMI: Amazon Linux 2023
Instance type: t2.micro/t3.micro (or similar)
Key Pair: Create new, download .pem
Network: VPC is same VPC created as RDS, Public Subnet
Auto-assign public IP: Enable
Security Group(firewall):ec2-lab-sg

2. Advanced Details
IAM Instance Profile: ec2-get-db-secret-lab-1a(ec2-get-secret-role)
User data: paste the updated_script.sh (optional)
launch instance


Attach role to EC2 (EC2 > Instance > check mark instance > Actions > Security > Modify IAM role > select your role)

SSH Key Permissions
While EC2 is launching, configure key file(for testing via SSH later, if desired)

cd <key-directory>`
ls chmod 600 <key.pem>
ls -l

Expected result: read/write permissions for owner only.


Application Testing
1. Verify the Application Loads
Copy EC2's public DNS
Open in a browser and confirm the app loads
*If app doesn't load, double check security groups to make sure public HTTP traffic is allowed. Once it has been confirmed that HTTP access works, move on to next step

2. Initialize Database(http://<EC2_PUBLIC_IP>/init)
Copy EC2 public IP address
modify link and paste in browser

From Theo: “If /init hangs or errors, it’s almost always due to one of the following: the RDS SG doesn't allow inbound traffic on port 3306 from the EC2 security group; the RDS instance is not in the same VPC or subnets not routed properly; the EC2 role is missing secretsmanager:GetSecretValue; or the secret doesn't contain the host, username, and password fields.”

Troubleshooting:

If you receive an error, check the following, then test /init again:
RDS SG allows inbound 3306 from EC2 SG
EC2 and RDS are in same VPC
Subnets properly routed in VPC
IAM policy is properly configured with correct permissions
IAM role has the policy attached and is assigned to the EC2 instance
Secret contains host, username, password
Make sure the IAM role is functioning correctly.
SSH into EC2 instance from key file directory:
`ssh -i <key.pem> ec2-user@
Show Role Information:
aws sts get-caller-identity
Retrieve the secret value manually:
aws secretsmanager get-secret-value --secret-id lab/rds/MySQL

3. Write Notes
Paste this link in your browser to poste the first note
http://<EC2_PUBLIC_IP>/add?note=hello

4. Read Notes
Paste this link in your browser to view a list of the notes.
http://<EC2_PUBLIC_IP>/list

