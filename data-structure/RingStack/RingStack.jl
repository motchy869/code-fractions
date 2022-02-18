"""
A cyclic stack which holds the latest `N` elements where `N` is a positive integer.
When a new element `x` is pushed, the oldest element is overwritten with `x`.
"""
module RingStack
    mutable struct State{T<:Any}
        capacity::Int
        buffer::Vector{T}
        index::Int

        """
        Create a `RingStack` instance with capacity `c`.
        """
        State{U}(c::Int) where U<:Any = let
            if c < 1
                error("capacity must be greater than 0")
            end
            new(c, Vector{U}(undef, c), 1)
        end
    end

    """
    Push an element `x` into the stack.
    The oldest element is overwritten with `x`.
    """
    function push(s::State{T}, x::T) where T
        s.buffer[s.index] = x
        s.index += 1
        if s.index == s.capacity+1
            s.index = 1
        end
    end

    """
    Pop an element from the stack.
    The internal index is decremented.
    """
    function pop(s::State{T}) where T
        s.index -= 1
        if s.index == 0
            s.index = s.capacity
        end
        s.buffer[s.index]
    end
end
