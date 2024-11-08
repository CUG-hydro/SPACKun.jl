using Test, SPAC

@testset "potentialET" begin
  Rn = 100.0
  G = 5.0
  LAI = 3.0
  Ta = 20.0
  Pa = 100.0

  VPD, U2, doy = 0.0, 0.0, 0
  pEc, pEs, ET0 = potentialET(Rn, G, LAI, Ta, Pa, VPD, U2, doy)

  @test pEc ≈ 2.5389604966643824
  @test pEs ≈ 0.3507115521629298
end

@testset "runoff_up" begin
  Pnet = 20.0 # mm
  zgw = 1000.0 # mm
  wa = [0.3, 0.3, 0.3]
  soilpar = get_soilpar(2)
  srf, IWS, Vmax = runoff_up(Pnet, wa, zgw, ZM, soilpar)
  @test Vmax ≈ 129
  @test IWS ≈ 20
end

@testset "pTr_partition" begin
  pEc = 20.0
  wa1, wa2, wa3 = 0.3, 0.2, 0.1
  fwet = 0.5
  soilpar = get_soilpar(2) #|> collect
  pftpar = get_pftpar(22) #|> collect
  r = pTr_partition(pEc, fwet, wa1, wa2, wa3, soilpar, pftpar, ZM)
  @test r == (0.004508186497043249, 9.864271368015835, 0.1312204454871218)
end
include("test-PET.jl")
include("test_栾城_2010.jl")
