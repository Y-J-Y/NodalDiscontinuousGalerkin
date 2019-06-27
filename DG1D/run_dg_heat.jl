include("dg1D.jl")
include("dg_heat.jl")

using Plots
using BenchmarkTools
using DifferentialEquations

# choose eqn type
periodic = false

# set number of DG elements and polynomial order
K = 2^3 #number of elements
n = 2^2-1 #polynomial order,
# (for 2^8, 2^4 with 2^4-1 seems best)
println("The degrees of freedom are ")
println((n+1) * K)

# set domain parameters
L    = 2π
xmin = 0.0
xmax = L
ι    = dg(K, n, xmin, xmax)

# set external parameters
ϰ = 1   # diffusivity constant
α = 1 # 1 is central flux, 0 is upwind
ε = external_params(ϰ, α)

# easy access
x  = ι.x
u  = ι.u
uʰ = ι.uʰ
q = copy(u)
dq = copy(ι.du)

# determine timestep
Δx  = minimum(x[2,:] - x[1,:])
CFL = 0.25
dt  = CFL * Δx^2 / ϰ #since two derivatives show up
dt *= 0.5 / 1

if periodic
    # initial condition for periodic problem
    @. u = exp(-4 * (ι.x - L/2)^2)
    make_periodic1D!(ι.vmapP, ι.u)
else
    # initial condition for textbook example problem
    @. u = sin(ι.x)
end

# run code
tspan  = (0.0, 2.0)
params = (ι, ε, periodic, q, dq)
rhs! = dg_heat!

prob = ODEProblem(rhs!, u, tspan, params);
sol  = solve(prob, Tsit5(), dt=dt, adaptive = false); # AB3(), RK4(), Tsit5(), Heun()
# @code_warntype dg_upwind!(ι.uʰ, ι.u, params, 0)
# @btime dg_upwind!(ι.uʰ, ι.u, params, 0)
# @btime sol = solve(prob, Tsit5(), dt=dt, adaptive = false);

# plotting
theme(:juno)
nt = length(sol.t)
num = 20
indices = Int(floor(nt/num)) * collect(1:num)
indices[end] = length(sol.t)

for i in indices
    plt = plot(x, sol.u[i], xlims=(0,L), ylims = (-1.1,1.1), marker = 3,    leg = false)
    plot!(     x, sol.u[1], xlims=(0,L), ylims = (-1.1,1.1), color = "red", leg = false)
    display(plt)
    sleep(0.25)
end
