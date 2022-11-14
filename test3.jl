#This is a test function intended to verify the working of functions in GetInfo.jl
include("GetInfo.jl")

print("Getting network details : ")

default_route_gen!()

default_gateway,subnet_id = get_default_route()

print("Subnet ID is $(subnet_id) and Default gateway @ $(default_gateway)\n")

print("Getting hosts on network......\n")

hosts_gen!(subnet_id)

arp_table_gen!()

devices = get_hosts_arp(my_ip,default_gateway)
#devices = get_hosts(my_ip,default_gateway)

for dev in devices
	sleep(2)
	print("Host @ $(dev) is up.\n")
end

print("******************\n")

print("Finding listeners on port 2000....\n")
filtered_hosts = get_open_ports(devices,2000)

for host in values(filtered_hosts)
	print("Found $(host) !\n")
end
