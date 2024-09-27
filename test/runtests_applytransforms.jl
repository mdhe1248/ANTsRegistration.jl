using TestImages
using Images
using ImageView
using NRRD

#### Prepare test images
img = testimage("cameraman")
θ = deg2rad(15)
rot = imrotate(img, θ, center = true, axes(img))
imshow(rot);
save("testimg.nrrd", img)
save("testimgrot.nrrd", rot)

#### AntsRegistration
output = "TEST"
nd = 2
fixedname = "testimg.nrrd"
movingname = "testimgrot.nrrd"
pipeline= [Stage(Global("Rigid"), MI(), (8,4,2), (3,2,1), (100,50,25), 1e-6, 10), 
           Stage(SyN(), MI(), (8,4,2), (3,2,1), (100,50,25), 1e-6, 10)]
register(output, nd, fixedname, movingname, pipeline; verbose = true, suppressout = false)

#### Run ants registration
outputname = "testwarp.nrrd"
aff_filename= output*"0GenericAffine.mat"
warp_filename = output*"1Warp.nii.gz"
fixedname = "testimg.nrrd"
movingname = "testimgrot.nrrd"
tfms = [Tform(warp_filename), Tform(aff_filename)]
applyTransforms(outputname, 2, tfms, fixedname, movingname; verbose = true, suppressout = false)
imgw = load(outputname)
imshow(imgw);

#### Run antsApplyTransforms
invoutputname = "testinvwarp.nrrd"
warpinv_filename = output*"1InverseWarp.nii.gz"
movingname = "testwarp.nrrd"
tfms = [Tform(aff_filename, 1), Tform(warpinv_filename)]
applyTransformation(invoutputname, 2, tfms, fixedname, movingname; verbose = true, suppressout = false)
imginvw = load(invoutputname)
imshow(imginvw);


