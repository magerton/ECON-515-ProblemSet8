

function leisure_value_t(
	θ::Array{Float64},
	a::Int64)

    p_vec = unpackparams(θ)
    γ_1 = p_vec["γ_1"]
    γ_2 = p_vec["γ_2"]

	γ_1 + (1 + γ_2).*(df[:Y])[df[:A] .== a] 
end

function wage_eqn(
	θ::Array{Float64},
	X_a::Union(Array{Int64}, Int64, DataArray),
	e  ::Union(Array{Float64}, Float64, DataArray)
	)

    p_vec = unpackparams(θ)
    α_1 = p_vec["α_1"]
    α_2 = p_vec["α_2"]
    α_3 = p_vec["α_3"]

	exp( α_1 + α_2.*X_a + α_3.*(X_a.^2) + e )
end

function obs_wage_eqn(	
	θ::Array{Float64},
	X_a::Union(Array{Int64}, Int64, DataArray),
	e  ::Union(Array{Float64}, Float64, DataArray),
	v  ::Union(Array{Float64}, Float64, DataArray)
	)

	exp( log(wage_eqn(θ,X_a,e)) + v )
end


function g(
	θ::Array{Float64},
	X_a::Union(Array{Int64}, Int64, DataArray),
	a  ::Int64)

	x        = unique(X_a)
	EV_a1_x  = symbol("EV_$(a+1)_x$(x[1])")
	EV_a1_x1 = symbol("EV_$(a+1)_x$(x[1]+1)")
	EV_1     = (df[EV_a1_x1])[df[:A] .== a] 
	EV_0     = (df[EV_a1_x])[df[:A] .== a] 
	y        = (df[:Y])[df[:A] .== a]

	log( 
		leisure_value_t(θ,a) 
		- y + β*(EV_0 - EV_1)
		)  - wage_eqn(θ,X_a,zeros(N)) 
end

function Π_work(
	θ::Array{Float64},
	X_a::Union(Array{Int64}, Int64, DataArray),
	a  ::Int64
	)

    p_vec = unpackparams(θ)
    σ_e = p_vec["σ_e"]
	
	1 - normcdf( g(X_a,a)./σ_e )
end

function unpackparams(θ::Array{Float64})
  d = minimum(size(θ))
  θ = squeeze(θ,d)
  γ_1 = θ[1]
  γ_2 = θ[2]
  α_1 = θ[3]
  α_2 = θ[4]
  α_3 = θ[5]
  σ_e = θ[6]

  return [ 
  "γ_1" => γ_1,
  "γ_2" => γ_2,
  "α_1" => α_1,
  "α_2" => α_2,
  "α_3" => α_3,
  "σ_e" => σ_e
  ]
end





function least_sq(
	X::Union(Array,DataArray,Float64),
	Y::Array;
	N=int(size(X,1)), W=1
	)

  l = minimum(size(X))
  A = X'*W*X
  if sum(size(A))== 1
    inv_term = 1./A
  else
    inv_term = A\eye(int(size(X,2)))
  end
  β = inv_term * X'*W*Y
  if l == 1
    sigma_hat = sqrt(sum((1/N).* (Y - (β*X')')'*(Y - (β*X')'  ) ) ) #sum converts to Float64
  else
    sigma_hat = sqrt(sum((1/N).* (Y - (X*β))'*(Y - (X*β)  ) ) ) #sum converts to Float64
  end
  VCV = (sigma_hat).^2 * inv_term * eye(l)
  return β, sigma_hat, VCV
end



















