#!/bin/bash

psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

export PGPASSWORD=$psql_password

vmstat_mb=$(vmstat --unit M)
hostname=$(hostname -f)

#usage info
memory_free=$(echo "$vmstat_mb" | tail -1 | awk -v col="4" '{print $col}')
cpu_idle=$(echo "$vmstat_mb" | tail -1 | awk -v col="15" '{print $col}')
cpu_kernel=$(echo "$vmstat_mb"  | tail -1 | awk -v col="14" '{print $col}')
disk_io=$(vmstat --unit M -d | tail -1 | awk -v col="10" '{print $col}')
disk_available=$(df -BM / | tail -1 | awk -v col="4" '{print $col}')
disk_available=${disk_available::-1}
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

#Subquery to find host id
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')";
get_host_id=$(psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$host_id")
host_id=$(echo "$get_host_id"| tail -2 | head -1 | xargs)
echo "$host_id"

insert_stmt="INSERT INTO host_usage (\"timestamp\", host_id, memory_free, cpu_idle, cpu_kernel, disk_io,
disk_available) VALUES('$timestamp', '$host_id', '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available');"

psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?