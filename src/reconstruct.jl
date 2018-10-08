using JuMP

# Creates the equality constraints matrix and vector for quadprog.
# Constrained vertices include - all persistence features (their
# paired minima and maxima), the global minimum and the domain
# edges. The reconstructed function is guaranteed to preserve their
# location and their value - no new minima or maxima are created.
function eq_constraints(p::Persistence)
    n = length(p.data)

    idx = sort([p.minima;p.maxima;p.gminindex])
    sum(idx.==1) != 1 && (idx = [1;idx])
    sum(idx.==n) != 1 && push!(idx, n)

    m = length(idx)

    Aeq = sparse(1:m, idx, ones(m), m, n)
    beq = p.data[idx]

    Aeq,beq
end

# Builds a monotonicity graph based on the indices of the persistent
# extrema features which are used to reconstruct the data.
#
# Assumes that the indices of the local minima and maxima are matched.
#
# For 1D data, a monotonicity matrix is a sparse matrix, with values
# != 0 only on two diagonals, each one 1-removed from the main
# diagonal.  It is used by in_eq_constraints to create inequality
# constraints matrix and vector for quadprog.
function monotonicity_graph(p::Persistence)
    minima = sort([p.minima;p.gminindex])
    maxima = sort(p.maxima)

    first_local_min = if sum(maxima.==1) == 1
        false
    elseif sum(minima.==1) == 1
        true
    elseif minima[1] < maxima[1]
        maxima = [1;maxima]
        false
    else
        minima = [1;minima]
        true
    end

    N = length(p.data)
    if sum(maxima.==N) != 1 && sum(minima.==N) != 1
        if minima[end] > maxima[end]
            maxima = [maxima;N]
        else
            minima = [minima;N]
        end
    end

    pgrad = zeros(N);
    ngrad = zeros(N);

    all_ind = [minima; maxima];
    all_ind = sort(all_ind);

    if first_local_min
        for i=1:2:length(all_ind)-2
            pgrad[all_ind[i]:all_ind[i+1]-1] = 1;
            ngrad[all_ind[i+1]:all_ind[i+2]-1] = 1;
        end
    else
        for i=1:2:length(all_ind)-2
            ngrad[all_ind[i]:all_ind[i+1]-1] = 1;
            pgrad[all_ind[i+1]:all_ind[i+2]-1] = 1;
        end
    end

    # if it divides by 2 and short - need to add 1s to the last section
    if mod(length(all_ind),2) == 0 # even number of indices
        if first_local_min         # mins are at odd, maxs are at even, last index is max
            pgrad[all_ind[length(all_ind)-1]:all_ind[length(all_ind)]] = 1
        else                         # maxs are at odd, mins are at even, last index is min
            ngrad[all_ind[length(all_ind)-1]:all_ind[length(all_ind)]] = 1
        end
    end

    sparse([1:N-1;2:N], [2:N;1:N-1], [pgrad[1:N-1];ngrad[1:N-1]], N, N)
end

# Converts adjacency matrix graphs into
# linear inequality constraints to use with Matlab's quadprog.
# Inequality constraints are used to localize the local extrema
# created in the interpolation process.
#
# The inequality constraints are as follows:
#
# For each vertex which is not a minimum nor a maximum, it will have
# one neighbor smaller than itself and one neighbor greater than
# itself.  Local minima are constrained to be smaller than both of
# their neighbors.  Local maxima are constrained to be greater than
# both of their neighbors.  Within each component between a local
# minimum and a local maximum, monotonicity is guaranteed.
#
# Code is adapted from Alec Jacobson, 2011 (jacobson@inf.ethz.ch)
#
# Jacobson, A., Baran, I., Jovan Popovi\'c, & Sorkine,
# O. (2011). Bounded biharmonic weights for real-time
# deformation. {ACM} Transactions on Graphics, 30(4),
# 1. http://dx.doi.org/10.1145/2010324.1964973
function in_eq_constraints(p::Persistence)
    A = monotonicity_graph(p)
    n = size(A,1)
    I,J = findn(A)
    nleq = length(I)
    m = max(n,nleq)
    Aleq = sparse([1:nleq;1:nleq], [I;J],
                  [ones(nleq);-ones(nleq)],
                  m, m)
    b = zeros(length(p.data))
    Aleq,b
end

# https://en.wikipedia.org/wiki/Quadratic_programming
function quadprog(H,f,A,b,Aeq,beq)
    m = Model()
    M,N = size(H)

    @variable(m, x[1:M])
    @objective(m, Min, (1/2*x'*H*x + f'*x)[1])

    @constraint(m, A*x .<= b)
    @constraint(m, Aeq*x .== beq)

    solve(m)
    getvalue(x)
end

function reconstruct_persistent(data::Vector{T}, threshold::Real,
                                smoothness::Integer = 2, weight = 1e-6) where {T<:Real}
    smoothness > 0 || error("Invalid smoothness requested: $(smoothness)")
    0 <= weight && weight <= 1 || error("Weight $(weight) not in the interval [0,1]")

    p = filter(find_persistence(data), threshold)
    Aeq,beq = eq_constraints(p)
    A,b = in_eq_constraints(p)

    N = length(p.data)
    laplace = spdiagm((-ones(N-1), [1;2ones(N-2);1], -ones(N-1)),
                      (-1, 0, 1))

    op = laplace^smoothness
    op = (op + op')/2

    f = zeros(N)

    if weight != 0
        op += spdiagm(weight*2ones(N))
        f = -2weight*p.data
    end

    quadprog(op, f, A, b, Aeq, beq)
end

export reconstruct_persistent
