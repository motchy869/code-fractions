module Utils
    using DSP
    using Plots

    """
    Estimates the number of required taps for HBF with given pass-band, gain errors.
    The equation is cited from "電気・電子・情報工学系テキストシリーズ 17 ディジタル・フィルタ" eq. (6.36).
    The estimated number of taps N_taps satisfies the following conditions.

    1. N_taps is odd
    2. (N_taps-1)/2 is also odd. This is required so that the left-most and right-most taps' coefficients are non-zero.

    args:
    - Ω_p: normalized angular frequency of pass-band right end, must be in (0, π/2)
    - δ_p: maximal pass-band error, must be greater than 0
    - δ_s: maximal stop-band error, must be greater than 0

    returns:
    - N_taps: estimated number of taps
    """
    function remezTapNumEst(Ω_p::Real, δ_p::Real, δ_s::Real)::Int
        @assert Ω_p > 0 && Ω_p < π/2 "Ω_p must be in (0, π/2)"
        @assert δ_p > 0 "δ_p must be greater than 0"
        @assert δ_s > 0 "δ_s must be greater than 0"
        Ω_s = pi-Ω_p; Δ = (Ω_s - Ω_p)/(2pi)
        N1 = Int(ceil((-20log10(sqrt(δ_p*δ_s))-13)/(14.6Δ)))
        L1 = N1÷2; L2 = L1÷2; N2 = 2*L2+1; 2*N2+1
    end

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
        DSP.remez(N_taps, band_defs)
    end

    """
    Calculates inverse sinc filter (ISF) coefficients.
    ISF is commonly used to compensate aperture effect of DAC.

    args:
    - N_taps: number of taps, must be odd
    - Ω_c: normalized angular frequency of compensation target band right end, must be in (0, π]. In most use cases, 0.8*π is enough.
    """
    function calcInvSincFltCoeffs(N_taps::Int, Ω_c::Real)::Vector{Float64}
        @assert N_taps % 2 == 1 "N_taps must be odd"
        @assert Ω_c > 0 && Ω_c <= π "Ω_c must be in (0, π]"
        f_c = Ω_c/(2pi)
        Hg_apt(F) = sinc(F) # aperture effect NORMALIZED gain characteristic
        Hg_apt_cmp(F) = 1/Hg_apt(F)
        band_defs = [(0,f_c) => f->Hg_apt_cmp(f)]
        vec_h = DSP.remez(N_taps, band_defs)
        max_g_flt = abs(sum(vec_h[1+n]*exp(-im*pi*n) for n in 0:N_taps-1)) # max gain of ISF
        vec_h ./= max_g_flt # Normalizes max gain to 1 to avoid overflow.
        return vec_h
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
        plt_td = plot(vec_h, title="HBF coefficients", minorgrid=true, label=nothing, xlabel="index", ylabel="value", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # time-domain
        plt_fd = plot(Ω->20log10(abs(H(Ω))), xlims=(0, pi), title="HBF gain characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain
        display(plot(plt_td, plt_fd, layout=(1,2), size=(1600,200)))
        plt_fd_pb = plot(Ω->20log10(abs(H(Ω))), xlims=(0, Ω_p), title="HBF pass-band gain characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain, pass-band
        if δ_p >= 0
            plot!(plt_fd_pb, Ω->20log10(1+δ_p), xlims=(0, Ω_p), label="expected maximal gain", linestyle=:dash)
            plot!(plt_fd_pb, Ω->20log10(1-δ_p), xlims=(0, Ω_p), label="expected minimal gain", linestyle=:dash)
        end
        plt_fd_sb = plot(Ω->20log10(abs(H(Ω))), xlims=(Ω_s, pi), title="HBF stop-band gain characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain, stop-band
        if δ_s >= 0
            plot!(plt_fd_sb, Ω->20log10(δ_s), xlims=(Ω_s, pi), label="expected maximal error", linestyle=:dash)
        end
        display(plot(plt_fd_pb, plt_fd_sb, layout=(1,2), size=(1600,200)))
    end

    """
    Plots the coefficients of Inverse sinc filter (ISF) and its frequency response.

    args:
    - vec_h: Coefficients of ISF
    - Ω_c: normalized angular frequency of compensation target band right end
    """
    function viewISF(vec_h::Vector{T}, Ω_c::Real) where T<:Real
        @assert Ω_c > 0 && Ω_c <= π "Ω_c must be in (0, π]"
        N_taps = length(vec_h)
        H(Ω) = sum(vec_h[1+n]*exp(-im*Ω*n) for n in 0:N_taps-1)

        # filter's own characteristic
        plt_td = plot(vec_h, title="ISF Coefficients", minorgrid=true, label=nothing, xlabel="index", ylabel="value", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # time-domain
        plt_fd = plot(Ω->20log10(abs(H(Ω))), xlims=(0, pi), title="ISF gain characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # frequency-domain
        display(plot(plt_td, plt_fd, layout=(1,2), size=(1600,200)))

        # composite characteristic
        Hg_apt(Ω) = sinc(Ω/(2pi)) # aperture effect NORMALIZED gain characteristic
        H_cmps(Ω) = H(Ω)*Hg_apt(Ω) # composite characteristic
        plt_cmps_fb = plot(Ω->20log10(abs(H_cmps(Ω))), xlims=(0, pi), title="Composite gain characteristic", minorgrid=true, label=nothing, xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # full-band
        plt_cmps_tb = plot(Ω->20log10(abs(H_cmps(Ω))), xlims=(0, Ω_c), title="Compensation error", minorgrid=true, label="composite gain", xlabel="normalized ang. freq. [rad]", ylabel="gain [dB]", size=(800,200), bottom_margin=8Plots.mm, left_margin=8Plots.mm) # target band
        plot!(Ω->20log10(abs(H_cmps(0))), xlims=(0, Ω_c), label="ideal gain", linestyle=:dash)
        display(plot(plt_cmps_fb, plt_cmps_tb, layout=(1,2), size=(1600,200)))
    end
end
