"""
FIR filter

- example usage: see test.ipynb
- tested on: Julia 1.7.2
- version: 0.1.0
- author: motchy
- license: MIT
"""
module FirFilter
    using DSP

    struct State{T}
        coeffs::Vector{T}
        buffer::Vector{T} # buffer to store the tail of previous samples
    end

    function State{U}(coeffs::Vector{U}) where U
        N = length(coeffs)
        @assert N >= 1
        State{U}(coeffs, zeros(U,N-1))
    end

    """
    Input samples to the filter and update the internal buffer.
    For details about the internal operation, see "illustration_push.png".
    """
    function push(state::State{T}, vec_x::Vector{T}) where T
        N1 = length(state.coeffs)
        N2 = length(vec_x)

        vec_x2 = vcat(state.buffer, vec_x) # Prepend the tail of previous samples to the input.
        vec_y = conv(state.coeffs, vec_x2) # convolution with zero-padding

        state.buffer[end-N1+2:end] = vec_x2[end-N1+2:end] # Update the buffer with last `N1-1` samples of `vec_x2`, which will be used in next call.
        vec_y[N1:N1+N2-1] # Drop head and tails.
    end
end
