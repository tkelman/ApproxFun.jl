export DefiniteIntegral,DefiniteLineIntegral

abstract CalculusFunctional{S,T} <: Functional{T}

##TODO: Add ConcreteOp

macro calculus_functional(Op)
    ConcOp=parse("Concrete"*string(Op))
    WrappOp=parse(string(Op)*"Wrapper")
    return esc(quote
        abstract $Op{SSS,TTT} <: CalculusFunctional{SSS,TTT}
        immutable $ConcOp{S,T} <: $Op{S,T}
            domainspace::S
        end
        immutable $WrappOp{BT<:Functional,S<:Space,T} <: $Op{S,T}
            func::BT
        end


        # We expect the operator to be real/complex if the basis is real/complex
        $ConcOp(dsp::Space) = $ConcOp{typeof(dsp),eltype(dsp)}(dsp)

        $Op() = $Op(UnsetSpace())
        $Op(dsp) = $ConcOp(dsp)
        $Op(d::Domain) = $Op(Space(d))

        promotedomainspace(::$Op,sp::Space) = $Op(sp)


        Base.convert{T}(::Type{Operator{T}},Σ::$ConcOp) =
            T==eltype(Σ)?Σ:$ConcOp{typeof(Σ.domainspace),T}(Σ.domainspace)
        Base.convert{T}(::Type{Functional{T}},Σ::$ConcOp) =
            T==eltype(Σ)?Σ:$ConcOp{typeof(Σ.domainspace),T}(Σ.domainspace)


        domain(Σ::$ConcOp) = domain(Σ.domainspace)
        domainspace(Σ::$ConcOp) = Σ.domainspace

        getindex(::$ConcOp{UnsetSpace},kr::Range) =
            error("Spaces cannot be inferred for operator")

        $WrappOp(op::Functional) =
            $WrappOp{typeof(op),typeof(domainspace(op)),eltype(op)}(op)


        Base.convert{T}(::Type{Operator{T}},Σ::$WrappOp) =
            T==eltype(Σ)?Σ:$WrappOp(convert(Operator{T},Σ.func))
        Base.convert{T}(::Type{Functional{T}},Σ::$WrappOp) =
            T==eltype(Σ)?Σ:$WrappOp(convert(Functional{T},Σ.func))


        #Wrapper just adds the operator it wraps
        getindex(D::$WrappOp,k::Range) = D.func[k]
        getindex(D::$WrappOp,k::Integer) = D.func[k]
        domainspace(D::$WrappOp) = domainspace(D.func)
        datalength(D::$WrappOp) = datalength(D.func)
    end)
end

@calculus_functional(DefiniteIntegral)
@calculus_functional(DefiniteLineIntegral)


#default implementation
function getindex(B::ConcreteDefiniteIntegral,kr::Range)
    S=domainspace(B)
    Q=Integral(S)
    A=(Evaluation(S,true)-Evaluation(S,false))*Q
    A[kr]
end

function getindex(B::ConcreteDefiniteIntegral,kr::Integer)
    S=domainspace(B)
    Q=Integral(S)
    A=(Evaluation(S,true)-Evaluation(S,false))*Q
    A[kr]
end




function DefiniteIntegral(sp::Space)
    if typeof(canonicaldomain(sp)).name==typeof(domain(sp)).name
        ConcreteDefiniteIntegral{typeof(sp),eltype(sp)}(sp)
    else
        M=Multiplication(fromcanonicalD(sp),setcanonicaldomain(sp))
        DefiniteIntegralWrapper(SpaceFunctional(DefiniteIntegral(rangespace(M))*M,sp))
    end
end

function DefiniteLineIntegral(sp::Space)
    if typeof(canonicaldomain(sp)).name==typeof(domain(sp)).name
        ConcreteDefiniteLineIntegral{typeof(sp),eltype(sp)}(sp)
    else
        M=Multiplication(abs(fromcanonicalD(sp)),setcanonicaldomain(sp))
        DefiniteLineIntegralWrapper(SpaceFunctional(DefiniteLineIntegral(rangespace(M))*M,sp))
    end
end
