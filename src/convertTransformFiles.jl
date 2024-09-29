struct ITKTransform
    version::AbstractString
    tag::AbstractString #Not sure what it means.
    transform::AbstractString
    parameters::NTuple
    fixedparameters::NTuple
end

"""ConvertTransformFile in ANTs"""
function convertTransformFile(tformfile::AbstractString, outputtxtfile::AbstractString)
    cmd = `ConvertTransformFile 2 $tformfile $outputtxtfile`
    run(cmd)
end

""" Load itk transform text file as a struct"""
function load_itktform(tformtxtfile::AbstractString)
    lines = Vector{AbstractString}()
    open(tformtxtfile) do file
        for ln in eachline(file)
            push!(lines, ln)
        end
    end
    itktform_textlines2struct(lines)
end

function itktform_textlines2struct(lines)
    if isequal(lines[1], "#Insight Transform File V1.0") #Check file version
        ITKTransform(lines[1],
                     lines[2], 
                     lines[3][(findfirst(':', lines[3])+2):end],
                     Tuple(parse.(Float64, split(lines[4][(findfirst(':', lines[4])+2):end]))),
                     Tuple(parse.(Float64, split(lines[5][(findfirst(':', lines[5])+2):end]))))
    else
        @error "Transform file version does not match"
    end
end

function itktform_struct2textlines(tform::ITKTransform)
    lines = Vector{AbstractString}(undef, 5)
    lines[1] = tform.version
    lines[2] = tform.tag
    lines[3] = string("Transform: ", tform.transform)
    lines[4] = string("Parameters: ", join(tform.parameters, " "))
    lines[5] = string("FixedParameters: ", join(tform.fixedparameters, " "), "\n")
    return lines
end

""" Save as itk transform text file"""
function save_itktform(filename, tform::ITKTransform)
    lines = itktform_struct2textlines(tform)
    tformtxt = join(lines, "\n")
    open(filename, "w") do file
        write(file, tformtxt)
    end
end
