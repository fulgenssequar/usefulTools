#module EasySaver
# Save and include this .jl file to get the useful getSaver function.
# An almost perfect julia script which makes Figure(variable) saving and org file generation as easy as a one-step call.
# Then go and find the *.org file in the folder in emacs without waiting for the finishing of the process or open the "screen -r" or Jupyter web again.

# Mostly workable with PyPlot



# (mapc 'eval '((julia-come) (undo-tree-mode) (linum-mode) (show-paren-mode)))

using LinearAlgebra
using Statistics
using JLD2
using Dates

using PyPlot
eye(m,n) = Array{Float64,2}(I,(m,n))
eye(m) = eye(m,m)

function getSaver(foldername::String)
    # Returns the closure function "saver" that automatically saves  and adds to an .org file figures and datas, while backs up data information as jld2 files.
    
    if ! isdir(foldername)
        mkdir(foldername)
    end
    saved_list = Dict()
    saved_text = Dict()
    saved_time = Dict()

    function dict2org()
        # I save the Dict of texts into one org/text file.
        # Called each time when new variable(Figure) are saved.
        sortedKeys = sort!(collect(keys(saved_time)), by=k->saved_time[k])
        sortedTexts = ["#+TITLE: $foldername\n"]
        for (i,k) in enumerate(sortedKeys)
            push!(sortedTexts, saved_text[k])
        end
        org_text = join(sortedTexts, "\n")

        f = open("$foldername.org","w")
        write(f, org_text)
        close(f)

        return org_text
    end
            
    function saver(var::Union{Symbol, Expr}, mark=nothing; expl="")
        # Closure function that saves Figure and variables by corresponding callable expressions. The same variable can be saved multi-times by specifying different marks.
        if mark==nothing
            mark = ""
        else
            mark = string(" ", mark)
        end
        
        varname = string(var,  mark)
        expl = "$varname - $expl"
        
        
        if eval(:(typeof($var)))==Figure
            figurename = "$foldername/$var$mark.svg"
            eval(:($var[:savefig]($figurename, bbox="tight")))


            saved_text[varname] = "$var\n[[./$figurename]]\n$expl\n - [saved: $(now())]\n"
            eval(:($var[:show]()))
        else
            
            saved_list[varname] = eval(var)
            saved_text[varname] = "\n$expl\n$(repr(eval(var)))\n - [saved: $(now())]\n"
        end
        
        saved_time[varname] = time()
        
        @save "$foldername/$foldername.jld2" saved_list saved_text saved_time

        println("Saved: $var ::$(eval(:(typeof($var))))\n$expl\n [$(now())] in ./$foldername\n ")
        
        dict2org()
        
    end

    return saver
                    
end
    
getSaver()= getSaver("backup$(now())")

# # The test code, as well as a demonstration:

# saveme = getSaver("theTest")

# fig = figure(figsize=[4,4])
# ax = fig[:gca]()
# ax[:imshow](rand(29,33))

# saveme(:fig, expl="Beautiful, almost delicious.")
# # Notice: one Figure saved...

# figure(figsize=[4,2])
# plot(rand(40))
# saveme(:(gcf()))
# # Another Figure saved...

# figure(figsize=[4,3])
# plot(rand(40), rand(40), "--r*", label="The ramble")
# gca()[:legend]()
# saveme(:(gcf()), 2)
# # Once again a Figure saved without overwriting the last gcf() object...

# asd = [x for x in 100:2:800]
# for i in 1:10
#     saveme(:asd, i, expl="Array repeatly saved in round $i")
#     # Array as data saved...
# end

# # The theTest.org file is already ready...

# sleep(100)

    

