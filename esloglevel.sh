#!/bin/bash
#This script will set or unset the debug flag for all DX services and restart the DX services to make the changes stick
#Written by Brad Johnson - LogRhythm Support 

user="root"					#$user is the username used for ssh access to the nodes and moving files between nodes.
password=""
script_exit=false
seelog_files="$(cd /usr/local/logrhythm; find . -name *.xml | grep seelog)"
logback_files="$(cd /usr/local/logrhythm; find . -name *.xml | grep logback)"
log_level=""
cluster_name="$(cat /etc/elasticsearch/elasticsearch.yml | grep -P 'cluster\.name' | grep -Po '(?<=cluster\.name: ).*?$')"
num_nodes="$(cat /etc/elasticsearch/elasticsearch.yml | grep discovery.zen.ping.unicast.hosts | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | wc -l)"
local_addresses="$(ip addr | grep inet | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | uniq)"
multinode=false
singlenode=true

#This function will determine number of nodes in the cluster, and set the multinode, nodes, and local_node_address variable appropriately.
#using the ping.unicast.hosts value in the /etc/elasticsearch/elasticsearch.yml file we can quickly determine the IP addresses of the nodes elastic will be expecting.
#If this value is more than 1 we will say this a multi node cluster, allowing some error messages to print if there is an invalid cluster configuration.
#We can then compare the ip of the nodes expected by Elastic, and compare it to the configured IP addresses on the system to determine which IP to use for the node the script is run off of.
nodes_function () {
	#Determines how many nodes are in the cluster, and writes to the console as informational messages.
	if [[ $num_nodes -eq 1 ]]; then
		multinode=false
	elif [[ $num_nodes -eq 2 ]] || [[ $num_nodes -gt 10 ]]; then
		multinode=true
		nodes="$(cat /etc/elasticsearch/elasticsearch.yml | grep discovery.zen.ping.unicast.hosts | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
		echo "***Unsupported number of nodes found in cluster***"
		echo "There are $num_nodes in the $cluster_name cluster.  The script can be run on the following nodes:"
		for current_node in $nodes; do
			echo "$current_node"
		done
		echo
	elif [[ $num_nodes -ge 3 ]]; then
		multinode=true
		nodes="$(cat /etc/elasticsearch/elasticsearch.yml | grep discovery.zen.ping.unicast.hosts | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
		echo "There are $num_nodes nodes in the $cluster_name cluster.  The script can be run on the following nodes:"
		for current_node in $nodes; do
			echo "$current_node"
		done
		echo

	fi

	#Compares all IP addresses on the system, and compares them to the hosts in the Elastic cluster, once it matches it sets the local_node_address variable to this IP address.
	for local in $local_addresses; do
		for node in $nodes; do
			if [[ $local = $node ]]; then
				local_node_address=$local
				echo "Running on node $HOSTNAME using IP of $local_node_address"
			fi
		done
	done
}

#This function will prompt the user for the users password, masking the input.  If no input is entered the default LogRhythm password will be used.
password_function () {
	unset password
	prompt="Please enter the password for the user $user: "
	while IFS= read -p "$prompt" -r -s -n 1 char
	do
	    if [[ $char == $'\0' ]]
	    then
	         break
	    fi
	    prompt='*'
	    password+="$char"
	done
	export SSHPASS=$password
}

change_debug () {
	chmod +x /usr/local/logrhythm/tools/{stop,start}-all-services-linux.sh
	curl -s -XPUT localhost:9200/_cluster/settings -d '{"persistent":{"logger._root":"'$log_level'"}}' > /dev/null
	cd /usr/local/logrhythm/tools
	./stop-all-services-linux.sh
	cd /usr/local/logrhythm

	if [[ "$log_level" = "debug" ]]; then
		echo "setting debug level logging..."
		for seelog in $seelog_files; do
			sed -i -e 's/minlevel=\"info\"/minlevel=\"debug\"/' $seelog
		done
		for logback in $logback_files; do
			sed -i -e 's/root level=\"INFO\"/root level=\"DEBUG\"/' $logback
		done
	elif [[ "$log_level" = "info" ]]; then
		echo "setting info level logging..."
		for seelog in $seelog_files; do
			sed -i -e 's/minlevel=\"debug\"/minlevel=\"info\"/' $seelog
		done
		for logback in $logback_files; do
			sed -i -e 's/root level=\"DEBUG\"/root level=\"INFO\"/' $logback
		done
	fi

	cd /usr/local/logrhythm/tools
	./start-all-services-linux.sh
}

select_debug () {
	if [[ $multinode = true ]]; then
		echo "Do you want to set the logging level cluster wide?"
		select allnodes in "Yes" "No"; do
	    	case $allnodes in
	        	Yes ) echo; echo "Setting $log_level level logging cluster wide."; echo; break;;
	        	No ) echo; echo "Setting $log_level level logging localy."; echo; singlenode=true; break;;
	    	esac
		done
	fi

	if [[ $multinode = false ]] || [[ $singlenode = true ]]; then
		change_debug
	elif [[ $multinode = true ]] && [[ $singlenode = false ]]; then
		password_function
		for node in $nodes; do
			if [[ $node = "$local_node_address" ]]; then
				echo
				echo "Changing log level on $node"
				echo
				change_debug
			else
				echo
				echo "Changing log level on $node"
				echo
				sshpass -e ssh -tq $user@$node "seelog_files=\"$seelog_files\" ; logback_files=\"$logback_files\"; log_level=\"$log_level\";$(typeset -f); change_debug"
			fi
		done
	fi
}

clear
#Commented out nodes function to make single node only.
#nodes_function
while [[ $script_exit = false ]]; do
	echo "Would you lke to enable or disable debugging on DX logs?"
	echo "***This will restart the DX services***"
	select menu in "Enable" "Disable"; do
	    case $menu in
	        #Enable ) log_level="debug"; select_debug; echo "Debugging for DX services has been enabled."; script_exit=true; break;;
	        #Disable ) log_level="info"; select_debug; echo "Debugging for DX services has been disabled."; script_exit=true; break;;
			Enable ) log_level="debug"; change_debug; echo "Debugging for DX services has been enabled."; script_exit=true; break;;
	        Disable ) log_level="info"; change_debug; echo "Debugging for DX services has been disabled."; script_exit=true; break;;
	    esac
	done
done
