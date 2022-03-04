"""
FIR filter

- example usage: see test.ipynb
- tested on: Julia 1.7.2
- version: 0.2.1
- author: motchy
- license: MIT
"""
module FirFilter
    using DSP

    struct State{Tc, Tb}
        coeffs::Vector{Tc}
        buffer::Vector{Tb} # buffer to store the tail of previous samples
    end

    function State{Tc, Tb}(coeffs::Vector{Tc}) where {Tc, Tb}
        N = length(coeffs)
        @assert N >= 1
        State{Tc, Tb}(coeffs, zeros(Tb,N-1))
    end

    function State{T}(coeffs::Vector{T}) where T
        State{T, T}(coeffs)
    end

    """
    Input samples to the filter and update the internal buffer.
    For details about the internal operation, see "illustration_push.png".
    """
    function push!(state::State{Tc, Tb}, vec_x::Vector{Tb}) where {Tc, Tb}
        N1 = length(state.coeffs)
        N2 = length(vec_x)

        vec_x2 = vcat(state.buffer, vec_x) # Prepend the tail of previous samples to the input.
        vec_y = conv(state.coeffs, vec_x2) # convolution with zero-padding

        state.buffer[:] = vec_x2[end-N1+2:end] # Update the buffer with last `N1-1` samples of `vec_x2`, which will be used in next call.
        vec_y[N1:N1+N2-1] # Drop head and tails.
    end
end
