include("grid2D.jl")
include("solveSalmonCNS.jl")
include("solveChorinNS.jl")

using Plots

# make mesh
K = 2
L = 2
xmin = ymin = -1.0
xmax = ymax = 1.0
ℳ = rectmesh2D(xmin, xmax, ymin, ymax, K, L)

filename = "Maxwell05.neu"
filepath = "./DG2D/grids/"
filename = filepath * filename
# ℳ = meshreader_gambit2D(filename)

# set number of DG elements and poly order
N = 2^2

# make grid
𝒢 = Grid2D(ℳ, N, periodic=true)
x = 𝒢.x[:,1]
y = 𝒢.x[:,2]
plotgrid2D(𝒢)

dof = 𝒢.nGL
println("The degrees of freedom are $dof")

# make field objects
u = Field2D(𝒢)
v = Field2D(𝒢)

# auxiliary fields
uˣ = Field2D(𝒢)
uʸ = Field2D(𝒢)
vˣ = Field2D(𝒢)
vʸ = Field2D(𝒢)
uu = Field2D(𝒢)
uv = Field2D(𝒢)
vu = Field2D(𝒢)
vv = Field2D(𝒢)

# initialize conditions
@. u.ϕ = 1.0
@. v.ϕ = 1.0

# parameters
stoptime = 2.
ν  = 1.0e-1
c² = 0.0

# determine timestep
umax = maximum(abs.(u.ϕ))
vmax = maximum(abs.(v.ϕ))
cmax = maximum([umax,vmax])
Δx = minspacing2D(𝒢)
CFL = 0.25
dt  = CFL * minimum([Δx/cmax, Δx^2/ν])
println("Time step is $dt")

# turn non-linear on/off
α = 0

# fluxes
φᵘ  = Flux2D([u], [1])
φᵛ  = Flux2D([v], [1])

φˣᵤ = Flux2D([uu, uˣ, vʸ], [-α, (ν+c²), c²])
φʸᵥ = Flux2D([vv, vʸ, uˣ], [-α, (ν+c²), c²])

φʸᵤ = Flux2D([uv, uʸ], [-α, ν])
φˣᵥ = Flux2D([vu, vˣ], [-α, ν])


# solve equations
fields = [u, v]
fluxes = [φᵘ, φᵛ, φˣᵤ, φʸᵤ, φˣᵥ, φʸᵥ]
auxils = [uˣ, uʸ, vˣ, vʸ, uu, uv, vu, vv]
params = (𝒢, ν, c², α)
rhs!   = solveChorinNS!
Nsteps = ceil(Int, stoptime / dt)
# Nsteps = 2
println("Number of steps is $Nsteps")

solutions = rk_solver!(rhs!, fields, fluxes, params, dt, Nsteps; auxils = auxils)

gr()
theme(:default)
step = floor(Int, Nsteps / 50)
step = 1

fieldNames = ["u", "v"]

@animate for t in 1:step:Nsteps
    plots = []
    for (i, sol) in enumerate(solutions)
        ploti = surface(x[:],y[:],sol[t][:], title = fieldNames[i], camera = (0,90))
        push!(plots, ploti)
    end
    display(plot(plots...))
end
