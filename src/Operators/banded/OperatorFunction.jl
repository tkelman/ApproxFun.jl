export OperatorFunction


abstract OperatorFunction{BT,T} <: BandedOperator{T}

immutable ConcreteOperatorFunction{BT<:BandedOperator,T} <: OperatorFunction{BT,T}
    op::BT
    f::Function
end

ConcreteOperatorFunction(op::BandedOperator,f::Function) = ConcreteOperatorFunction{typeof(op),eltype(op)}(op,f)
OperatorFunction(op::BandedOperator,f::Function) = ConcreteOperatorFunction(op,f)

for op in (:domainspace,:rangespace,:domain,:bandinds)
    @eval begin
        $op(OF::ConcreteOperatorFunction) = $op(OF.op)
    end
end

function getindex(OF::ConcreteOperatorFunction,k::Integer,j::Integer)
    @assert isdiag(OF.op)
    if k==j
        OF.f(OF.op[k,k])::eltype(OF)
    else
        zero(eltype(OF))
    end
end

function Base.convert{T}(::Type{Operator{T}},D::ConcreteOperatorFunction)
    if T==eltype(D)
        D
    else
        ConcreteOperatorFunction{typeof(D.op),T}(D.op,D.f)
    end
end

function Base.convert{T}(::Type{BandedOperator{T}},D::ConcreteOperatorFunction)
    if T==eltype(D)
        D
    else
        ConcreteOperatorFunction{typeof(D.op),T}(D.op,D.f)
    end
end
