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
#Initialize some directories..
for i in 1:N_pool
    run(`mkdir -p pool_storage/$(i)`)
end

respond_sock = listen(my_ip,2001)

while true
    conn = accept(respond_sock)
    @async begin
        msg = readline(conn)
        try
            cmd,dev_ip,dev_id = split(msg,",")
            if isequal(cmd,"STORE")
                open("pool_storage/$(dev_id)/$(dev_id).txt","w") do f
                    write(f,read(conn,String))
                end
                close(conn)
            end

            if isequal(cmd,"FWD")
                open("pool_storage/$(dev_id)/$(dev_id).txt") do f
                    write(conn,read(f,String))
                end
                close(conn)
            end
        catch e
            print("An error has occured!")
            close(conn)
        end
    end
end