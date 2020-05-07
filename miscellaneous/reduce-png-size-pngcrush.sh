#!/bin/sh

# Shell script to reduce PNG file size using pngcrush
# Attempt with -brute with all methods first and then -reduce if file is still too big
# Anson Liu

# Requires pngcrush installed

# Recommend using pngquant to do lossy compression if file is still too big

maxsize=100000

mkdir pngcrush_out
ls *.png | while read line; 
do 
	pngcrush -brute -d pngcrush_out $line; 
	filesize=$(wc -c pngcrush_out/$line | awk '{print $1}'); 
	echo "$line crushed to $filesize"
	if [ "$filesize" -gt "$maxsize" ]; then
		echo "size is greater than maxsize, trying -reduce"
		pngcrush -brute -d pngcrush_out -reduce $line; 
		filesize=$(wc -c pngcrush_out/$line | awk '{print $1}'); 
		echo "$line crushed (with reduce) to $filesize"
	fi
done