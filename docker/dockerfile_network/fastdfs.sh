#!/usr/bin/env bash
#  startup script for the `fastdfs` service
#  Author: wangleyi
#  Email: leyiwang.cn@gmail.com
#  File:  fastdfs.sh
#  Date: 2020/3/9 下午2:12

# ============== environment variable ==============
# MODE="storage"
# FASTDFS_IPADDRS="127.0.0.1,127.1.1.1,127.3.4.1"
# TRACKER_PORT="2222"
# STORAGE_PORT="1111"
# GROUP_ID="9"

# ============== configure file ==============
FASTDFS_DIR=/etc/fdfs
TRACKER_CONF_PATH=${FASTDFS_DIR}/tracker.conf
STORAGE_CONF_PATH=${FASTDFS_DIR}/storage.conf
MOD_FASTDFS_PATH=${FASTDFS_DIR}/mod_fastdfs.conf
CLIENT_CONF_PATH=${FASTDFS_DIR}/client.conf
CONFS_PATH_LIST=(${TRACKER_CONF_PATH} ${MOD_FASTDFS_PATH} ${MOD_FASTDFS_PATH})

# ============== default value ==============
DEFAULT_TRACKER_PORT=$(expr "`cat ${TRACKER_CONF_PATH}`" : ".*[^_]port=\([0-9]*\)")
DEFAULT_STORAGE_PORT=$(expr "`cat ${STORAGE_CONF_PATH}`" : ".*[^_]port=\([0-9]*\)")
DEFAULT_TRACKER_URL="com.ikingtech.ch116221"
DEFAULT_NGINX_LISTEN_PORT=8888

function init_env() {
    TRACKER_IP_ADDR_LIST=(`echo ${FASTDFS_IPADDRS} | tr ',' ' '` )
    if [[ ${TRACKER_PORT} == "" ]]; then
        TRACKER_PORT=${DEFAULT_TRACKER_PORT}
    fi
    if [[ ${STORAGE_PORT} == "" ]]; then
        STORAGE_PORT=${DEFAULT_STORAGE_PORT}
    fi
    if [[ ${GROUP_ID} == "" ]]; then
        GROUP_ID="1"
    fi
}

function prepare() {
    init_env
    for url in ${TRACKER_IP_ADDR_LIST[@]}
    do
        new_addr=${url}:${TRACKER_PORT}
        echo "add tracker $new_addr info ..."
        sed -i "/tracker_server=${DEFAULT_TRACKER_URL}/a\tracker_server=${new_addr}" ${STORAGE_CONF_PATH}
        sed -i "/tracker_server=${DEFAULT_TRACKER_URL}/a\tracker_server=${new_addr}" ${MOD_FASTDFS_PATH}
    done
    echo "tracker server list: ${TRACKER_IP_ADDR_LIST[@]} ..."

    sed -i "/tracker_server=${DEFAULT_TRACKER_URL}/d" ${STORAGE_CONF_PATH}
    sed -i "/tracker_server=${DEFAULT_TRACKER_URL}/d" ${MOD_FASTDFS_PATH}

    sed -i "s/^port=.*$/port=${STORAGE_PORT}/g" ${STORAGE_CONF_PATH}
    sed -i "s/^group_name=group1/group_name=group${GROUP_ID}/g" ${STORAGE_CONF_PATH}
    sed -i "s/^group_name=group1/group_name=group${GROUP_ID}/g" ${MOD_FASTDFS_PATH}

    mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.t
    cp /etc/fdfs/nginx.conf /usr/local/nginx/conf
    cat ${FASTDFS_DIR}/mod_fastdfs.conf > ${FASTDFS_DIR}/mod_fastdfs.txt
}

function start_tracker() {
    prepare
    echo "start trackerd ..."
    /etc/init.d/fdfs_trackerd start
    tail -f  /dev/null
}

function start_storage() {
    prepare
    echo "start storage"
    /etc/init.d/fdfs_storaged start

    echo "start nginx"
    /usr/local/nginx/sbin/nginx
    tail -f  /dev/null
}

function init_client() {
    init_env
    for url in ${TRACKER_IP_ADDR_LIST[@]}
    do
        new_addr=${url}:${TRACKER_PORT}
        echo "add tracker $new_addr info ..."
        sed -i "/tracker_server=${DEFAULT_TRACKER_URL}/a\tracker_server=${new_addr}" ${CLIENT_CONF_PATH}
    done
    sed -i "/tracker_server=${DEFAULT_TRACKER_URL}/d" ${CLIENT_CONF_PATH}
    cat ${FASTDFS_DIR}/client.conf > ${FASTDFS_DIR}/client.txt
    tail -f /dev/null
}

case ${MODE} in
    tracker )
        start_tracker;;
    storage )
        start_storage;;
    * )
        init_client;;
esac
