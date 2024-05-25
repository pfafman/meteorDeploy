#!/bin/bash

echo ""

echo "Reading mup.json file ..."
config=`cat mup.json | grep -v "//"`


date=$(date '+%Y-%m-%d')

appName=`echo $config | jq -r '.appName'`


buildLocaltion="/tmp/mup/$appName/$date"


# meteor build --directory /tmp/mup/coWorkr1/2024-05-25 --architecture os.linux.x86_64 --server http://localhost:3000 --server-onl
buildCmd="meteor build --directory $buildLocaltion --architecture os.linux.x86_64 --server http://localhost:3000 --server-only"

# cd to app
appDir=`echo $config | jq -r '.app'`
echo "cd $appDir"

currentDir=`pwd`

cd $appDir

echo " Running: $buildCmd ..."
echo ""

$buildCmd

echo "cd $currentDir"
cd $currentDir

echo ""

servers=`echo $config | jq -r '.servers.[].host'`

for server in "${servers[@]}"
do
	echo "scp $buildLocaltion/bundle.tar.gz $server:/opt/$appName/tmp/."
	scp $buildLocaltion/bundle.tar.gz $server:/opt/$appName/tmp/.
done