"""
Resizes 1-dimensional array to a new size like image resizing.
The intensity is preserved.

- example usage: see test.ipynb
- tested on: Julia 1.7.3
- version: 0.1.0
- author: motchy
- license: MIT
"""

module Resize1dArray
    function shrink1dArray(vec_x::Vector{T}, lNew::Int) where {T}
        l1, l2 = length(vec_x), lNew
        @assert 0 < l2 < l1

        vec_y = zeros(T, l2)

        for n = 0:l2-1
            t1, t2 = n * l1 / l2, (n+1) * l1 / l2
            u1, u2 = Int(floor(t1)), Int(floor(t2))
            yn = T(0)

            # Treat left and right ends.
            yn += vec_x[1+u1] * (1 - (t1 - u1))
            if u2 < l1
                yn += vec_x[1+u2] * (t2 - u2)
            end

            # Treat middle part.
            yn += sum(vec_x[1+u1+1:1+u2-1])

            vec_y[1+n] = yn
        end

        vec_y ./ l1 .* l2 # power adjustment
    end

    """
    Resizes 1-dimensional array `vec_x` to a new size `lNew` 1-d array like image resizing.
    The intensity is preserved.
    """
    function resize1dArray(vec_x::Vector{T}, lNew::Int) where {T}
        l1, l2 = length(vec_x), lNew
        if l1 < l2
            @assert false "expansion mode is not supported yet."
        elseif l1 == l2
            return vec_x
        else
            return shrink1dArray(vec_x, l2)
        end
    end
end
