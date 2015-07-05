#!/bin/sh

for i in conffail makefail makecheckfail makechecklogfail ;
do
    tar -czvf $i.tar.gz $i || exit 1
done
