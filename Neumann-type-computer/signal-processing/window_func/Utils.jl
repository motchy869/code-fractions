module Utils
    using Plots

    """
    Calculates Blackman-Harris window function.

    args:
    - N::Int: Length of the window.
    - val_type: type of the samples in the window (e.g., Float32, Float64).

    returns:
    - vec_w::Vector{T}: the window samples
    """
    function calc_BH_wndFxn(N::Int, val_type::Type{T}) where {T<:AbstractFloat}
        @assert N > 0
        N_2 = N-1;
        a_0 = T(0.35875); a_1 = T(0.48829); a_2 = T(0.14128); a_3 = T(0.01168)
        vec_w = Vector{T}(undef, N) #zeros(T, N)
        for n in 0:N_2
            vec_w[n+1] = a_0 - a_1*cos(2pi*n/N_2) + a_2*cos(4pi*n/N_2) - a_3*cos(6pi*n/N_2)
        end
        vec_w
    end

    """
    Plots the window function and its frequency response.

    generics:
    - T: type of the samples in the window (e.g., Float32, Float64).

    args:
    - vec_w::Vector{T}: The window samples.
    """
    function viewWndFxn(vec_w::Vector{T}) where T<:Real
        N = length(vec_w)
        H(Ω) = sum(vec_w[1+n]*exp(-im*Ω*n) for n in 0:N-1)
        dc_gain_dB = 20log10(abs(H(0)))
        plt_td = plot(vec_w, title="waveform", minorgrid=true, label=nothing, xlabel="index", ylabel="value", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # time-domain
        plt_fd = plot(Ω->20log10(abs(H(Ω)))-dc_gain_dB, xlims=(-pi, pi), title="normalized gain characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain
        display(plot(plt_td, plt_fd, layout=(1,2), size=(1600,200)))
    end
end
