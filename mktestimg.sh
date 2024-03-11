#!/bin/bash

FILES=test_files/*
DELETE=(fstab LICENSE)

OUT=test.img
SIZE=1G

rm $OUT

fallocate -l $SIZE $OUT
mkdosfs -F32 $OUT -n 'test'

for file in ${FILES[@]}
do
    mcopy -i $OUT $file ::
done

for file in ${DELETE[@]}
do
    mdel -i $OUT $file
done

mdir -i $OUT # directory listing
