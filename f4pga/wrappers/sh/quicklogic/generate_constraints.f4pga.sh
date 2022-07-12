#!/usr/bin/env bash
#
# Copyright (C) 2020-2022 F4PGA Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

set -e

PCF=$1
EBLIF=$2
NET=$3
PART=$4
DEVICE=$5
ARCH_DEF=$6
CORNER=$7

PROJECT=$(basename -- "$EBLIF")
IOPLACE_FILE="${PROJECT%.*}_io.place"

BIN_DIR_PATH=${BIN_DIR_PATH:="$F4PGA_ENV_BIN"}
SHARE_DIR_PATH=${SHARE_DIR_PATH:="$F4PGA_ENV_SHARE"}

PYTHON3=$(which python3)

if [[ "$DEVICE" =~ ^(qlf_.*)$ ]]; then
  if [[ "$DEVICE" =~ ^(qlf_k4n8_qlf_k4n8)$ ]];then
    DEVICE_1="qlf_k4n8-qlf_k4n8_umc22_$CORNER"
    DEVICE_2=${DEVICE_1}
    PINMAPXML="pinmap_qlf_k4n8_umc22.xml"
  elif [[ "$DEVICE" =~ ^(qlf_k6n10_qlf_k6n10)$ ]];then
    DEVICE_1="qlf_k6n10-qlf_k6n10_gf12"
    DEVICE_2=${DEVICE_1}
    PINMAPXML="pinmap_qlf_k6n10_gf12.xml"
  else
    echo "ERROR: Unknown qlf device '${DEVICE}'"
    exit -1
  fi

  PINMAP_XML=`realpath ${SHARE_DIR_PATH}/arch/${DEVICE_1}_${DEVICE_1}/${PINMAPXML}`
  IOGEN=`realpath ${BIN_DIR_PATH}/python/qlf_k4n8_create_ioplace.py`

  ${PYTHON3} ${IOGEN} --pcf $PCF --blif $EBLIF --pinmap_xml $PINMAP_XML --csv_file $PART --net $NET > ${IOPLACE_FILE}

elif [[ "$DEVICE" =~ ^(ql-.*)$ ]]; then
  DEVICE_1=${DEVICE}
  DEVICE_2="wlcsp"

  if ! [[ "$PART" =~ ^(PU64|WR42|PD64|WD30)$ ]]; then 
       PINMAPCSV="pinmap_PD64.csv"
       CLKMAPCSV="clkmap_PD64.csv"
  else
       PINMAPCSV="pinmap_${PART}.csv"
       CLKMAPCSV="clkmap_${PART}.csv"
  fi

  echo "PINMAP FILE : $PINMAPCSV"
  echo "CLKMAP FILE : $CLKMAPCSV"

  PINMAP=`realpath ${SHARE_DIR_PATH}/arch/${DEVICE_1}_${DEVICE_2}/${PINMAPCSV}`
  CLKMAP=`realpath ${SHARE_DIR_PATH}/arch/${DEVICE_1}_${DEVICE_2}/${CLKMAPCSV}`

  IOGEN=`realpath ${BIN_DIR_PATH}/python/pp3_create_ioplace.py`
  PLACEGEN=`realpath ${BIN_DIR_PATH}/python/pp3_create_place_constraints.py`

  PLACE_FILE="${PROJECT%.*}_constraints.place"

  ${PYTHON3} ${IOGEN} --pcf $PCF --blif $EBLIF --map $PINMAP --net $NET > ${IOPLACE_FILE}
  ${PYTHON3} ${PLACEGEN} --blif $EBLIF --map $CLKMAP -i ${IOPLACE_FILE} > ${PLACE_FILE}

  # EOS-S3 IOMUX configuration
  if [[ "$DEVICE" =~ ^(ql-eos-s3)$ ]]; then

      IOMUXGEN=`realpath ${BIN_DIR_PATH}/python/pp3_eos_s3_iomux_config.py`

      IOMUX_JLINK="${PROJECT%.*}_iomux.jlink"
      IOMUX_OPENOCD="${PROJECT%.*}_iomux.openocd"
      IOMUX_BINARY="${PROJECT%.*}_iomux.bin"

      ${PYTHON3} ${IOMUXGEN} --eblif $EBLIF --pcf $PCF --map $PINMAP --output-format=jlink > ${IOMUX_JLINK}
      ${PYTHON3} ${IOMUXGEN} --eblif $EBLIF --pcf $PCF --map $PINMAP --output-format=openocd > ${IOMUX_OPENOCD}
      ${PYTHON3} ${IOMUXGEN} --eblif $EBLIF --pcf $PCF --map $PINMAP --output-format=binary > ${IOMUX_BINARY}
  fi

else
    echo "FIXME: Unsupported device '${DEVICE}'"
    exit -1
fi