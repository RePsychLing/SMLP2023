module SMLP2023

using Arrow
using CSV
using DataFrames
using Downloads
using Markdown
using MixedModels
using Scratch
using ZipFile

const CACHE = Ref("")
const MMDS = String[]
const ML_LATEST_URL = "https://files.grouplens.org/datasets/movielens/ml-latest.zip"

_file(x) = joinpath(CACHE[], string(x, ".arrow"))

function __init__()
    CACHE[] = @get_scratch!("data")
    append!(MMDS, MixedModels.datasets())
end

clear_scratchspaces!() = Scratch.clear_scratchspaces!(@__MODULE__)

function extract_csv(zipfile, fname; kwargs...)
    file = only(filter(f -> endswith(f.name, fname), zipfile.files))
    return CSV.read(file, DataFrame; delim=',', header=1, kwargs...)
end

const metadata = Dict{String,String}("url" => ML_LATEST_URL)

function create_arrow(fname, df)
    arrowfile = _file(splitext(basename(fname))[1])
    Arrow.write(arrowfile, df; compress=:lz4, metadata)
    return arrowfile
end

const GENRES = ["Action", "Adventure", "Animation",
                "Children", "Comedy", "Crime",
                "Documentary", "Drama",
                "Fantasy", "Film-Noir",
                "Horror",
                "IMAX",
                "Musical", "Mystery",
                "Romance",
                "Sci-Fi",
                "Thriller",
                "War", "Western"]

function download_movielens()
    @info "Downloading Movielens data"
    quiver = String[]
    open(Downloads.download(ML_LATEST_URL), "r") do io
        zipfile = ZipFile.Reader(io)
        @info "Extracting and saving ratings"
        ratings = extract_csv(zipfile, "ratings.csv";
            types=[Int32, Int32, Float32, Int32],
            pool=[false, false, true, false],
        )
        push!(quiver, create_arrow("ratings.csv", ratings))
        @info "Extracting movies that are in the ratings table"
        movies = leftjoin!(
            leftjoin!(
                sort!(combine(groupby(ratings, :movieId), nrow => :nrtngs), :nrtngs),
                extract_csv(zipfile, "movies.csv"; types=[Int32,String,String], pool=false);
                on=:movieId,
            ),
            extract_csv(zipfile, "links.csv"; types=[Int32,Int32,Int32]);
            on=:movieId,
        )
        disallowmissing!(movies; error=false)
        movies.nrtngs = Int32.(movies.nrtngs)
        for g in GENRES
            setproperty!(movies, replace(g, "-" => ""), contains.(movies.genres, g))
        end
        select!(movies, Not("genres"))  # now drop the original genres column
        push!(quiver, create_arrow("movies.csv", movies))
        @info "Extracting and saving README"
        readme = only(filter(f -> endswith(f.name, "README.txt"), zipfile.files))
        open(joinpath(CACHE[], "README.txt"), "w") do io
            write(io, read(readme))
        end

        return nothing
    end

    return quiver
end


function movielens_readme()
    return Markdown.parse_file(joinpath(CACHE[], "README.txt"))
end

const OSF_IO_URIs = Dict{String,String}(
    "box" => "tkxnh",
    "elstongrizzle" => "5vrbw",
    "oxboys" => "cz6g3",
    "sizespeed" => "kazgm",
    "ELP_ldt_item" => "c6gxd",
    "ELP_ldt_subj" => "rqenu",
    "ELP_ldt_trial" => "3evhy",
    # TODO: add entries for fggk21_Child.arrow, fggk21_Score.arrow, fgg21.arrow
    # kkl15.arrow, kwdyz11.arrow

    # "movies" => "kvdch",
    # "ratings" => "v73ym",
)

"""
    download_data(; movielens=true, osf=true)

Download datasets.
"""
function download_data(; movielens=true, osf=true)
    movielens && download_movielens()

    if osf
        for (name, osfkey) in OSF_IO_URIs
            @info "Downloading $(name) dataset"
            Downloads.download(string("https://osf.io/", osfkey, "/download"),
                               _file(name))
        end
    end
    @info "Done"
    return nothing
end

datasets() = sort!(vcat(MMDS, first.(splitext.(filter(endswith(".arrow"), readdir(CACHE[]))))))
dataset(name::Symbol) = dataset(string(name))
function dataset(name::AbstractString)
    name in MMDS && return MixedModels.dataset(name)
    f = _file(name)
    isfile(f) ||
        throw(ArgumentError("$(name) is not a dataset "))
    return Arrow.Table(f)
end

end
