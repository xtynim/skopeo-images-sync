#!/bin/bash
# Synchronize images by skopeo copy
# Use YQ to Parse ymal file

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin; export PATH

IMAGES_FILE=$1
IMAGES_REPO=$2
IMAGES_MULTIPATHS=$3
SKOPEO_USERNAME=${USERNAME}
SKOPEO_PASSWORD=${PASSWORD}
SKOPEO_AUTHFILE=${AUTHFILE:-'./containers/auth.json'}

getSyncStatus()
## 获取同步状态，参数：注册表名称, 仓库名称， Tag名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local TAG=$3
    local SYNCSTATUS_FILE=${4:-$IMAGES_FILE}.sync

    if [ ! -f "${SYNCSTATUS_FILE}" ]; then
        echo -e "# 已同步镜像列表\n" >${SYNCSTATUS_FILE}
    fi
    eval $(echo "yq -e '.\"${REGISTRY}\".images.\"${REPOSITORY}\".[] | select(. == \"${TAG}\")' ${SYNCSTATUS_FILE}") 2>/dev/null
    return $?
}

updateSyncStatus()
## 写入同步结果，参数：注册表名称, 仓库名称， Tag名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local TAG=$3
    local SYNCSTATUS_FILE=${4:-$IMAGES_FILE}.sync

    local line=$(eval $(echo "yq '.\"${REGISTRY}\".images.\"${REPOSITORY}\".[]' ${SYNCSTATUS_FILE} | wc -l"))
    eval $(echo "yq -i '.\"${REGISTRY}\".images.\"${REPOSITORY}\".["${line}"] = \"${TAG}\"' ${SYNCSTATUS_FILE}")
    eval $(echo "yq -i 'with(.\"${REGISTRY}\".images; . = sort_keys(.))' ${SYNCSTATUS_FILE}")
    eval $(echo "yq -i 'with(.\"${REGISTRY}\".images.\"${REPOSITORY}\"; . = (. | sort | unique))' ${SYNCSTATUS_FILE}")
    eval $(echo "yq -i '.\"${REGISTRY}\".updated = now' ${SYNCSTATUS_FILE}")
}

getRegistry()
## 获取注册表地址列表
{
    local IMAGES_FILE=${1:-$IMAGES_FILE}

    local registry=$(yq 'keys' ${IMAGES_FILE} | awk '{print $2}')
    echo $registry
}

getRepository()
## 获取仓库地址列表，参数：注册表名称
{
    local REGISTRY=$1
    local IMAGES_FILE=${2:-$IMAGES_FILE}

    local repository=$(eval $(echo "yq '.\"${REGISTRY}\".images[] | key' ${IMAGES_FILE}"))
    echo $repository
}

getTag()
## 获取仓库Tags列表，参数：注册表名称, 仓库名称
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local IMAGES_FILE=${3:-$IMAGES_FILE}

    local tags=$(eval $(echo "yq '.\"${REGISTRY}\".images.\"${REPOSITORY}\"' ${IMAGES_FILE} ") | awk '{print $2}')
    echo $tags
}

skopeoCopy()
## 同步镜像到目标仓库，参数：注册表名称, 仓库名称, 镜像Tag，目标仓库地址，多路径处理
{
    local REGISTRY=$1
    local REPOSITORY=$2
    local TAG=$3
    local IMAGES_REPO=$4
    local IMAGES_MULTIPATHS=$5

    if [ ! "$(getSyncStatus ${REGISTRY} ${REPOSITORY} ${TAG})" ]; then
        echo "+ skopeo copy docker://${REGISTRY}/${REPOSITORY}:${tag} docker://${IMAGES_REPO}/${REPOSITORY}:${TAG}"
        if [ "${IMAGES_MULTIPATHS^^}X" == "REPLACEX" ]; then
            echo "  => ${IMAGES_REPO}/${REPOSITORY//\//_}:${TAG}"
            skopeo copy --retry-times 5 docker://${REGISTRY}/${REPOSITORY}:${tag} docker://${IMAGES_REPO}/${REPOSITORY//\//_}:${TAG}
        elif [ "${IMAGES_MULTIPATHS^^}X" == "DELETEX" ]; then
            echo "  => ${IMAGES_REPO}/${REPOSITORY##*/}:${TAG}"
            skopeo copy --retry-times 5 docker://${REGISTRY}/${REPOSITORY}:${tag} docker://${IMAGES_REPO}/${REPOSITORY##*/}:${TAG}
        elif [ "${IMAGES_MULTIPATHS^^}X" == "SUFFIXX" ]; then
            echo "  => ${IMAGES_REPO}/${REPOSITORY##*/}:${TAG}-${REPOSITORY%%/*}"
            skopeo copy --retry-times 5 docker://${REGISTRY}/${REPOSITORY}:${tag} docker://${IMAGES_REPO}/${REPOSITORY##*/}:${TAG}-${REPOSITORY%%/*}
        else
            skopeo copy --retry-times 5 docker://${REGISTRY}/${REPOSITORY}:${tag} docker://${IMAGES_REPO}/${REPOSITORY}:${TAG}
        fi
        updateSyncStatus ${REGISTRY} ${REPOSITORY} ${TAG}
    fi
}

## Login to the Container registry
# if [ ! -f "${SKOPEO_AUTHFILE}" ]; then
#     echo "${SKOPEO_PASSWORD}" | skopeo login -u "${SKOPEO_USERNAME}" --password-stdin ${IMAGES_REPO%%/*}
# fi

## Synchronize Container images
# skopeo copy docker://docker.io/bitnami/git:2.35.0 docker://hub.local.lan/repo/bitnami/git:2.35.0
# REGISTRY=$(getRegistry)
for reg in $(getRegistry);
do
    # REPOSITORY=$(getRepository $reg)
    for repo in $(getRepository $reg);
    do
        # TAGS=$(getTag $reg $repo)
        for tag in $(getTag $reg $repo);
        do
            # skopeo copy --retry-times 5 docker://${reg}/${repo}:${tag} docker://${IMAGES_REPO}/${repo}:${tag}
            skopeoCopy ${reg} ${repo} ${tag} ${IMAGES_REPO} ${IMAGES_MULTIPATHS}
        done
    done
done
