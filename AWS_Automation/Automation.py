import boto3
import time
from colorama import Fore as c

#create VPC
client = boto3.client("ec2")
vpc = client.create_vpc(CidrBlock='10.0.0.0/16')
vpcid = vpc['Vpc']['VpcId']
print(c.GREEN + "VPC is created with ID:",vpcid)


#attaching internet gateway to the VPC
gateway = client.create_internet_gateway()
create_ig_response = client.create_internet_gateway()
ig_id = create_ig_response["InternetGateway"]["InternetGatewayId"]
print(c.GREEN + "This is gateway Id:", ig_id)
client.attach_internet_gateway(InternetGatewayId = ig_id,VpcId = vpcid)
print(c.GREEN + "Gateway is attached to VPC", vpcid)


#Create subnet inside the VPC (2 public and two private)

#Public
Pub_subnet1 = client.create_subnet(
    #Name='Public 1',
    AvailabilityZone='us-east-1a',
    CidrBlock='10.0.0.0/20',
    VpcId = vpcid,
)
Pub_subId1 = Pub_subnet1["Subnet"]["SubnetId"]
print(c.RED + "Public Subnet 1 ID is", Pub_subId1)


Pub_subnet2 = client.create_subnet(
    #Name='Public 2',
    AvailabilityZone='us-east-1b',
    CidrBlock='10.0.32.0/20',
    VpcId = vpcid,
)
Pub_subId2 = Pub_subnet2["Subnet"]["SubnetId"]
print(c.RED + "Public Subnet 2 ID is", Pub_subId2)


#Private
Private_subnet1 = client.create_subnet(
    #Name='Private 1',
    AvailabilityZone='us-east-1c',
    CidrBlock='10.0.80.0/20',
    VpcId = vpcid,
)
Private_subId1 = Private_subnet1["Subnet"]["SubnetId"]
print(c.RED + "Private Subnet 1 ID is", Private_subId1)



Private_subnet2 = client.create_subnet(
    #Name='Private 2',
    AvailabilityZone='us-east-1d',
    CidrBlock='10.0.48.0/20',
    VpcId = vpcid,
)
Private_subId2 = Private_subnet2["Subnet"]["SubnetId"]
print(c.RED + "Private Subnet 2 ID is", Private_subId2)


#Route table association to Public subnets
route_table = client.create_route_table(VpcId = vpcid)
routeid = route_table['RouteTable']['RouteTableId']
route = client.create_route(
    RouteTableId = routeid,
    DestinationCidrBlock = '0.0.0.0/0',
    GatewayId = ig_id
)
#attaching to the specific subnet
client.associate_route_table(SubnetId = Pub_subId1,RouteTableId = routeid,)
print(c.GREEN + "Route table attached to Public subnet 1")

#Route table creation and attachment to a subnet...
route_table2 = client.create_route_table(VpcId = vpcid)
routeid2 = route_table2['RouteTable']['RouteTableId']
route = client.create_route(
    RouteTableId = routeid2,
    DestinationCidrBlock = '0.0.0.0/0',
    GatewayId = ig_id
)
#attaching to the specific subnet
client.associate_route_table(SubnetId = Pub_subId2,RouteTableId = routeid2,)
print(c.GREEN + "Route table attached to public subnet 2")

#creation to connect to NAT Gateway....Inside public 1 subnet
NATGateway = client.create_nat_gateway(
    AllocationId = 'eipalloc-050e422bfc50c8794',
    SubnetId = Pub_subId1
)
NatId = NATGateway['NatGateway']['NatGatewayId']
print(c.YELLOW + "Waiting for NAT to be available ...... approx. 30 sec")
time.sleep(30)
print(c.GREEN + "NAT Created in subnet 1 with NatId :",NatId)


#creating private route tables....
Private_route_table = client.create_route_table(VpcId = vpcid)
privaterouteid = Private_route_table['RouteTable']['RouteTableId']
route = client.create_route(
    RouteTableId = privaterouteid,
    DestinationCidrBlock = '0.0.0.0/0',
    GatewayId = NatId
)
print(c.GREEN + "Private route id is", privaterouteid)

#for second private subnet.....
Private_route_table2 = client.create_route_table(VpcId = vpcid)
privaterouteid2 = Private_route_table2['RouteTable']['RouteTableId']
route = client.create_route(
    RouteTableId = privaterouteid2,
    DestinationCidrBlock = '0.0.0.0/0',
    GatewayId = NatId
)
print(c.GREEN + "Private route id is", privaterouteid2)







