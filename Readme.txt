# PROJECT 7 ASSIGNMENT RESPONSE

1. Created a VPC with 10.0.0.0/16 CIDR
2. Created 1 Subnet on 2 of the AZ
	10.0.1.0/24 on AZ 1a corresponding to Zone A
	10.0.2.0/24 on AZ 1b corresponding to Zone B
3. Created an Internet Gateway for the VPC
4. Created 1 Route Table each for the 2 AZ
5. Associated the subnets with the corresponding route table and internet gateway
6. Created a Security group and opened port 22 for ssh and 80 for http
7. Lunch 2 EC2 Instances for the webserver and place them on two AZ {eu-north-la & eu-north-lb}
8. Created a Target Group
9. Created a Network Load Balancer
10. Created an Auto scaling group
	Lunch configuration
	