export ↦

immutable SpaceFunctional{O<:Functional,S<:Space,D<:Domain,T} <: Functional{T}
    op::O
    domainspace::S
    rangedomain::D
end

SpaceFunctional(o::Functional,s::Space,d::Domain)=SpaceFunctional{typeof(o),typeof(s),typeof(d),eltype(o)}(o,s,d)
SpaceFunctional(o::Functional,s::Space)=SpaceFunctional(o,s,domain(s))

datalength(S::SpaceFunctional)=datalength(S.op)


for TYP in (:Functional,:Operator)
    @eval function Base.convert{T}(::Type{$TYP{T}},S::SpaceFunctional)
        if T==eltype(S)
            S
        else
            op=convert(Operator{T},S.op)
            SpaceFunctional{typeof(op),typeof(S.domainspace),T}(op,S.domainspace,S.rangespace)
        end
    end
end

getindex(S::SpaceFunctional,k)=S.op[k]
getindex(S::SpaceFunctional,k,j)=S.op[k,j]


domainspace(S::SpaceFunctional)=S.domainspace
rangespace(S::SpaceFunctional)=ConstantSpace(S.rangedomain)
domain(S::SpaceFunctional)=domain(S.domainspace)

## Space Operator is used to wrap an AnySpace() operator
immutable SpaceOperator{O<:Operator,S<:Space,V<:Space,T} <: BandedOperator{T}
    op::O
    domainspace::S
    rangespace::V
end

# The promote_type is needed to fix a bug in promotetimes
# not sure if its the right long term solution
SpaceOperator(o::Operator,s::Space,rs::Space)=SpaceOperator{typeof(o),
                                                            typeof(s),
                                                            typeof(rs),eltype(o)}(o,s,rs)
SpaceOperator(o,s)=SpaceOperator(o,s,s)
Base.convert{OT<:SpaceOperator}(::Type{OT},S::OT)=S  # Added to fix 0.4 bug
function Base.convert{OT<:Operator}(::Type{OT},S::SpaceOperator)
    T=eltype(OT)
    if T==eltype(S)
        S
    else
        op=convert(BandedOperator{T},S.op)
        SpaceOperator{typeof(op),typeof(S.domainspace),typeof(S.rangespace),T}(op,S.domainspace,S.rangespace)
    end
end



# Similar to wrapper, but different domain/domainspace/rangespace

@wrappergetindex SpaceOperator

for func in (:(ApproxFun.bandinds),:(Base.stride))
     @eval $func(D::SpaceOperator)=$func(D.op)
end

domain(S::SpaceOperator)=domain(domainspace(S))
domainspace(S::SpaceOperator)=S.domainspace
rangespace(S::SpaceOperator)=S.rangespace



##TODO: Do we need both max and min?
function findmindomainspace(ops::Vector)
    sp = AnySpace()

    for op in ops
        sp = conversion_type(sp,domainspace(op))
    end

    sp
end

function findmaxrangespace(ops::Vector)
    sp = AnySpace()

    for op in ops
        sp = maxspace(sp,rangespace(op))
    end

    sp
end


# The coolest definitions ever!!
# supports Derivative():Chebyshev()↦Ultraspherical{1}()
↦(A::Operator,b::Space)=promoterangespace(A,b)
Base.colon(A::Operator,b::Space)=promotedomainspace(A,b)


promotedomainspace(P::Functional,sp::Space,::AnySpace)=SpaceFunctional(P,sp)
promotedomainspace(P::Functional,sp::Space,::ZeroSpace)=SpaceFunctional(P,sp)

for op in (:promoterangespace,:promotedomainspace)
    @eval begin
        ($op)(P::BandedOperator,::AnySpace)=P
        ($op)(P::BandedOperator,::UnsetSpace)=P
        ($op)(P::BandedOperator,sp::Space,::AnySpace)=SpaceOperator(P,sp)
    end
end

promoterangespace(P::Operator,sp::Space)=promoterangespace(P,sp,rangespace(P))
promotedomainspace(P::Operator,sp::Space)=promotedomainspace(P,sp,domainspace(P))


promoterangespace(P::BandedOperator,sp::Space,cursp::Space)=(sp==cursp)?P:Conversion(cursp,sp)*P
promotedomainspace(P::Functional,sp::Space,cursp::Space)=(sp==cursp)?P:P*Conversion(sp,cursp)
promotedomainspace(P::BandedOperator,sp::Space,cursp::Space)=(sp==cursp)?P:P*Conversion(sp,cursp)




for TYP in (:Operator,:BandedOperator,:Functional)
  @eval begin
    #TODO: better way of deciding type
    function promoterangespace{O<:$TYP}(ops::Vector{O})
      k=findmaxrangespace(ops)
      #TODO: T might be incorrect
      T=mapreduce(eltype,promote_type,ops)
      $TYP{T}[promoterangespace(op,k) for op in ops]
    end
    function promotedomainspace{O<:$TYP}(ops::Vector{O})
      k=findmindomainspace(ops)
      #TODO: T might be incorrect
      T=mapreduce(eltype,promote_type,ops)
      $TYP{T}[promotedomainspace(op,k) for op in ops]
    end
    function promotedomainspace{O<:$TYP}(ops::Vector{O},S::Space)
        k=conversion_type(findmindomainspace(ops),S)
        #TODO: T might be incorrect
        T=promote_type(mapreduce(eltype,promote_type,ops),eltype(S))
        $TYP{T}[promotedomainspace(op,k) for op in ops]
    end
  end
end


####
# choosedomainspace returns a potental domainspace
# where the second argument is a target rangespace
# it defaults to the true domainspace, but if this is ambiguous
# it tries to decide a space.
###

function choosedomainspace(A::Operator,sp)
    sp2=domainspace(A)
    isambiguous(sp2)?sp:sp2
end
choosedomainspace(A::Functional,sp)=domainspace(A)

choosedomainspace(A)=choosedomainspace(A,AnySpace())

function choosedomainspace(ops::Vector,spin)
    sp = AnySpace()

    for op in ops
        sp = conversion_type(sp,choosedomainspace(op,spin))
    end

    sp
end


#It's important that domain space is promoted first as it might impact range space
promotespaces(ops::Vector)=promoterangespace(promotedomainspace(ops))
function promotespaces(ops::Vector,b::Fun)
    A=promotespaces(ops)
    if isa(rangespace(A),AmbiguousSpace)
        # try setting the domain space
        A=promoterangespace(promotedomainspace(ops,space(b)))
    end
    A,Fun(b,rangespace(A[end]))
end


function promotespaces(A::Operator,B::Operator)
    if domainspace(A)==domainspace(B) && rangespace(A)==rangespace(B)
        A,B
    else
        tuple(promotespaces([A,B])...)
    end
end



## algebra


linsolve(A::SpaceOperator,b::Fun;kwds...) =
    setspace(linsolve(A.op,coefficients(b,rangespace(A));kwds...),domainspace(A))

linsolve{T<:Number}(A::SpaceOperator,b::Array{T};kwds...) =
    setspace(linsolve(A.op,b;kwds...),rangespace(A))
linsolve(A::SpaceOperator,b::Number;kwds...) =
    setspace(linsolve(A.op,b;kwds...),rangespace(A))
