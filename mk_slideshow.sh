#!/bin/bash

# Takes all images given as parameters, and makes a video slideshow out of them.
# Note that the images are ordered lexicographically, regardless of the order in
# which they are given.

# Output Parameters:
SLIDE_SECONDS=4
SIZE_WIDTH=640
SIZE_HEIGHT=480
OUTPUT_FILE="output-mpeg4.avi"

function die()
{
    exit_status=$1
    die_message=$2

    if [[ $exit_status != 0 ]]
    then
        echo "$die_message"
        exit 1
    fi
}

if [[ $# == 0 ]]
then
    echo "no input files"
    exit 1
fi

if [ -e "$OUTPUT_FILE" ]
then
    echo "refusing to overwrite $OUTPUT_FILE"
    exit 1
fi

echo "Creating temp dir..."
mkdir tmp
die $? "mkdir failed"

echo "Resizing images..."
SIZE="${SIZE_WIDTH}x${SIZE_HEIGHT}"
for img in $@
do
    echo "$img..."
    convert "$img" -auto-orient -resize $SIZE -gravity center \
            -background black -extent $SIZE "tmp/$img"
    # the -auto-orient option handles EXIF rotation
    die $? "convert failed"
done

echo "Creating video slideshow..."
FPS=$(echo "scale=3; 1.0/$SLIDE_SECONDS" |bc)
mencoder mf://tmp/* -mf fps=$FPS -ovc lavc -lavcopts vcodec=mpeg4 \
         -o "$OUTPUT_FILE" >tmp/mencoder.log 2>&1
die $? "mencoder failed"

echo "Cleaning up..."
for img in $@
do
    rm "tmp/$img"
    die $? "rm failed"
done
rm tmp/mencoder.log
die $? "rm failed"
rmdir tmp
die $? "rmdir failed"

echo "Done! Output is in $OUTPUT_FILE"