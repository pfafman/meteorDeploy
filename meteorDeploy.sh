#!/bin/bash

if [ "$1" == "-d" ]; then 
	echo "Deploy Only, no build"; 
fi

echo "Reading mup.json file ..."
config=`cat mup.json | grep -v "^[[:blank:]]*//"`
echo ""

date=$(date '+%Y-%m-%d')
appName=`echo $config | jq -r '.appName'`
buildLocaltion="/tmp/mup/$appName/$date"

# meteor build /tmp/mup/coWorkr1/2024-05-25 --architecture os.linux.x86_64 --server http://localhost:3000 --server-onl
buildCmd="meteor build $buildLocaltion --architecture os.linux.x86_64 --server http://localhost:3000 --server-only"

# cd to app
appDir=`echo $config | jq -r '.app'`
currentDir=`pwd`
scriptDir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


if [ "$1" != "-d" ]; then 
	cd $appDir
	echo ""
	echo "$buildCmd ..."
	echo ""
	$buildCmd
	cd $currentDir
	echo ""
fi

servers=`echo $config | jq -r '.servers.[]'`


for server in "${servers[@]}"
do
	host=`echo $server | jq -r '.host'`

	echo "Copy $appName to $host"
	scp $buildLocaltion/app.tar.gz $host:/opt/$appName/tmp/.
	echo ""

	env=`echo $server | jq -r '.env'`
	keys=($(echo $env | jq -r 'keys' | tr -d '[]," '))
	rm $buildLocaltion/env.sh
	for key in "${keys[@]}"
	do
		val=`echo $env | jq ".$key"`
		echo "$key=$val" >> $buildLocaltion/env.sh
	done
	echo "" >> $buildLocaltion/env.sh
	settings=`cat settings.json`
	echo 'METEOR_SETTINGS='$settings >> $buildLocaltion/env.sh
	echo "" >> $buildLocaltion/env.sh
	echo ""
	cat $buildLocaltion/env.sh
	echo "Copy env.sh to $host"
	scp $buildLocaltion/env.sh $host:/opt/$appName/tmp/.
	echo ""

	port=`echo $env | jq -r '.PORT'`
	
	if test -f "preInstallScript"; then
  		echo "Running preInstallScript"
  		ssh $host 'bash -s' < preInstallScript
	fi


	# Run installer on remote
	echo "Install on $host $port"
	echo ""

	remoteCmd=$(cat <<-END
	    cd /opt/$appName/tmp;
	    echo "Extracting";
	    tar xfz app.tar.gz;
	    cd ..;
	    sudo rm -rf old_app;
	    sudo rm -rf old_config;
	    echo "BackUp Old App";
	    sudo mv app old_app;
	    sudo cp -r config old_config;
	    sudo mv tmp/bundle app;
	    sudo cp tmp/env.sh config/.;
	    cd app/programs/server && sudo npm install;
	    cd ../../..;
	    echo "Fix ownership";
	    sudo chown -R meteoruser app;
	    echo "Restarting $appName";
	    sudo service $appName restart;
	    echo "Sleep 10";
	    /usr/bin/sleep 10;
	    echo "";
	    echo -e "Checking $appName on port:$port";
	    if curl localhost:$port 2>/dev/null >/dev/null; then
    		echo -e "   Server online";
    		echo -e "";
    		echo -e "Clean up on remote";
    		sudo rm -rf old_app;
	    	sudo rm -rf old_config;
    	else
    		echo -e "  Server offline";
    		echo -e "";
    		echo -e "Revert to previous version";
    		sudo rm -rf app;
	    	sudo rm -rf config;
    		sudo mv old_app app;
    		sudo mv old_config config;
    		sudo service $appName restart;
		fi
END
	)

	echo "Run command on $host"
	echo $remoteCmd
	ssh $host $remoteCmd

	if test -f "postInstallScript"; then
  		echo "Running postInstallScript"
  		ssh $host 'bash -s' < postInstallScript
	fi

done

if [ "$1" == "-d" ]; then 

	echo "Deploy Only, no build clean up"; 

elif [ "$1" != "-s" ]; then

	echo "Clean up local"
	rm -rf $buildLocaltion

fi 

echo ""

