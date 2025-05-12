module Utils
    using DSP
    using Plots

    """
    Calculates the coefficient of HBF using Remez algorithm.

    args:
    - N_taps: number of taps, must be odd
    - Ω_p: normalized angular frequency of pass-band right end, must be in (0, π/2)

    returns:
    - coeffs: Coefficients of HBF
    """
    function calcHBF_coeffs(N_taps::Int, Ω_p::Real)::Vector{Float64}
        @assert N_taps % 2 == 1 "N_taps must be odd"
        @assert Ω_p > 0 && Ω_p < π/2 "Ω_p must be in (0, π/2)"
        Ω_s = pi-Ω_p # normalized stop-band left end
        band_defs = [(0,Ω_p/(2pi)) => 1, (Ω_s/(2pi),0.5) => 0]
        vec_h = DSP.remez(N_taps, band_defs)
    end

    """
    Plots the coefficients of HBF and its frequency response.

    args:
    - vec_h: Coefficients of HBF
    - Ω_p: normalized angular frequency of pass-band right end, must be in (0, π/2)
    - δ_p: Expected maximal pass-band error, used to show margin in gain plot. Ignored if not specified.
    - δ_s: Expected maximal stop-band error, used to show margin in gain plot. Ignored if not specified.
    """
    function viewHBF(vec_h::Vector{T}, Ω_p::Real, δ_p::Real=-1, δ_s::Real=-1) where T<:Real
        @assert Ω_p > 0 && Ω_p < π/2 "Ω_p must be in (0, π/2)"
        Ω_s = pi-Ω_p # normalized stop-band left end
        N_taps = length(vec_h)
        H(Ω) = sum(vec_h[1+n]*exp(-im*Ω*n) for n in 0:N_taps-1)
        plt_td = plot(vec_h, title="HBF Coefficients", minorgrid=true, label=nothing, xlabel="index", ylabel="value", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # time-domain
        plt_fd = plot(Ω->20log10(abs(H(Ω))), xlims=(0, pi), title="HBF Gain Characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain
        display(plot(plt_td, plt_fd, layout=(1,2), size=(1600,200)))
        plt_fd_pb = plot(Ω->20log10(abs(H(Ω))), xlims=(0, Ω_p), title="HBF pass-band Gain Characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain, pass-band
        if δ_p >= 0
            plot!(plt_fd_pb, Ω->20log10(1+δ_p), xlims=(0, Ω_p), label="expected maximal gain", linestyle=:dash)
            plot!(plt_fd_pb, Ω->20log10(1-δ_p), xlims=(0, Ω_p), label="expected minimal gain", linestyle=:dash)
        end
        plt_fd_sb = plot(Ω->20log10(abs(H(Ω))), xlims=(Ω_s, pi), title="HBF stop-band Gain Characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain, stop-band
        if δ_s >= 0
            plot!(plt_fd_sb, Ω->20log10(δ_s), xlims=(Ω_s, pi), label="expected maximal error", linestyle=:dash)
        end
        display(plot(plt_fd_pb, plt_fd_sb, layout=(1,2), size=(1600,200)))
    end
end
