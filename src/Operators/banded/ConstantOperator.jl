export ConstantOperator, BasisFunctional

##TODO: c->λ
##TODO: ConstantOperator->UniformScalingOperator?
immutable ConstantOperator{T,V} <: BandedOperator{V}
    c::T
    ConstantOperator(c::Number)=new(convert(T,c))
    ConstantOperator(L::UniformScaling)=new(convert(T,L.λ))
end


ConstantOperator(T::Type,c)=ConstantOperator{eltype(T),T}(c)
ConstantOperator(c::Number)=ConstantOperator(typeof(c),c)
ConstantOperator(L::UniformScaling)=ConstantOperator(L.λ)
IdentityOperator()=ConstantOperator(1.0)

bandinds(T::ConstantOperator)=0,0

getindex(C::ConstantOperator,k::Integer,j::Integer)=k==j?C.c:zero(eltype(C))


==(C1::ConstantOperator,C2::ConstantOperator)=C1.c==C2.c

Base.convert{BT<:ConstantOperator}(::Type{BT},C::ConstantOperator)=C
Base.convert{BT<:Operator}(::Type{BT},C::ConstantOperator)=ConstantOperator(eltype(BT),C.c)

## Algebra

for op in (:+,:-,:*)
    @eval ($op)(A::ConstantOperator,B::ConstantOperator)=ConstantOperator($op(A.c,B.c))
end


## Basis Functional

immutable BasisFunctional{T} <: Functional{T}
    k::Integer
end
BasisFunctional(k)=BasisFunctional{Float64}(k)

datalength(B::BasisFunctional) = B.k

for TYP in (:Functional,:Operator)
    @eval Base.convert{T}(::Type{$TYP{T}},B::BasisFunctional)=BasisFunctional{T}(B.k)
end

Base.getindex(op::BasisFunctional,k::Integer)=(k==op.k)?1.:0.
Base.getindex(op::BasisFunctional,k::Range)=convert(Vector{Float64},k.==op.k)

immutable FillFunctional{T} <: Functional{T}
    c::T
end


Base.getindex(op::FillFunctional,k::Integer)=op.c
Base.getindex(op::FillFunctional,k::Range)=fill(op.c,length(k))

## Zero is a special operator: it makes sense on all spaces, and between all spaces

immutable ZeroOperator{T,S,V} <: BandedOperator{T}
    domainspace::S
    rangespace::V
end

ZeroOperator{T,S,V}(::Type{T},d::S,v::V)=ZeroOperator{T,S,V}(d,v)
ZeroOperator{S,V}(d::S,v::V)=ZeroOperator(Float64,d,v)
ZeroOperator()=ZeroOperator(AnySpace(),ZeroSpace())
ZeroOperator{T}(::Type{T})=ZeroOperator(T,AnySpace(),ZeroSpace())

for TYP in (:Operator,:BandedOperator)
    @eval Base.convert{T}(::Type{$TYP{T}},Z::ZeroOperator)=ZeroOperator(T,Z.domainspace,Z.rangespace)
end

Base.convert{T}(::Type{Functional{T}},Z::ZeroOperator)=ZeroFunctional(T,Z.domainspace)




domainspace(Z::ZeroOperator)=Z.domainspace
rangespace(Z::ZeroOperator)=Z.rangespace

bandinds(T::ZeroOperator)=0,0

getindex(C::ZeroOperator,k::Integer,j::Integer)=zero(eltype(C))

promotedomainspace(Z::ZeroOperator,sp::AnySpace)=Z
promoterangespace(Z::ZeroOperator,sp::AnySpace)=Z
promotedomainspace(Z::ZeroOperator,sp::UnsetSpace)=Z
promoterangespace(Z::ZeroOperator,sp::UnsetSpace)=Z
promotedomainspace(Z::ZeroOperator,sp::Space)=ZeroOperator(sp,rangespace(Z))
promoterangespace(Z::ZeroOperator,sp::Space)=ZeroOperator(domainspace(Z),sp)


immutable ZeroFunctional{S<:Space,T<:Number} <: Functional{T}
    domainspace::S
end
ZeroFunctional(sp::Space)=ZeroFunctional{typeof(sp),Float64}(sp)
ZeroFunctional{T<:Number}(::Type{T},sp::Space)=ZeroFunctional{typeof(sp),T}(sp)
ZeroFunctional{T<:Number}(::Type{T})=ZeroFunctional(T,AnySpace())
ZeroFunctional()=ZeroFunctional(AnySpace())


for TYP in (:Functional,:Operator)
    @eval Base.convert{T}(::Type{$TYP{T}},Z::ZeroFunctional)=ZeroFunctional(T,Z.domainspace)
end


domainspace(Z::ZeroFunctional)=Z.domainspace
promotedomainspace(Z::ZeroFunctional,sp::Space)=ZeroFunctional(sp)

Base.getindex{S,T}(op::ZeroFunctional{S,T},k::Integer)=zero(T)
Base.getindex{S,T}(op::ZeroFunctional{S,T},k::Range)=zeros(T,length(k))



isconstop(::Union{ZeroOperator,ConstantOperator})=true
isconstop(S::SpaceOperator)=isconstop(S.op)
isconstop(::)=false

Base.convert{T<:Number}(::Type{T},::ZeroOperator)=zero(T)
Base.convert{T<:Number}(::Type{T},C::ConstantOperator)=convert(T,C.c)
Base.convert{T<:Number}(::Type{T},S::SpaceOperator)=convert(T,S.op)
