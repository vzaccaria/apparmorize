#!/usr/bin/env sh 
set -e

# Source directory
#
srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`
dstdir=`pwd`

bindir=$srcdir/../..
npm=$srcdir/../node_modules/.bin

rm dest.txt
../index.js ./mytest > /dev/null && tree . > dest.txt
$npm/diff-files dest.txt ref.txt -m "check tree"

