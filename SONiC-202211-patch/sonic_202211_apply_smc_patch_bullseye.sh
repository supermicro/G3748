#!/bin/bash

# Copyright (c) Super Micro Computer. All rights reservered. Confidential.
# Copyright (c) Marvell, Inc. All rights reservered. Confidential.
# Description: Applying open PRs needed for compilation


#
# patch script for ARM64 AC5X based Supermicro SSE-G3748
#

#
# CONFIGURATIONS:-
#

SONIC_COMMIT="86c1bf5c155eb0a88c82a2adc6f4398b2794232f"

#
# END of CONFIGURATIONS
#

# PREDEFINED VALUES
CUR_DIR=$(basename `pwd`)
LOG_FILE=patches_result.log
FULL_PATH=`pwd`

# Path for 202211 patches
WGET_PATH="https://raw.githubusercontent.com/supermicro/G3748/master/SONiC-202211-patch/"
WGET_PATH="https://raw.githubusercontent.com/supermicro/G3748/main/SONiC-202211-patch/"
# Patches for kernel
KERN_PATCHES="github_202211_src_sonic-linux-kernel_kconfig-inclusions.patch
	github_202211_src_sonic-linux-kernel_patch.patch"

# device/platform updates
declare -a SUB_UPDATES=(SU1 SU2 SU3)
declare -A SU1=([NAME]="github_202211_device_update_for_g3748_20240131.tgz" [DIR]="./")
declare -A SU2=([NAME]="github_202211_platform_update_for_g3748_20240131.tgz" [DIR]="./")
declare -A SU3=([NAME]="github_202211_rules_update_for_g3748_20240131.tgz" [DIR]="./")
	

log()
{
    echo $@
    echo $@ >> ${FULL_PATH}/${LOG_FILE}
}

pre_patch_help()
{
    log "<<Apply patches using patch script>>"
    log "bash $0"

    log "<<FOR ARM64>> NOSTRETCH=1 make configure PLATFORM=marvell-arm64 PLATFORM_ARCH=arm64"
    log "<<FOR INTEL>> NOSTRETCH=1 make configure PLATFORM=marvell"
    log "make all"
}

apply_smc_kernel_patches()
{
    for patch in $KERN_PATCHES
    do
	echo $patch	
    	pushd patches
    	wget -c $WGET_PATH/$patch
        popd
	    patch -p1 < patches/$patch
        if [ $? -ne 0 ]; then
	        log "ERROR: Failed to apply patch $patch"
            exit 1
    	fi
    done
}

apply_device_platform_updates()
{
    CWD=`pwd`
    for SU in ${SUB_UPDATES[*]}
    do
	update=${SU}[NAME]
	dir=${SU}[DIR]
	echo "${!update}"
    	pushd patches
    	wget -c $WGET_PATH/${!update}
        popd
	    pushd ${!dir}
    	tar -zxvf $CWD/patches/${!update}
        if [ $? -ne 0 ]; then
	        log "ERROR: Failed to apply update ${!update}"
            exit 1
    	fi
	popd
    done
}

main()
{
    sonic_buildimage_commit=`git rev-parse HEAD`
    if [ "$CUR_DIR" != "sonic-buildimage" ]; then
        log "ERROR: Need to be at sonic-builimage git clone path"
        pre_patch_help
        exit
    fi

    if [ "${sonic_buildimage_commit}" != "$SONIC_COMMIT" ]; then
        log "Checkout sonic-buildimage commit to proceed"
        log "git checkout ${SONIC_COMMIT}"
        pre_patch_help
        exit
    fi

    date > ${FULL_PATH}/${LOG_FILE}
    [ -d patches ] || mkdir patches

    # Apply patches
    apply_smc_kernel_patches
    # Apply submodule patches
    apply_device_platform_updates
}

main $@
