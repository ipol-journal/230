An Implementation of the Exposure Fusion Algorithm
by Charles Hessel <charles.hessel@cmla.ens-cachan.fr> (CMLA, ENS Paris-Saclay)

The provided code compute the exposure fusion of a bracketed exposure sequence.
A separate script register images with misalignment.
This code is linked to an IPOL publication [1].


The provided Matlab/Octave implementation of exposure fusion was written by Tom
Mertens and is associated to [2], [3].
It is available online (https://github.com/Mericam/exposure-fusion).
The version included (in exposureFusion/) is a copy (master at commit 03e2469).
We provide two supplementary functions:
  - robustNormalization.m
  - run_ef.m
The first implements the robust normalization described in the paper.
The second loads a sequence of images, apply exposure fusion on it, then apply
the robust normalization or clipping on the fused image, and save the output
(and the generated weight images).

The registration script implements the algorithm described in the paper, which
is based on three steps: midway histogram equalization of the image pair (using
[4]); estimation of an homography (using [5]);  b-spline interpolation (using
[6]).


References:
[1] https://www.ipol.im/pub/pre/230/
[2] Mertens, T., Kautz, J., & Reeth, F. Van. (2007). Exposure Fusion. In 15th Pacific Conference on Computer Graphics and Applications (PG’07) (pp. 382–390). IEEE. http://doi.org/10.1109/PG.2007.17
[3] Mertens, T., Kautz, J., & Van Reeth, F. (2009). Exposure Fusion: A Simple and Practical Alternative to High Dynamic Range Photography. Computer Graphics Forum, 28(1), 161–171. http://doi.org/10.1111/j.1467-8659.2008.01171.x
[4] Thierry Guillemot, and Julie Delon, Implementation of the Midway Image Equalization, Image Processing On Line, 6 (2016), pp. 114–129. https://doi.org/10.5201/ipol.2016.140
[5] Thibaud Briand, Gabriele Facciolo, Javier Sánchez, Improvements of the Inverse Compositional Algorithm for Parametric Motion Estimation, Image Processing On Line, 8 (2018), Preprint, https://www.ipol.im/pub/pre/222/
[6] Thibaud Briand, and Pascal Monasse, Theory and Practice of Image B-Spline Interpolation, Image Processing On Line, 8 (2018), pp. 99–141. https://doi.org/10.5201/ipol.2018.221


Version 1.0 released on October 12, 2018


Files
-----

src
├── README.txt
├── composeHomographies.m
├── exposureFusion/ (*)
├── image_registration.sh
├── robustNormalization.m
└── run_ef.m

(*) The code in this directory is not reviewed.

"image_registration.sh" uses codes that need to be downloaded; this is described
in the section "sequence registration" below.


-----------------------
--- Exposure Fusion ---
-----------------------


The exposure fusion implementation is copyrighted by Tom Mertens. It implements
the algorithm described in [2], [3].
Merten's code is available on GitHub https://github.com/Mericam/exposure-fusion
and is licensed under the BSD 2-Clause "Simplified" License.

We provide it as supplementary (not reviewed) code.
This code (in the directory "exposureFusion") is a copy of the GitHub repository
(at commit 03e2469), with one slight modification: in the definition of the
function in exposure_fusion.m,

  function R = exposure_fusion(I,m)

is replaced by

  function [R,W] = exposure_fusion(I,m)

which allows the script run_ef.m to save the weights images.  If you download
the code from Mertens' repo, this is the only modification you will have to do.


Prerequisites
-------------

Either GNU Octave, version 4.0 or higher (with package "image" installed), or
Matlab.


Usage
-----

With Octave, call from the command line:

  $ octave run_ef.m Wc Ws We SCB Wsat Bsat image0 [image1 image2 ... imageN]

with:
  - Wc    : weight given to the contrast measure in [0,1]
  - Ws    : weight given to the saturation measure in [0,1]
  - We    : weight given to the well-exposedness measure in [0,1]
  - SCB   : clip or normalize the fused image
            - if 0, clip out-of-range values
            - if 1, apply robust normalization with parameters Wsat and Bsat
  - Wsat  : maximal percentage of white-saturated pixels (used only when SCB=1)
  - Bsat  : maximal percentage of black-saturated pixels (used only when SCB=1)
  - image0: first and mandatory image of the sequence
  - image1..imageN: (optional) following images of the sequence.

The accepted image formats are: PNG, JPEG, TIFF, PPM, BMP.
The images must have 3 channels.
There is no limitation on the number of images.

There are no default parameters since they are all required.
Nonetheless, here are the recommended values: Wc = Ws = We = 1 and SCB = 0.
When SCB = 0, Wsat and Bsat are not used so they can be set to any value.
When SCB = 1, the recommended values are Wsat = 0.1 and Bsat = 0.5.
These values are the default in the IPOL demo.

You can also run the script with

  $ ./run_ef.m Wc Ws We SCB Wsat Bsat image0 image1 ...

which will use the first line of the script (shebang).
Depending on the location of octave on your machine, you may have to update it.
Using

  #! /usr/bin/env octave -qfW

generally works.


With Matlab, first replace line 1

  #! /usr/bin/octave -qfW

by

  function run_ef (varargin)

then call the function from Matlab, using for example:

  $ run_ef('1', '1', '1', '0', '0', '0', 'A.jpg', 'B.jpg', 'C.jpg')



-----------------------------
--- Sequence registration ---
-----------------------------


The script "image_registration.sh" register a series of images on a reference.
The reference is the mid-sequence image.

The following steps are applied.
First, to pairs of consecutive images in the sequence:
  a. midway image equalization (give the two images the same histogram);
  b. estimation of the homography.
Then, pairing all images with the reference one:
  c. computation of the homography for non-adjacent images (by composition of
     the previously estimated homographies);
  d. interpolation of the registered image.
These operations are performed in parallel.

Each step is based on an IPOL paper and uses the code published along with it.
From inside directory "src" (see Files section above), download the codes with:

1) Midway Image Equalization [4]

  $ wget http://www.ipol.im/pub/art/2016/140/midway.zip
  $ unzip midway.zip

