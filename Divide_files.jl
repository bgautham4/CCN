function divide_file(file::IO,n_segs::Int,dest::String="")
    size = position(seekend(file))
    seg_size = size ÷ n_segs
    seekstart(file)
    for i in 1:n_segs
        if i<n_segs
            open("$(dest)$(i).txt","w") do f
                while position(file) != i*seg_size
                    write(f,read(file,Char))
                end
            end
        else
            open("$(dest)$(i).txt","w") do f
               write(f,read(file,String))
            end
        end  
    end
end

function combine_files(n_segs::Int,path::String="",dest::String="")
    open("$(dest)combine.txt","w") do f
        for i in 1:n_segs
            open("$(path)$(i).txt") do f2
                write(f,read(f2,String))
            end
        end
    end
end


