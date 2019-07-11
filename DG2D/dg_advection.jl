

include("utils2D.jl")

function dg_central_2D!(u̇, u, params, t)
    # unpack params
    𝒢 = params[1] # grid parameters
    ι = params[2] # internal parameters
    ε = params[3] # external parameters

    # calculate fluxes
    @. ι.φˣ = ε.v1 * u
    @. ι.φʸ = ε.v2 * u

    # now for the boundary conditions
    # neumann boundary conditions (reflecting)
    #@. ι.fⁿ[𝒢.mapB] = 2*u[𝒢.vmapB]
    @. ι.fˣ[𝒢.mapB] = 0.0 #+ 2*u[𝒢.vmapB]
    @. ι.fʸ[𝒢.mapB] = 0.0 #+ 2*u[𝒢.vmapB]

    # Form field differences at faces, computing central flux
    @. ι.fˣ[:] = (ι.φˣ[𝒢.vmapM] - ι.φˣ[𝒢.vmapP])/2
    @. ι.fʸ[:] = (ι.φʸ[𝒢.vmapM] - ι.φʸ[𝒢.vmapP])/2
    #now for the normal component along the faces
    @. ι.fⁿ = ι.fˣ * 𝒢.nx + ι.fʸ * 𝒢.ny


    # rhs of the semi-discrete PDE, ∂ᵗu = -∂ˣ(v1*u) - ∂ʸ(v2*u)
    # compute divergence
    ∇⨀!(u̇, ι.φˣ, ι.φʸ, 𝒢)
    @. u̇ *= -1.0
    lift = 𝒢.lift * (𝒢.fscale .* ι.fⁿ) #inefficient part
    @. u̇ += lift
    return nothing
end

#note that this is useless for a fixed velocity field
function dg_rusonov_2D!(u̇, u, params, t)
    # unpack params
    𝒢 = params[1] # grid parameters
    ι = params[2] # internal parameters
    ε = params[3] # external parameters

    # calculate fluxes
    @. ι.φˣ = ε.v1 * u
    @. ι.φʸ = ε.v2 * u

    # find maximum velocity at faces
    # allocate memory 😦
    v1faceP = zeros(𝒢.nfp * 𝒢.nfaces, 𝒢.K)
    v2faceP = zeros(𝒢.nfp * 𝒢.nfaces, 𝒢.K)
    v1faceM = zeros(𝒢.nfp * 𝒢.nfaces, 𝒢.K)
    v2faceM = zeros(𝒢.nfp * 𝒢.nfaces, 𝒢.K)
    #
    v1faceP[:] = ε.v1[𝒢.vmapP]
    v2faceP[:] = ε.v2[𝒢.vmapP]
    v1faceM[:] = ε.v1[𝒢.vmapM]
    v2faceM[:] = ε.v2[𝒢.vmapM]
    vnfaceP = @. 𝒢.nx * v1faceP + 𝒢.ny * v2faceP
    vnfaceM = @. 𝒢.nx * v1faceM + 𝒢.ny * v2faceM
    max_nvel = [ max(vnfaceP[i,j], vnfaceM[i,j]) for i in 1:length(𝒢.nx[:,1]), j in 1:length(𝒢.nx[1,:]) ];
    # now for the boundary conditions
    # neumann boundary conditions (reflecting)
    #@. ι.fⁿ[𝒢.mapB] = 2*u[𝒢.vmapB]
    @. ι.fˣ[𝒢.mapB] = 0.0 #+ 2*u[𝒢.vmapB]
    @. ι.fʸ[𝒢.mapB] = 0.0 #+ 2*u[𝒢.vmapB]

    # Form field differences at faces, computing central flux
    @. ι.fˣ[:] = (ι.φˣ[𝒢.vmapM] - ι.φˣ[𝒢.vmapP])/2 - max_nvel[:] * (v1faceM[:] - v1faceP[:])/2
    @. ι.fʸ[:] = (ι.φʸ[𝒢.vmapM] - ι.φʸ[𝒢.vmapP])/2 - max_nvel[:] * (v2faceM[:] - v2faceP[:])/2
    #now for the normal component along the faces
    @. ι.fⁿ = ι.fˣ * 𝒢.nx + ι.fʸ * 𝒢.ny


    # rhs of the semi-discrete PDE, ∂ᵗu = -∂ˣ(v1*u) - ∂ʸ(v2*u)
    # compute divergence
    ∇⨀!(u̇, ι.φˣ, ι.φʸ, 𝒢)
    @. u̇ *= -1.0
    lift = 𝒢.lift * (𝒢.fscale .* ι.fⁿ) #inefficient part
    @. u̇ += lift
    return nothing
end

# currently just central difference right now

function dg_upwind_2D!(u̇, u, params, t)
    # unpack params
    𝒢 = params[1] # grid parameters
    ι = params[2] # internal parameters
    ε = params[3] # external parameters

    # calculate fluxes
    @. ι.φˣ = ε.v1 * u
    @. ι.φʸ = ε.v2 * u

    # now for the boundary conditions
    # neumann boundary conditions (reflecting)
    #@. ι.fⁿ[𝒢.mapB] = 2*u[𝒢.vmapB]
    @. ι.fˣ[𝒢.mapB] = 0.0 #+ 2*u[𝒢.vmapB]
    @. ι.fʸ[𝒢.mapB] = 0.0 #+ 2*u[𝒢.vmapB]

    # Form field differences at faces, computing central flux
    #vmapM is the interior node
    #vmapP is the flux from the neighbor
    @. ι.fˣ[:] = (ι.φˣ[𝒢.vmapM] - ι.φˣ[𝒢.vmapP])/2
    @. ι.fʸ[:] = (ι.φʸ[𝒢.vmapM] - ι.φʸ[𝒢.vmapP])/2
    #now for the normal component along the faces, with upwind
    ujump = reshape( abs.(ε.v1[𝒢.vmapM] .* 𝒢.nx[:] + ε.v2[𝒢.vmapM] .* 𝒢.ny[:]) .* (u[𝒢.vmapM] - u[𝒢.vmapP]), size(ι.fˣ) )
    @. ι.fⁿ = ι.fˣ * 𝒢.nx + ι.fʸ * 𝒢.ny - 0.5 * ujump



    # rhs of the semi-discrete PDE, ∂ᵗu = -∂ˣ(v1*u) - ∂ʸ(v2*u)
    # compute divergence
    ∇⨀!(u̇, ι.φˣ, ι.φʸ, 𝒢)
    @. u̇ *= -1.0
    lift = 𝒢.lift * (𝒢.fscale .* ι.fⁿ) #inefficient part
    @. u̇ += lift
    return nothing
end
