#!/bin/bash

# Verify variables and build config accordingly
if [ -v $SERVER ]; then
        sed -i "s/server\=localhost:4730/server\=$SERVER/" /etc/mod_gearman/worker.conf
else
        echo "SERVER not defined with -e SERVER=gearmandhost:port"
        echo "SERVER variable is required for this to function"
        exit 2
fi
if [ -v $HOSTGROUP ]; then
        sed -i "s/\#identifier\=hostname/identifier\=$HOSTGROUP/" /etc/mod_gearman/worker.conf
        sed -i "s/\#hostgroups\=name1/hostgroups\=$HOSTGROUP/" /etc/mod_gearman/worker.conf
else
        echo "---!!!WARNING!!!---"
        echo "HOSTGROUP(s) not defined with -e HOSTGROUP=hg1,hg2,hg3"
        echo "if this worker needs to accept a specific set of jobs at least one HOSTGROUP or SERVICEGROUP is required"
fi
if [ -v $SERVICEGROUP ]; then
        sed -i "s/\#servicegroups\=name1\,name2\,name3/servicegroups\=$SERVICEGROUP/" /etc/mod_gearman/worker.conf
else
        echo "---!!!WARNING!!!---"
        echo "SERVICEGROUP(s) not defined with -e SERVICEGROUP=sg1"
        echo "if this worker needs to accept a specific set of jobs at least one HOSTGROUP or SERVICEGROUP is required"
fi
if [ -v $GEARMANKEY ]; then
        if [ -r "$GEARMANKEY" ]; then
                sed -i "s/\#keyfile\=\/path\/to\/secret.file/keyfile\=$GEARMANKEY/" /etc/mod_gearman/worker.conf
        elif [ -n "$GEARMANKEY" ]; then
                sed -i "s/key\=should_be_changed/key=$GEARMANKEY/" /etc/mod_gearman/worker.conf
        else
                echo "---!!!WARNING!!!---"
                echo "GEARMANKEY not defined with -e GEARMANKEY=key or -e GEARMANKEY=/path/to/key.file"
                echo "GEARMANKEY is not required, but recommended to increase security"
        fi
else
        echo "---!!!WARNING!!!---"
        echo "GEARMANKEY not defined with -e GEARMANKEY=key or -e GEARMANKEY=/path/to/key.file"
        echo "GEARMANKEY is not required, but recommended to increase security"
fi
if [ -v $CUSTOMCONFIG ]; then
        if [ "$CUSTOMCONFIG" == "true" ]; then
                echo "copying custom config to /etc/mod_gearman/worker.conf"
                cp -f /tmp/worker.conf /etc/mod_gearman/worker.conf
                echo "starting modgearman worker"
        else
                echo "starting modgearman worker"
        fi
fi
# Export Oracle home directory
export ORACLE_HOME=/usr/lib/oracle/12.2/client64
export LD_LIBRARY_PATH=/usr/lib/oracle/12.2/client64/lib

# Start gearman worker
/bin/mod_gearman_worker --logmode=stdout --config=/etc/mod_gearman/worker.conf --pidfile=/var/mod_gearman/mod_gearman_worker.pid
