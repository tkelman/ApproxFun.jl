
export coefficientmatrix,normalizedcumsum,normalizedcumsum!

function coefficientmatrix{T<:IFun}(B::Vector{T})
    m=mapreduce(length,max,B)
  n=length(B)
  ret = Array(Float64,m,length(B))
  for k=1:m,j=1:n
    ret[k,j] = length(B[j]) < k ? 0. : B[j].coefficients[k]
  end
  
  ret
end

##bisection inverse


bisectioninv(f::IFun,x::Real) = first(bisectioninv(f,[x]))




function bisectioninv(c::Vector{Float64},x::Float64)
    a = -1.;
    b = 1.;
    
#     a_v = unsafe_view(a);
#     b_v = unsafe_view(b);    
    
    for k=1:47  #TODO: decide 47
        m=.5*(a+b);
        val = clenshaw(c,m);

            (val<= x) ? (a = m) : (b = m)
    end
    .5*(a+b)    
end


bisectioninv(c::Vector{Float64},xl::Vector{Float64})=(n=length(xl);bisectioninv(c,xl,Array(Float64,n),Array(Float64,n),Array(Float64,n)))
function bisectioninv(c::Vector{Float64},xl::Vector{Float64},bk::Vector{Float64},bk1::Vector{Float64},bk2::Vector{Float64}) 
    n = length(xl);
    a = -ones(n);
    b = ones(n);
    
#     a_v = unsafe_view(a);
#     b_v = unsafe_view(b);    
    
    for k=1:47  #TODO: decide 47
        m=.5*(a+b);
        vals = clenshaw(c,m,bk,bk1,bk2);
        
        for j = 1:n
            (vals[j] <= xl[j]) ? (a[j] = m[j]) : (b[j] = m[j])
        end
    end
    m=.5*(a+b)    
end


#here, xl is vector w/ length == #cols of c
bisectioninv(c::Array{Float64,2},xl::Vector{Float64})=(n=length(xl);bisectioninv(c,xl,Array(Float64,n),Array(Float64,n),Array(Float64,n)))
function bisectioninv(c::Array{Float64,2},xl::Vector{Float64},bk::Vector{Float64},bk1::Vector{Float64},bk2::Vector{Float64}) 
    @assert size(c)[2] == length(xl)

    n = length(xl);
    a = -ones(n);
    b = ones(n);
    
#     a_v = unsafe_view(a);
#     b_v = unsafe_view(b);    
    
    for k=1:47  #TODO: decide 47
        m=.5*(a+b);
        vals = clenshaw(c,m,bk,bk1,bk2);
        
        for j = 1:n
            (vals[j] <= xl[j]) ? (a[j] = m[j]) : (b[j] = m[j])
        end
    end
    m=.5*(a+b)    
end



##normalized cumsum

function normalizedcumsum(f::IFun)
    cf = cumsum(f);
    cf = cf - cf[f.domain.a];
    cf = cf/cf[f.domain.b];
    
    cf    
end

function subtract_zeroatleft!(fin::Array{Float64,2})
    f=unsafe_view(fin)

    for k=2:size(f)[1],j=1:size(f)[2]
        f[1,j] += (-1.)^k.*f[k,j]
    end
    
    fin
end

function multiply_oneatright!(fin::Array{Float64,2})
    f=unsafe_view(fin)

    for j=1:size(f)[2]
        val=0.
        for k=1:size(f)[1]
            val+=f[k,j]
        end
        
        val=1./val
    
        for k=1:size(f)[1]
            f[k,j] *= val
        end
    end
        
    fin
end

function normalizedcumsum!(f::Array{Float64,2})
    ultraconversion!(f)
    ultraint!(f)
    subtract_zeroatleft!(f)
    multiply_oneatright!(f)
end

## Sampling

function sample(f::IFun,n::Integer)
    cf = normalizedcumsum(f)
    fromcanonical(f,bisectioninv(cf.coefficients,rand(n)))
end


sample(f::IFun)=sample(f,1)[1]





##2D sample

function sample(f::Fun2D,n::Integer)
    ry=sample(sum(f,1),n)
    fA=evaluate(f.A,ry)
    CB=coefficientmatrix(f.B)
    AB=CB*fA
    normalizedcumsum!(AB)
    rx=bisectioninv(AB,rand(n))
  [rx ry]
end

sample(f::Fun2D)=sample(f,1)[1,:]