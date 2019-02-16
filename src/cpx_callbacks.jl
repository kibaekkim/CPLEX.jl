function get_best_bound(m::Model)
    objval_p = Vector{Cdouble}(undef, 1)
    stat = @cpx_ccall(getbestobjval, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cdouble}), m.env.ptr, m.lp, objval_p)
    if stat != 0
        throw(CplexError(m.env.ptr, stat))
    end
    return objval_p[1]
end

mutable struct CallbackData
    cbdata::Ptr{Cvoid}
    model::Model
end

export CallbackData

function setcallbackcut(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble, purgeable::Cint)
    len = length(ind)
    @assert length(val) == len
    sns = convert(Cint, sense)
    stat = @cpx_ccall(cutcallbackadd, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Cint,
                      Cdouble,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Cint
                      ),
                      cbdata.model.env.ptr, cbdata.cbdata, where, len, rhs, sns, ind .- Cint(1), val, purgeable)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end

function setcallbackcutlocal(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble, purgeable::Cint)
    len = length(ind)
    @assert length(val) == len
    sns = convert(Cint, sense)
    stat = @cpx_ccall(cutcallbackaddlocal, Cint, (
                      Ptr{Cvoid},
                      Ptr{Cvoid},
                      Cint,
                      Cint,
                      Cdouble,
                      Cint,
                      Ptr{Cint},
                      Ptr{Cdouble},
                      Cint
                      ),
                      cbdata.model.env.ptr, cbdata.cbdata, where, len, rhs, sns, ind .- Cint(1), val, purgeable)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
end



cbcut(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcut(cbdata, where, ind, val, sense, rhs, convert(Cint,CPX_USECUT_PURGE))

cbcutlocal(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcutlocal(cbdata, where, ind, val, sense, rhs, convert(Cint,CPX_USECUT_PURGE))

cblazy(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcut(cbdata, where, ind, val, sense, rhs, convert(Cint,CPX_USECUT_FORCE))

cblazylocal(cbdata::CallbackData, where::Cint, ind::Vector{Cint}, val::Vector{Cdouble}, sense::Char, rhs::Cdouble) =
        setcallbackcutlocal(cbdata, where, ind, val, sense, rhs, convert(Cint,CPX_USECUT_FORCE))

function cbbranch(cbdata::CallbackData, where::Cint, idx::Cint, LU::Cchar, bd::Cdouble, nodeest::Cdouble)
    seqnum = Vector{Cint}(1)
    stat = @cpx_ccall(branchcallbackbranchbds, Cint, (Ptr{Cvoid},Ptr{Cvoid},Cint,Cint,Ptr{Cint},Ptr{Cchar},Ptr{Cdouble},Cdouble,Ptr{Cvoid},Ptr{Cint}),
                      cbdata.model.env.ptr,cbdata.cbdata,where,convert(Cint,1),[idx],[LU],[bd],nodeest,C_NULL,seqnum)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
    return seqnum[1]
end

function cbbranchconstr(cbdata::CallbackData, where::Cint, indices::Vector{Cint}, coeffs::Vector{Cdouble}, rhs::Cdouble, sense::Cchar, nodeest::Cdouble)
    seqnum = Vector{Cint}(undef,1)
    stat = @cpx_ccall(branchcallbackbranchconstraints, Cint,
                      (Ptr{Cvoid},
                       Ptr{Cvoid},
                       Cint,
                       Cint,
                       Cint,
                       Ptr{Cdouble},
                       Ptr{Cchar},
                       Ptr{Cint},
                       Ptr{Cint},
                       Ptr{Cdouble},
                       Cdouble,
                       Ptr{Cvoid},
                       Ptr{Cint}),
                      cbdata.model.env.ptr,
                      cbdata.cbdata,
                      where,
                      convert(Cint,1),
                      convert(Cint,length(indices)),
                      [rhs],
                      [sense],
                      Cint[0],
                      indices,
                      coeffs,
                      nodeest,
                      C_NULL,
                      seqnum)
    if stat != 0
        throw(CplexError(cbdata.model.env.ptr, stat))
    end
    return seqnum[1]
end
