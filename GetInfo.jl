#This program will write all the necessary info about the local network into some files and display them.
using Sockets

const my_ip = getipaddr()
print("Machine ip is $(my_ip)\n")

function default_route_gen!()
	open("default_route.txt","w") do f
		redirect_stdio(stdout=f) do
			run(`ip route`)
		end
	end
end


function get_default_route()
	ip,subnet_id = open("default_route.txt") do f
		a = readlines(f)
		ip =IPv4( split(a[1]," ")[3])
		subnet_id = split(a[2]," ")[1]
		return ip,subnet_id
	end
	return ip,subnet_id
end


#Get all available hosts on the network by doing an NMAP scan over the network.
function hosts_gen!(subnet_id::AbstractString)
	open("hosts.txt","w") do f
			redirect_stdio(stdout = f) do
				run(`nmap -sn $(subnet_id)`)
			end
	end
end


function get_hosts(my_ip::IPv4,default_gateway::IPv4)
	addrs = open("hosts.txt") do f 
		text = readlines(f)
		i = 2
		addrs = []
		while true
			try
				addr = IPv4(split(text[i]," ")[end])
				!(isequal(addr,my_ip)||isequal(addr,default_gateway)) && push!(addrs,addr)
			catch e
				if isa(e,BoundsError)
					return addrs
				end
			end
			i+=2
		end
	end
	return addrs
end

#Use arp_table_gen! and get_hosts_arp if windows firewall blocks the icmp request messages used by nmap to discover hosts on the network.
function arp_table_gen!()
	open("arp.txt","w") do f
		redirect_stdio(stdout=f) do
			run(`cat /proc/net/arp`)  #This command is UNIX specific.
		end
	end
end

function get_hosts_arp(my_ip::IPv4,default_gateway::IPv4) 
	addrs = open("arp.txt") do f
		text = readlines(f)
		i = 2
		addrs = []
		while true
			try 
				addr = IPv4(split(text[i]," ")[1])
				!(isequal(addr,my_ip)||isequal(addr,default_gateway)) && push!(addrs,addr)
			catch e
				if isa(e,BoundsError)
					return addrs
				end
			end
			i+=1
		end
	end
	return addrs
end


