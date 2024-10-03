abstract type AbstractAntsInterpolation end

####Interpolation mode
interpolation_mode = ("Linear", "NearestNeighbor", "MultiLabel", "Gaussian", "BSpline", "CosineWindowedSinc", "HammingWindowedSinc", "LanczosWindowedSinc", "GenericLabel") 

struct Linear<:AbstractAntsInterpolation
    mode::AbstractString
end
Linear() = Linear("Linear")

struct NearestNeighbor<:AbstractAntsInterpolation
    mode::AbstractString
end
NearestNeighbor() = NearestNeighbor("NearestNeighbor")

### FIXME multilabel
struct MultiLabel{N}<:AbstractAntsInterpolation
   mode::AbstractString
   sigma::NTuple{N, Float64}
   alpha::Float64
end

### FIXME gaussian
struct Gaussian{N}<:AbstractAntsInterpolation
   mode::AbstractString
   sigma::NTuple{N, Number}
   alpha::Float64
end

struct BSpline<:AbstractAntsInterpolation
    mode::AbstractString
    order::Int
end
BSpline() = BSpline("BSpline", 3)
BSpline(order) = BSpline("BSpline", order)

struct CosineWindowedSinc<:AbstractAntsInterpolation
    mode::AbstractString
end
CosineWindowedSinc() = CosineWindowedSinc("CosineWindowedSinc")

struct WelchWindowedSinc<:AbstractAntsInterpolation
    mode::AbstractString
end
WelchWindowedSinc() = WelchWindowedSinc("WelchWindowedSinc")

struct HammingWindowedSinc<:AbstractAntsInterpolation
    mode::AbstractString
end
HammingWindowedSinc() = HammingWindowedSinc("HammingWindowedSinc")

struct LanczosWindowedSinc<:AbstractAntsInterpolation
    mode::AbstractString
end
LanczosWindowedSinc() = LanczosWindowedSinc("LanczosWindowedSinc")

struct GenericLabel<:AbstractAntsInterpolation
    mode::AbstractString
    interpolator::AbstractString
end
GenericLabel() = GenericLabel("GenericLabel", "Linear")
GenericLabel(interpolator) = GenericLabel("GenericLabel", interpolator)

#### Transformation
#struct Tform
#    transformFileName::AbstractString
#    useInverse::Int
#end
#Tform(transformFileName) = Tform(transformFileName, 0)

struct ITKTransform
    #mode::AbstractString FIXME 
    version::AbstractString
    tag::AbstractString #Not sure what it means.
    transform::AbstractString
    parameters::NTuple
    fixedparameters::NTuple
end

struct Tform #Transformation setup for antsApplyTransform
    transform::ITKTransform
    useInverse::Int
end
Tform(transform::ITKTransform) = Tform(transform, 0)
Tform(transformFileName::AbstractString) = Tform(load_itktform(transformFileName))
Tform(transformFileName::AbstractString, useInverse) = Tform(load_itktform(transformFileName), useInverse)

#### Point
struct Point
    x::Number
    y::Number
    z::Number
    t::Number
end

function applyTransforms(outputFileName, nd::Int, tforms::Vector{Tform}, referenceFileName::AbstractString, inputFileName::AbstractString; interpolation::AbstractAntsInterpolation = Linear(), input_imagetype = 0, output_datatype = "default", float::Bool = false, default_value = missing, verbose::Bool=false, suppressout::Bool=true)
    up = userpath()
    tfmnames = [joinpath(up, randstring(10)*"_tfm.txt") for i in tforms] #temporary transform file names
    cmd = `antsApplyTransforms -o $outputFileName -d $nd -r $referenceFileName -i $inputFileName --input-image-type $input_imagetype --output-data-type $output_datatype`
    # Add interpolation method
    if any(x -> isa(interpolation, x), [Linear, NearestNeighbor, CosineWindowedSinc, WelchWindowedSinc, HammingWindowedSinc, LanczosWindowedSinc])  
        cmd = `$cmd -n $(interpolation.mode)`
    elseif any(x -> isa(interpolation, x), [MultiLabel, Gaussian])
        cmd = `$cmd -n \[$(interpolation.mode), $(interpolation.sigma), $(interpolation.alpha)\]`
    elseif any(x -> isa(interpolation, x), [BSpline])
        cmd = `$cmd -n \[$(interpolation.mode), $(interpolation.order)\]`
    end
    # Add transformations
    for (i, tform) in enumerate(tforms)
        save_itktform(tfmnames[i], tform.transform)
        cmd = `$cmd -t \[$(tfmnames[i]), $(tform.useInverse)\]`
    end
    # Other options
    if verbose
        cmd = `$cmd -v 1`
    end
    if !ismissing(default_value)
        cmd = `$cmd --default-value $default_value`
    end
    # output display
    if verbose
        @show cmd
    end
    if suppressout
        @suppress_out run(cmd)
    else
        run(cmd)
    end
    rm.(tfmnames)
end

function get_tempname(tag::AbstractString)
    tfmname = joinpath(userpath(), randstring(10)*tag) #temporary transform file names
    return tfmname
end
get_tempname(noutputs::Int, tag::AbstractString) = [get_tempname(tag) for i in 1:noutputs]
get_tempname(noutputs::Int) = [get_tempname() for i in 1:noutputs]
get_tempname() = get_tempname("")

#### Apply Transforms to point
function applyTransformsToPoints(outputFileName::AbstractString, nd::Int, tforms::Vector{Tform}, inputFileName::AbstractString; precision::Bool = false)
    tfmnames = get_tempname(length(tforms), "_tfm.txt")
    cmd = `antsApplyTransformsToPoints -o $outputFileName -d $nd -i $inputFileName`
    if precision
        cmd = `$cmd --precision 1`
    end
    for tform in tfmnames
        save_itktform(tfmnames[i], tform.transform)
        cmd = `$cmd -t \[$(tfmnames[i]), $(tform.useInverse)\]`
    end
end

function applyTransformsToPoints(nd::Int, tforms::Vector{Tform}, points::DataFrame; precision::Bool = false)
    tmpinputname = tempname()*".CSV"
    tmpoutname = tempname()*".CSV"
    CSV.save(tmpname, points)
    applyTransformsToPoints(tmpoutname, nd, tforms, tmpinputname; precision = precision)
    df_tformed = CSV.read(tmpoutname, DataFrame)
    rm(tmpinputname)
    rm(tmpoutname)
    return df_tformed
end

function applyTransformsToPoints(nd::Int, tforms::Vector{Tform}, points::Vector{Point}; precision::Bool = false)
    x = map(p -> p.x, points)
    y = map(p -> p.y, points)
    z = map(p -> p.z, points)
    t = map(p -> p.t, points)
    df = DataFrame(x = x, y = y, z = z, t = z) #Make data frames
    df_tformed = applytTransformsToPoints(nd, tforms, df; precision = precision)
    points_tformed = map(p -> Point(p...), zip(df_tformed.x, df_tformed.y, df_tformed.z, df_tformed.t))
    return points_tformed
end

