export Soil, update_soil
export SpacOutput, SpacOutputs


@with_kw mutable struct Soil{FT}
  N::Int = 3
  Δz::Vector{FT} = [50.0, 1450.0, 3500.0]  # mm
  z₊ₕ::Vector{FT} = cumsum(Δz)

  jwt::Int = 0                    # index of groundwater table, 追踪地下水，所在位置的上一层
  θ::Vector{FT} = ones(N) .* 0.2
  θ_prev::Vector{FT} = fill(0.2, N) # previous soil water content
  θ_unsat::Vector{FT} = fill(0.3, N)

  Q::Vector{FT} = fill(0.0, N)      # drainage, discharge, [mm d-1]

  Ec_pot::Vector{FT} = fill(0.0, N) # potential transpiration
  Ec_sm::Vector{FT} = fill(0.0, N)  # actual transpiration from unsaturated zone
  Ec_gw::Vector{FT} = fill(0.0, N)  # actual transpiration from groundwater

  Es_pot::Vector{FT} = fill(0.0, N) # potential soil evaporation
  Es_sm::Vector{FT} = fill(0.0, N)  # actual transpiration from unsaturated zone
  Es_gw::Vector{FT} = fill(0.0, N)  # actual transpiration from groundwater

  sink::Vector{FT} = fill(0.0, N)   # sink, 来自土壤的Ec + Es

  fsm_Es::Vector{FT} = fill(1.0, N) # SM constraint for soil evaporation
  fsm_Ec::Vector{FT} = fill(1.0, N) # SM constraint for transpiration

  zwt::FT = 0.0                     # groundwater depths [mm]
  snowpack::FT = 0.0                # snowpack depth [mm]

  ## Parameters
  Dmin::Vector{FT} = [0.048, 0.012, 0.012]  # drainage Parameters
  Dmax::Vector{FT} = [4.8, 1.2, 1.2]
end


# Update soil variables
function update_soil!(soil, θ, zwt, snowpack)
  # Create a structure to store soil variables
  #
  # 状态变量需要连续，传递到下一年中；模型对初始状态soil敏感。
  # - θ: 采用warming-up的方式获取，warming-up period可取3年
  # - zwt: 采用spin-up的方式获取，spin-up period可取100年
  #
  ## Argument Specification
  # - θ: soil water content in three layers, [m^3 m^-3]
  # - zwt: groundwater depth, [mm]
  # - snowpack: snowpack depth
  θ[θ.<0] .= 0.01  # set the minimum value for soil moisture
  soil.θ = θ
  soil.zwt = zwt
  soil.snowpack = snowpack
  return soil
end


# case_num::Int = 0
# Tr1::FT = 0
# Tr2::FT = 0
# Tr3::FT = 0
# s_vod::FT = 0
# s_tem::FT = 0
# Ec_pot[1]::FT = 0
# Ec_pot[2]::FT = 0
# Ec_pot[3]::FT = 0
# fsm_Es[1]::FT = 0
# f_sm_s2::FT = 0
# f_sm_s3::FT = 0
# pEc::FT = 0
# pEs::FT = 0
# ET0::FT = 0

@with_kw mutable struct SpacOutput{FT}
  ## Original Output
  ET::FT = 0
  Tr::FT = 0
  Es::FT = 0
  Ei::FT = 0
  Esb::FT = 0
  RS::FT = 0
  GW::FT = 0
  SM::Vector{FT} = zeros(3)
end


@with_kw mutable struct SpacOutputs{FT}
  ## Original Output
  ntime::Int = 10
  ET::Vector{FT} = zeros(ntime)
  Tr::Vector{FT} = zeros(ntime)
  Es::Vector{FT} = zeros(ntime)
  Ei::Vector{FT} = zeros(ntime)
  Esb::Vector{FT} = zeros(ntime)
  RS::Vector{FT} = zeros(ntime)
  GW::Vector{FT} = zeros(ntime)

  SM::Matrix{FT} = zeros(ntime, 3)
end


function Base.setindex!(res::SpacOutputs, r::SpacOutput, i::Int64)
  fields = fieldnames(SpacOutput)
  @inbounds for f in fields[1:end-1]
    getfield(res, f)[i] = getfield(r, f)
  end
  res.SM[i, :] .= r.SM
  return res
end
