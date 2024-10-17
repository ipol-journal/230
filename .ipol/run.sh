#!/bin/bash

### unzip the given archive. IPOL demo system will have renamed it input_0
### option -q makes it quiet.
unzip -q input_0
if [ $? != 0 ]; then # input_0 is not a zip file
  echo "Failed to unzip the uploaded file." > demo_failure.txt
  exit 0
fi

### This stops the script as soon as there is an error
### Need to set this after the zip failure test
set -e

### get value for regristration option
REGISTRATION="$1"
shift
WC="$1" # contrast weight
shift
WS="$1" # saturation weight (updated in this script if gray inputs)
shift
WE="$1" # well-exposedness weight
shift

### find images
# https://unix.stackexchange.com/a/321757
# "find prints a list of file paths delimited by newline characters"
FILELIST=$(find . -not -path '*/\.*' -type f -iname '*.jpg'  \
               -o -not -path '*/\.*' -type f -iname '*.jpeg' \
               -o -not -path '*/\.*' -type f -iname '*.png'  \
               -o -not -path '*/\.*' -type f -iname '*.ppm'  \
               -o -not -path '*/\.*' -type f -iname '*.bmp'  \
               -o -not -path '*/\.*' -type f -iname '*.tif'  \
               -o -not -path '*/\.*' -type f -iname '*.tiff' | sort)

IFS=$'\n'       # set IFS to be newline -- because FILELIST may have spaces.
                # This is used in the whole script

FLA=($FILELIST) # convert to array (based on new IFS)
NB=${#FLA[@]}   # counts number of elements in FLA, i.e., the number of inputs

if [ $NB == 0 ]; then # when no image was found after unzipping
  printf "No image found in the provided zip file.\n" > demo_failure.txt
  printf "(Or their format is not recognized)\n" >> demo_failure.txt
  exit 0
fi

if [ $NB == 1 ]; then # fusing a sequence of only one image causes an error
  printf "Can't fuse a sequence with only one image.\n\n" \
    > demo_failure.txt
  printf "(Note: the output would be the exact same as the input.)\n" \
    >> demo_failure.txt
  exit 0
fi

### give number of images to IPOL demo system
echo "nb_outputs=$NB" > algo_info.txt

### also set the warning_visible info (re-set later if needed)
echo "warning_visible=0" >> algo_info.txt

### resize large images (avoid "timeout", generally due to the registration)
mogrify -resize "1200x900>" "${FLA[@]}"

### convert images in RGB if they are 1-channel only
# I removed the conversion because I couldn't make it work on the ipol demo
# server. (I used eval octave --eval \""u=imread('""$FILE""'); ...)
# Also, $(identify -format "%[colorspace]" "$FILE") == "Gray" should do the
# trick but this too I couldn't make it work on the demo server. I drop it.
# If the sequence contains grayscale images, the execution will fail.
### some time later, a new attempt
WFLAG=true
for ID in ${!FLA[@]}; do # convert 1 channel images in 3 channels images
  INPUT="${FLA[$ID]}"
  OUTPUT=${INPUT/.bmp/.png} # convert to png because octave fails to write 3-channels images (used only for gray inputs)
  STDOUT=$(octave -WHf --eval "u=imread('$INPUT'); if size(u,3)==1, imwrite(repmat(u,[1,1,3]),'$OUTPUT'); fprintf('converted'); end")
  if [[ $STDOUT == "converted" ]]; then
    FLA[$ID]="$OUTPUT"
    if [ "$WFLAG" = true ]; then
      WS=0
      echo "warning_visible=1" >> algo_info.txt
      WFLAG=false
      echo ""
      echo "WARNING! Saturation metric was automatically set to zero (gray input images)"
      echo ""
    fi
  fi
done

if [ ! $REGISTRATION == 0 ]; then

  ### image registration
  echo "image_registration.sh ${FLA[@]}"
  TIME=$(date +%s)
  image_registration.sh "${FLA[@]}"
  TIMEREG=$(($(date +%s) - $TIME))

  ### find registered images and convert to array based on IFS=$'\n'
  FILELISTREG=$(find . -type f -name '*_registered.png' | sort)
  FLREGA=($FILELISTREG)

  ### call script with its parameters
  echo ""
  echo "run_ef.m $WC $WS $WE $@ ${FLREGA[@]}"
  TIME=$(date +%s)
  run_ef.m "$WC" "$WS" "$WE" "$@" "${FLREGA[@]}"
  TIMEFUSION=$(($(date +%s) - $TIME))

  ### display recap on computation times
  echo ""
  echo "Total time for registration: $TIMEREG seconds."
  echo "Total time for fusion: $TIMEFUSION seconds."

else

  ### call script with its parameters
  echo "run_ef.m $WC $WS $WE $@ ${FLA[@]}"
  TIME=$(date +%s)
  run_ef.m "$WC" "$WS" "$WE" "$@" "${FLA[@]}"
  TIMEFUSION=$(($(date +%s) - $TIME))

  ### display recap on computation time
  echo ""
  echo "Total time for fusion: $TIMEFUSION seconds."

fi

### Hack for demo
### Create a transparent image with the same size as the output image.
### This is used to compute the width of the result gallery (with two columns)
convert -size $(identify output.png | awk -F' ' '{ print $3 }') xc:none transparent.png

