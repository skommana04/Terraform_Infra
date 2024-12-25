# Terraform_Infra

1) creating a main.tf, variables.tf for vpc in modules
2) write a main.tf, variables.tf, terraform.tfvars in root directory.
3) call the vpc module in main.tf(root)

4) create igw 
5) now fetch the availability zones in that region using data block 
6) create the public and private subnets

7) create nat gateway, before this create a elastic ip and attch to natgateway

8) create route tables and attach the route tables to subnets using rta block
--- public subnet route:
outbound traffic to the internet should take igw route 
route table should be associated to public subnet in both the az's

--- private subnet route:
outbound traffic to the internet should take nat gateway route 
route table should be associated to private subnet in both the az's

for the inbound traffic - aws takes care of this implicilty. no need to explicitly specify the inbound route table.
for example inbound traffic coming to the alb, it comes with the alb public ip address, aws knows the alb's ip adress is within the range of public subnet ip's;

heres how the traffic flows:

once the external inbound traffic hits the alb, the alb will hvae the listeners configured based on the traffic protocol. lets say if it is http -the listener port will be 80, if its https:443
then it routes to the one of the healthy ec2 instance in the target group

all these traffic is controlled by the ingress and egress rules in alb security group and target group (ec2 instances) security group.

alb sg:
ingress: (open) port 80/443 for the inbound traffic from anywhere in internet
cidr: 0.0.0.0/0
from:80
to:80

cidr: 0.0.0.0/0
from:443
to:443

egress:
from: 0
to: 0
cidr: 0.0.0.0/0
-----------------------------------

target group rules:
 ingress: any traffic coming to the alb to any of my ports:
 from:0
 to:0
 tcp : -1
 sg: alb.sg

egress:
from: 0
to: 0
cidr: 0.0.0.0/0

9) create a security group 
10) create a ec2 instance with nginx 

next steps:

create pipeline using github actions using github hosted runner
main branch: when should it trigger , when we raise the pull request /push it should do terraform, init,fmt,validate,plan and apply
feature branch pipeline: when should it trigger: only on push and it should do terraform init,fmt,validate,plan-out(plan report)
 configure remote s3 backed and dynamodb for state locking

create alb ,asg, rds
going  to do first pipeline