2) Homography estimation [5] (on github, tested at commit 01ffa47)
   Also available on the paper's page: https://www.ipol.im/pub/pre/222/

  $ wget https://github.com/tbriand/modified_inverse_compositional/archive/master.zip
  $ unzip master.zip

3) Bspline interpolation [6]

  $ wget http://www.ipol.im/pub/art/2018/221/bspline_1.00.zip
  $ unzip bspline_1.00.zip



Prerequisites
-------------

We report below a condensed recap of the prerequisite and build instructions of
the three program called by the registration script.
More information can be found in the readme files of the respective source code.

Required environment: Any unix-like system with a standard compilation
environment (make, C compiler and C++ compiler)

Required libraries:
- libpng and gnuplot for midway
- in addition: lipjpeg, libtiff for homography
- in addition: (optional) gsl for bspline interpolation.


Build
-----

Midway:

  $ cd src_ipol
  $ make

Homography:

  $ cd ../modified_inverse_compositional-master
  $ make

B-spline interpolation:

  $ cd ../bspline_1.00
  $ mkdir build && cd build
  $ cmake -DCMAKE_BUILD_TYPE=Release ../src
  $ make

Move the binaries in the same directory as "image_registration.sh"

  $ cd ../..
  $ mv src_ipol/bin/midway \
  $    modified_inverse_compositional-master/inverse_compositional_algorithm \
  $    bspline_1.00/build/bspline .


Usage
-----

Add the current directory to the search path so that the executables can be
found by the script:

  $ export PATH=$PATH:$(pwd)

Then, simply run

  $ ./image_registration.sh image1 image2 ... imageN

This registers the N images on image number (floor(N/2)). The output images have
"_registered" appended to their file name.

The script uses Octave for multiplying matrices.
To use Matlab instead, you will have to modify both composeHomographies.m and
image_registration.sh. In composeHomographies.m, replace the first line by

  function composeHomographies ( f_B2A, f_C2B, f_C2A )

then in image_registration.sh, uncomment

  COMPOSE="matlab_compose"
  function matlab_compose {
    matlab -nodesktop -nojvm -r "composeHomographies('$1','$2','$3'); quit"
  }

from line 10 to line 13 (and comment line 9).
Remember that matlab must be in your path.


---------------
--- Example ---
---------------


Assuming a directory "house" copied inside "src" and containing the images
"A.jpg", "B.jpg", "C.jpg" and "D.jpg" sorted by exposure time.
Register with

  $ ./image_registration.sh house/A.jpg house/B.jpg house/C.jpg house/D.jpg

then fuse with exposure fusion and parameters Ws = Wc = We = 1, SCB = 1,
Wsat = 0.1 and Bsat = 0.5:

  $ octave run_ef.m 1 1 1 1 .1 .5 A_registered.png \
  $                               B_registered.png \
  $                               C_registered.png \
  $                               D_registered.png

The fused image is called "output.png".

