#testing server code
include("GetInfo.jl")
#using Sockets

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
pool = get_open_ports(devices,2000)

for host in values(pool)
	print("Found $(host) !\n")
end

println("$(pool)")

N_pool = length(pool) # find out the number of devices in the pool.

@sync for device_id in keys(pool)
	@async begin
		info_sock = connect(pool[device_id], 2000)
		write(info_sock, "$(my_ip),$(device_id),$(N_pool)")
		#readline(conn, keep=true)
		println("Sent Pool info and device id to $(device_id) with ip address $(pool[device_id]))")
		close(info_sock)
	end
end

control = listen(my_ip,2000)
println("Waiting for requests.....")
while true
	conn = accept(control)
	@async begin  # @async allows the simultaneous handling of multiple connections.
		try
			request = readline(conn)  #Request of the form GET,src_dev,needed_dev\n
			cmd,src_dev,needed_dev = split(request,",")
			needed_id = parse(Int,needed_dev)
			write(conn,"$(pool[needed_id])")
			close(conn)
			println("Device $(src_dev) @ $(pool[parse(Int,src_dev)]) asked for $(needed_dev)")
		catch e
			println("An error has occured!")
			write(conn,"An invalid query was possibly made!")
			close(conn)
		end
	end
end

