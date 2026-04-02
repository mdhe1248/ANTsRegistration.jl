"""
Manually set a translation. This can be used for setting an initial transformation. This translation should be also be called in `applyTransforms` to take an effect.
e.g.) A point (388,194) in a moving image matches well to a point (360, 154) in a fixed image.

p = Pair((360, 154), (388, 194)) #fixed:(360, 154) moving:(388, 194).
itktrans = itktransXY(p)
itktforms = register(fixed, moving, stageaff; initial_moving_transform = [Tform(itktrans)])
imgw = applyTransforms(Tform.([itktrans, itktforms[1]]), fixed, moving)
"""
function itktransXY(fixed2moving::Pair) #FIXME make it compatible with CoordinateTransformations
    p = first(fixed2moving) .- last(fixed2moving)
    itktransXY(p)
end

function itktransXY(fixed2moving)
        tform = ITKTransform("GenericAffine",
             "#Insight Transform File V1.0",
             "#Transform 0",
             "AffineTransform_double_2_2",
             (1.0, 0.0, 0.0, 1.0, Float64.(fixed2moving)...),
             (0.0, 0.0)
            )
end


