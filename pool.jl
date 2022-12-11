using Sockets
include("Divide_files.jl")
my_ip = getipaddr()

get_id_sock = listen(my_ip,2000)
print("Awaiting for controller's signal....\n")
n_attempts = 0
data = ""

#Acquire details from controller.
while n_attempts < 3
    try
        conn = accept(get_id_sock)
        global data = read(conn,String)
        println("Controller says : $(data)")
        close(conn)
        break
    catch e
        if isa(e,Base.IOError)
            println("Connection reset!")
            global n_attempts+=1
        else
            println("An error has occured!")
            close(conn)
        end
    end
end
data_arr = split(data,",")
server_ip = IPv4(data_arr[1])
my_id = parse(Int,data_arr[2])
N_pool = parse(Int,data_arr[3])
pool_ids = [i for i in 1:N_pool if i!=my_id]
#Initialize some directories..(NOTE: Remeber to delete these directories before every run.)
for i in 1:N_pool
    run(`mkdir -p pool_storage/$(i)`)
end

print("Enter the path of file(relative to pwd) to divide in the pool : ")
file_name = readline(stdin)
run(`mkdir segments`)

open("$(file_name)") do f
    divide_file(f,N_pool,"segments/")
end

run(`rm $(file_name)`)
run(`mv segments/$(my_id).txt pool_storage/$(my_id)/`)

@sync for device in pool_ids
    @async begin
        get_ip = connect(server_ip,2000)
        write(get_ip,"GET,$(my_id),$(device)\n") #Request for pool device ip.
        device_ip = IPv4(read(get_ip,String))
        close(get_ip)
        write_sock = connect(device_ip,2001)
        write(write_sock,"STORE,$(my_ip),$(my_id)\n")  #command to the storage pool device of the form STORE,dev_ip,dev_id\n
        open("segments/$(device).txt") do f
            #=while !eof(f)
                write(write_sock,read(f,Char))
            end=#
            write(write_sock,read(f,String))
        end
        close(write_sock)
    end
end

run(`rm -rf segments/`)

print("Press any key to retrieve files back from the pool.")
readline(stdin)

@sync for device in pool_ids
    println("Retrieving from $(device)...")
    @async begin
        get_ip = connect(server_ip,2000)
        write(get_ip,"GET,$(my_id),$(device)\n") #Request for pool device ip.
        device_ip = IPv4(read(get_ip,String))
        close(get_ip)
        read_sock = connect(device_ip,2001)
        write(read_sock,"FWD,$(my_ip),$(my_id)\n")  #command to the storage pool device of the form STORE/FWD,dev_ip,dev_id\n
        open("pool_storage/$(my_id)/$(device).txt","w") do f
            #=while !eof(f)
                write(write_sock,read(f,Char))
            end=#
            text = read(read_sock,String)
            write(f,text)
        end
        close(read_sock)
    end
end
combine_files(N_pool,"pool_storage/$(my_id)/")
println("Retrieved file from the pool successfully!")




