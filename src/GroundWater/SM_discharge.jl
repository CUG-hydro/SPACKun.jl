# SM_discharge!(soil, θ_unsat, soilpar; Q_in=0.0)
function SM_discharge!(soil::Soil, θ_unsat::Vector{T}, sink::Vector{T},
  soilpar; Q_in::T=0.0) where {T<:Real}
  (; z₊ₕ, zwt, θ, Q, Dmin, Dmax, N) = soil
  (; θ_sat, θ_wp, Ksat) = soilpar
  j = find_jwt(z₊ₕ, zwt)

  ## 非饱和带
  for i = 1:j
    i == N + 1 && continue

    z0 = i == 1 ? 0 : z₊ₕ[i-1]
    z1 = i == j ? zwt : z₊ₕ[i]
    depth = z1 - z0

    # TODO: 这里存在bug，土壤的厚度影响排泄量
    Q[i] = soil_drainage(θ_unsat[i], θ_sat, Ksat, Dmin[i], Dmax[i]) # 向下排泄量, [mm/d]
    ΔQ = Q_in - Q[i]

    # 对蒸发量也进行限制
    _θ = i == j ? θ_unsat[i] : θ[i]
    _sink = sink[i]
    # _sink = clamp(sink[i], 0, (_θ - θ_wp) * depth)

    θ_unsat[i] = (_θ * depth + ΔQ - _sink) / depth
    θ_unsat[i] = clamp(θ_unsat[i], 0, 1)

    Q_in = Q[i] # 一下次迭代
    if θ_unsat[i] > θ_sat
      Q_in += (θ_unsat[i] - θ_sat) * depth
      θ_unsat[i] = θ_sat
    end
  end

  ## 在排泄过程中，水位会下降，也会上升
  return Q_in # exceed
end


"""
    soil_drainage(wa_unsat, θ_sat, ks, Dmin, Dmax; dd = 1.5)

# layer1
Dmin = 0.048; # mm day-1
Dmax = 4.8; # mm day-1

# layer2
Dmin = 0.012; # 0.0005*24, mm day-1
Dmax = 1.2; # 0.05*24,   mm day-1

# Reference
1. Ducharne & Polcher, 1998
"""
function soil_drainage(θ_unsat, θ_sat, ks, Dmin, Dmax; dd=1.5)
  thx = θ_unsat / θ_sat

  if thx < 0.75
    perc = Dmin * thx
  else
    perc = Dmin * thx + (Dmax - Dmin) * thx^dd
  end
  return min(ks, perc) # drainage from unsaturated zone
end