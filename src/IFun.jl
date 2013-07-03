## helper routines



alternating_vector(n::Integer) = 2*mod([1:n],2)-1;

function chebyshev_transform(x::Vector)
    ret = FFTW.r2r(x, FFTW.REDFT00);
    ret[1] *= .5;
    ret[end] *= .5;    
    ret.*alternating_vector(length(ret))/(length(ret)-1)
end

function ichebyshev_transform(x::Vector)
    x[1] *= 2.;
    x[end] *= 2.;
    
    ret = chebyshev_transform(x);
    
    x[1] *= .5;
    x[end] *= .5;
    
    ret[1] *= 2.;
    ret[end] *= 2.;
    
    flipud(ret.*alternating_vector(length(ret)).*(length(x) - 1).*.5)
end

points(n::Integer)= cos(π*[n-1:-1:0]/(n-1))

points(d::Domain,n::Integer) = from_uinterval(d,points(n))



##  IFun

abstract Fun



type IFun <: Fun
    coefficients::Vector
    domain::Domain
end



function IFun(f::Function,n::Integer)
    IFun(f,Interval(-1,1),n)
end

function IFun(f::Function,d::Domain,n::Integer)
    IFun(chebyshev_transform(f(points(d,n))),d)
end

function IFun(f::Function,d::Vector,n::Integer)
    IFun(f,apply(Interval,d),n)
end

function IFun(cfs::Vector)
	IFun(cfs,Interval(-1,1))
end

function IFun(cfs::Vector,d::Vector)
	IFun(cfs,apply(Interval,d))
end


function IFun(f::Function)
    IFun(f,Interval(-1,1))
end

function IFun(f::Function,d::Vector)
    IFun(f,apply(Interval,d))
end

function IFun(f::Function, d::Domain)
    tol = 10*eps();

    for logn = 2:20
        cf = IFun(f, d, 2^logn);
        
        if max(abs(cf.coefficients[end]),abs(cf.coefficients[end-1])) < tol
            return cf;
        end
    end
    
    warn("Maximum length reached");
    
    cf
end



function evaluate(f::IFun,x)
    evaluate(f.coefficients,to_uinterval(f.domain,x))
end

function evaluate(v::Vector{Float64},x::Real)
    unp = 0.;
    un = v[end];
    n = length(v);
    for k = n-1:-1:2
        uk = 2.*x.*un - unp + v[k];
        unp = un;
        un = uk;
    end

    uk = 2.*x.*un - unp + 2*v[1];
    .5*(uk -unp)
end



function values(f::IFun)
   ichebyshev_transform(f.coefficients) 
end

function points(f::IFun)
    points(f.domain,length(f))
end


function Base.length(f::IFun)
    length(f.coefficients)
end



function pad!(f::IFun,n::Integer)
	if (n > length(f))
		append!(f.coefficients,zeros(n - length(f)));
	else
		resize!(f.coefficients,n);
	end
end


function pad(f::IFun,n::Integer)
	g = deepcopy(f);
	pad!(g,n);
	g
end

function +(f::IFun,g::IFun)
	@assert f.domain == g.domain

	n = max(length(f),length(g))
	f2 = pad(f,n);
	g2 = pad(g,n);
	
	IFun(f2.coefficients + g2.coefficients,f.domain)
end

function .*(f::IFun,g::IFun)
	@assert f.domain == g.domain

	n = length(f) + length(g) - 1;
	f2 = pad(f,n);
	g2 = pad(g,n);
	
	IFun(chebyshev_transform(values(f2).*values(g2)),f.domain)
end



function Winston.plot(f::IFun)
    plot(points(f),values(f))
end


