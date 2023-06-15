# An expoential smoothing filter.
#
# depends on:
#
# - NaNCheck_0.1.0.jl

module ExpSmoothingFilter
    using ..NaNCheck

    mutable struct FilterState{T}
        alpha::T
        c_alpha::T
        x::T
        is1StShot::Bool
        FilterState{U}(alpha, initVal) where U = new(alpha, 1-alpha, initVal, true)
    end

    FilterState{T}(alpha) where T = FilterState{T}(alpha, 0)

    function step(filterState::FilterState{T}, x::T) where T
        NaNCheck.abortWhenNan(x)
        y = (filterState.is1StShot ? 1 : filterState.alpha)*x + filterState.c_alpha*filterState.x;
        filterState.x = y;
        filterState.is1StShot = false
        y
    end
end
