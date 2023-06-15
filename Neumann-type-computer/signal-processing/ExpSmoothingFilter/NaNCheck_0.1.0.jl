# NaNCheck
#
# version 0.1.0

module NaNCheck
    const ENABLE_CHECK = true # When set to `false`, the check will be optimized away at compilation.

    function abortWhenNan(val::T) where {T<:Number}
        if ENABLE_CHECK
            @assert !isnan(val)
        end
    end

    function abortWhenNan(val::Array{T, N}) where {T<:Number, N}
        if ENABLE_CHECK
            @assert !any(isnan.(val))
        end
    end
end
