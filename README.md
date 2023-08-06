# SMLP2023

SMLP2023: Advanced methods in frequentist statistics with Julia

The rendered website version of the course materials is available [here](https://repsychling.github.io/SMLP2023/).

This repository uses [Quarto](https://quarto.org). To be able to render all the pages, you will need an appropriate Jupyter kernel installed and the local environment instantiated.

```sh
~/SMLP2023$ julia

julia> using Pkg

julia> Pkg.add("IJulia")
    Updating registry at `~/.julia/registries/General.toml`
   Resolving package versions...
< lots of output >

julia> using IJulia

julia> installkernel("julia", "--threads=auto", "--project=@.")
[ Info: Installing julia kernelspec in ~/.local/share/jupyter/kernels/julia-1.9
"~/.local/share/jupyter/kernels/julia-1.9"

julia> Pkg.activate(".")
  Activating project at `~/SMLP2023`

julia> Pkg.instantiate()
< lots of output >

julia> exit()

~/SMLP2023$ quarto preview

< lots of output >

```
