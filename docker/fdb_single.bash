#!/usr/bin/env bash
set -Eeuo pipefail
set -m

function create_cluster_file() {
    FDB_CLUSTER_FILE=${FDB_CLUSTER_FILE:-/etc/foundationdb/fdb.cluster}
    mkdir -p "$(dirname "$FDB_CLUSTER_FILE")"

    if [[ -n "$FDB_CLUSTER_FILE_CONTENTS" ]]; then
        echo "$FDB_CLUSTER_FILE_CONTENTS" > "$FDB_CLUSTER_FILE"
    elif [[ -n $FDB_COORDINATOR ]]; then
        coordinator_ip=$(dig +short "$FDB_COORDINATOR")
        if [[ -z "$coordinator_ip" ]]; then
            echo "Failed to look up coordinator address for $FDB_COORDINATOR" 1>&2
            exit 1
        fi
        coordinator_port=${FDB_COORDINATOR_PORT:-4500}
        echo "docker:docker@$coordinator_ip:$coordinator_port" > "$FDB_CLUSTER_FILE"
    else
        echo "FDB_COORDINATOR environment variable not defined" 1>&2
        exit 1
    fi
}

function create_server_environment() {
    env_file=/var/fdb/.fdbenv

    if [[ "$FDB_NETWORKING_MODE" == "host" ]]; then
        public_ip=127.0.0.1
    elif [[ "$FDB_NETWORKING_MODE" == "container" ]]; then
        public_ip=$(hostname -i | awk '{print $1}')
    else
        echo "Unknown FDB Networking mode \"$FDB_NETWORKING_MODE\"" 1>&2
        exit 1
    fi

    echo "export PUBLIC_IP=$public_ip" > $env_file
    if [[ -z $FDB_COORDINATOR && -z "$FDB_CLUSTER_FILE_CONTENTS" ]]; then
        FDB_CLUSTER_FILE_CONTENTS="docker:docker@$public_ip:$FDB_PORT"
    fi

    create_cluster_file
}

function start_fdb () {
    create_server_environment
    source /var/fdb/.fdbenv
    echo "Starting FDB server on $PUBLIC_IP:$FDB_PORT"
    fdbserver --listen-address 0.0.0.0:"$FDB_PORT" \
              --public-address "$PUBLIC_IP:$FDB_PORT" \
              --datadir /var/fdb/data \
              --logdir /var/fdb/logs \
              --locality-zoneid="$(hostname)" \
              --locality-machineid="$(hostname)" \
              --knob_disable_posix_kernel_aio=1 \
              --class "$FDB_PROCESS_CLASS" &
    fdb_pid=$(jobs -p)
    echo "fdbserver pid is: ${fdb_pid}"
}

function configure_fdb_single () {
    echo "Configuring new single memory FDB database"
    fdbcli --exec 'configure new single memory'
    sleep 3
    fdbcli --exec 'status'
}

start_fdb
sleep 5
configure_fdb_single
fg %1
