"""
    loadArrayFromFile(path, type)

Load binary data from a file `path` and interpret the data as an array of type `type`.

# Examples
```julia-repl
julia> data = loadArrayFromFile("data.bin", Float32)
```
"""
function loadArrayFromFile(path::String, T::DataType)::Vector{T}
    if !isfile(path)
        throw(ErrorException("file not found."))
    end

    fileSize = filesize(path);
    numElems = fileSize÷sizeof(T);
    if fileSize != numElems*sizeof(T)
        println("Warn: file size is not a multiple of element size.\nLoading truncated data.")
    end

    array = Vector{T}(undef, numElems);
    read!(path, array);
    array
end
