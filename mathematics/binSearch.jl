"""
    binSearch(array, x)

Find the smallest index `i` in sorted vector `array` that satisfies `array[i] <= x < array[i+1]`.

# Examples

```julia-repl
julia> binSearch([1,2.5,3.4,4,5], 3.2)
2
```
"""
function binSearch(array::Vector{T}, x::U)::Int where {T,U <: Real}
    pos_start = 1; pos_end = length(array);

    while pos_start < pos_end
        if pos_start == pos_end - 1
            if x < array[pos_end]
                return pos_start
            end
        end

        pos_middle = (pos_start + pos_end)÷2
        if x < array[pos_middle]
            pos_end = pos_middle
        else
            pos_start = pos_middle
        end
    end

    pos_start
end
