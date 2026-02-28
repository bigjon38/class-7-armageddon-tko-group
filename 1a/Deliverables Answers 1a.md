A. Why is DB inbound source restricted to the EC2 security group? 
Inbound database traffic is restricted to the EC2 security group so only application servers can connect, reducing exposure and following security best practices.


B. What port does MySQL use?
It uses port 3306


C. Why is Secrets Manager better than storing creds in code/user-data?
Storing credentials in code is unsafe because anyone who can see the code can see the secrets. A secrets manager stores encrypted credentials, only lets authorized systems retrieve them and can rotate them automatically.

Why each rule exists
Each security group controls which traffic can reach resources in your VPC. Security groups act like a stateful firewall to block unwanted connections and protect your servers and databases.

What would break if removed
EC2 Security Group
Inbound Traffic:
If removed, the web app would no longer be reachable over HTTP (port 80) and SSH access from the trusted IP would stop working.
Outbound Traffic:
If outbound rules were removed, the EC2 instance could not talk to other services inside or outside the VPC.

Database Security Group
Inbound Traffic:
If the MySQL inbound rule (port 3306) were removed, the EC2 instance could not connect to the RDS database.

Why broader access is forbidden
Allowing wider access (SSH from anywhere or DB access from anywhere) breaks the principle of least privilege. More access means more ways for attackers to reach your systems and a higher risk of exposing sensitive data.

Why this role exists
The IAM Role lets EC2 get temporary permissions to read secrets without storing long‑term credentials on the instance. This reduces secret exposure and makes it easy for new instances to use the same permissions.

Why it can read this secret
The EC2 instance can read the secret because the IAM Role attached to it includes a policy that allows secretsmanager:GetSecretValue for that secret.

Why it cannot read others
The role’s policy restricts access to secrets with the ARN prefix arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:lab/rds/mysql*. That wildcard limits which secrets the role can access. If the policy used a single exact ARN (no wildcard), it would be limited to that one secret only. To allow other secrets, their ARNs would need to be added to the policy.










