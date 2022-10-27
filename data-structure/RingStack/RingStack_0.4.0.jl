"""
A cyclic stack which holds the latest `N` elements where `N` is a positive integer.
When a new element `x` is pushed, the oldest element is overwritten with `x`.

- example usage: see test.ipynb
- tested on: Julia 1.8.2
- version: 0.3.0
- author: motchy
- license: MIT
"""
module RingStack
    @assert VERSION >= v"1.8.2" # const struct member is supported since v1.8.2

    mutable struct State{T<:Any}
        const capacity::Int
        buffer::Vector{T}
        index::Int

        """
        Create a `RingStack` instance with capacity `c`.
        """
        State{U}(c::Int) where U<:Any = let
            if c < 1
                error("capacity must be greater than 0")
            end
            new(c, zeros(U, c), 1)
        end
    end

    """
    Push an element `x` into the stack.
    The oldest element is overwritten with `x`.
    """
    function push!(s::State{T}, x::T) where T
        s.buffer[s.index] = x
        s.index += 1
        if s.index == s.capacity+1
            s.index = 1
        end
    end

    """
    Pop an element from the stack.
    The internal index is decremented, but the popped element is remain valid in buffer.
    Thus, `moveHead(n)` after n-times `pop()` recovers the buffer state identical to the state before calling `pop()`s.
    """
    function pop!(s::State{T}) where T
        s.index -= 1
        if s.index == 0
            s.index = s.capacity
        end
        s.buffer[s.index]
    end

    """
    Pops `n` elements from the stack and execute `moveHead(n)`, where `n` is a given integer.
    The popped elements are returned as a vector only if `n` is positive.
    Otherwise, an empty vector is returned.
    """
    function copyTail!(s::State{T}, n::Int) where T
        if n <= 0
            return zeros(T, 0)
        end

        tail = zeros(T, n)

        for i in 1:n
            tail[1+n-i] = pop!(s)
        end

        moveHead!(s, n)

        tail
    end

    """
    Move the internal index by `n`.
    """
    function moveHead!(s::State{T}, n::Int) where T
        # Efficient specific imprementation is used for frequent case: n=1 or -1.

        if n == 1
            s.index += 1
            if s.index == s.capacity+1
                s.index = 1
            end
        elseif n == -1
            s.index -= 1
            if s.index == 0
                s.index = s.capacity
            end
        else
            i = s.index - 1 # Convert index range to [0, capacity-1]
            c = s.capacity
            i = (i+n)%c
            if i < 0
                i += c
            end
            s.index = 1 + i # Convert index range to [1, capacity]
        end
    end
end
