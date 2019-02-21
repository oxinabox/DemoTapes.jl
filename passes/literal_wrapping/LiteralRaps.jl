# Title:  LiteralRaps
# Artist: Lyndon White (@oxinabox)
# Format: Literate.jl script
# License: MIT
# ---

# # What are we doing?
# Literals in julia have types, often hard-coding that literal type can cause problems.
# For example it may trigger unintended type-promotion (since `0.1*x` will be a Float64, even if `x` is a `Float32`
# This example will demonstrate how a Cassette pass can be used to replace every literal with a function call
# so a `0.1` in the orignal code will become `wrap(0.1)`
# We are adding that call to `wrap` into the code so that `wrap` gets called at run-time
# With some small tweaking, this could be changed to run `wrap` at compile time
# to actually insert different literals, and even do things like compile time string interning.

using Pkg: @pkg_str
pkg"activate ."


using Cassette
using IRTools
using Test

#-
# ## What are we going to wrap to?
#
#  For this example we are going to do some various different return types depending on the type of the input
# `wrap` will dispatch as required.

wrap(x::Integer) = Int128(x)
wrap(x::AbstractFloat) = BigFloat(x)
wrap(x) = x  # fallback

#-
# ## Now to define the pass
Cassette.@context LiteralWrapCtx



function apply_wrap(::Type{<:LiteralWrapCtx}, reflection::Cassette.Reflection)
    ir::Core.CodeInfo = reflection.code_info

end


#-
# ## Define convient way of calling it
const wrap_pass = Cassette.@pass apply_wrap
const LW_CTX = LiteralWrapCtx(;pass=wrap_pass)

"""
    with_wrapped_literals(f)

Call this as `with_wrapped_literals() do ... end`, to wrap all literals occurring
inside the do block.
"""
function with_wrapped_literals(f)
    Cassette.recurse(LW_CTX, f)
end

#-
# #Test it

function foo(x)
    0.1x
end

@test foo(2f0) isa Float64

@test with_wrapped_literals() do
    foo(2f0)
end isa BigFloat

cl = @code_lowered foo(1f0)

new_ir = IRTools.IR()
wval = push!(new_ir, :(wrap($val)))



ir = IRTools.@code_ir foo(1f0)

IRTools.code_ir(cl)
