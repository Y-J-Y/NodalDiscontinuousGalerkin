include("field2D.jl")
include("utils2D.jl")

"""
solveMaxwell!(u̇, u, params)

# Description

    numerical solution to 1D maxwell's equation

# Arguments

-   `u̇ = (Eʰ, Hʰ)`: container for numerical solutions to fields
-   `u  = (E , H )`: container for starting field values
-   `params = (𝒢, E, H, ext)`: mesh, E sol, H sol, and material parameters

"""
function solveMaxwell2D!(fields, params)
    # unpack params
    𝒢 = params[1] # grid parameters
    α = params[2]

    # unpack fields
    Hˣ = fields[1]
    Hʸ = fields[2]
    Eᶻ = fields[3]

    # define field differences at faces
    @. Hˣ.Δu = Hˣ.u[𝒢.nodes⁻] - Hˣ.u[𝒢.nodes⁺]
    @. Hʸ.Δu = Hʸ.u[𝒢.nodes⁻] - Hʸ.u[𝒢.nodes⁺]
    @. Eᶻ.Δu = Eᶻ.u[𝒢.nodes⁻] - Eᶻ.u[𝒢.nodes⁺]

    # impose reflective BC
    @. Hˣ.Δu[𝒢.mapᴮ] = 0
    @. Hʸ.Δu[𝒢.mapᴮ] = 0
    @. Eᶻ.Δu[𝒢.mapᴮ] = 2 * Eᶻ.u[𝒢.nodesᴮ]

    # perform calculations over elements
    let nGL = nBP = 0
        for k in 1:𝒢.ℳ.K
            # get element and number of GL points
            Ωᵏ = 𝒢.Ω[k]
            nGLᵏ = (nGL + 1):(nGL + Ωᵏ.nGL)
            nBPᵏ = (nBP + 1):(nBP + Ωᵏ.nBP)
            nGL += Ωᵏ.nGL
            nBP += Ωᵏ.nBP

            # get views of computation elements
            uHˣ = view(Hˣ.u, nGLᵏ)
            uHʸ = view(Hʸ.u, nGLᵏ)
            uEᶻ = view(Eᶻ.u, nGLᵏ)

            u̇Hˣ = view(Hˣ.u̇, nGLᵏ)
            u̇Hʸ = view(Hʸ.u̇, nGLᵏ)
            u̇Eᶻ = view(Eᶻ.u̇, nGLᵏ)

            ∇Hˣ = view(Hˣ.∇u, nGLᵏ)
            ∇Hʸ = view(Hʸ.∇u, nGLᵏ)
            ∇Eᶻ = view(Eᶻ.∇u, nGLᵏ)

            ΔHˣ = view(Hˣ.Δu, nBPᵏ)
            ΔHʸ = view(Hʸ.Δu, nBPᵏ)
            ΔEᶻ = view(Eᶻ.Δu, nBPᵏ)

            fHˣ = view(Hˣ.fⁿ, nBPᵏ)
            fHʸ = view(Hʸ.fⁿ, nBPᵏ)
            fEᶻ = view(Eᶻ.fⁿ, nBPᵏ)

            # evaluate upwind fluxes
            nˣΔH = @. Ωᵏ.nˣ * (Ωᵏ.nˣ * ΔHˣ + Ωᵏ.nʸ * ΔHʸ)
            nʸΔH = @. Ωᵏ.nʸ * (Ωᵏ.nˣ * ΔHˣ + Ωᵏ.nʸ * ΔHʸ)

            # minus isn't defined for these fluxes?????
            @. fHˣ =      Ωᵏ.nʸ * ΔEᶻ + α * (nˣΔH + (-1 * ΔHˣ))
            @. fHʸ = -1 * Ωᵏ.nˣ * ΔEᶻ + α * (nʸΔH + (-1 * ΔHʸ))
            @. fEᶻ = -1 * Ωᵏ.nˣ * ΔHʸ + Ωᵏ.nʸ * ΔHˣ + (-1 * α * ΔEᶻ)

            # local derivatives of the fields
            ∇!(∇Hʸ, ∇Hˣ, uEᶻ, Ωᵏ)
            ∇⨂!(∇Eᶻ, uHˣ, uHʸ, Ωᵏ)

            # compute RHS of PDE's
            liftHˣ = 1//2 * Ωᵏ.M⁺ * Ωᵏ.∮ * (Ωᵏ.volume .* fHˣ)
            liftHʸ = 1//2 * Ωᵏ.M⁺ * Ωᵏ.∮ * (Ωᵏ.volume .* fHʸ)
            liftEᶻ = 1//2 * Ωᵏ.M⁺ * Ωᵏ.∮ * (Ωᵏ.volume .* fEᶻ)

            @. u̇Hˣ = -∇Hˣ + liftHˣ
            @. u̇Hʸ =  ∇Hʸ + liftHʸ
            @. u̇Eᶻ =  ∇Eᶻ + liftEᶻ
        end
    end

    return nothing
end
