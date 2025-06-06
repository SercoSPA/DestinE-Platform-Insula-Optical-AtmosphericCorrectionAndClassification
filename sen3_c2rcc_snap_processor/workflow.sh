#!/bin/bash

set -x -e

success=0
fail_multiple_input=10
fail_file_not_found=11
fail_inputs=12
fail_uncompress=20
fail_tools=30
fail_graph=40

# FS-TEP service environment
readonly WORKFLOW=$(dirname $(readlink -f "$0"))
readonly WORKER_DIR="/home/worker"
readonly IN_DIR="${WORKER_DIR}/workDir/inDir"
readonly OUT_DIR="${WORKER_DIR}/workDir/outDir"
readonly WPS_PROPS="${WORKER_DIR}/workDir/FSTEP-WPS-INPUT.properties"
readonly PROC_DIR="${WORKER_DIR}/procDir"
readonly TIMESTAMP=$(date --utc +%Y%m%d_%H%M%SZ)
readonly PROC_DIR_TMP="${PROC_DIR}/tmp"
readonly PROC_DIR_TMP_IMAGE="${PROC_DIR}/tmp_image"
readonly RESULT_PATH_GTIF="${OUT_DIR}/output"
readonly RESULT_PATH_NETCDF="${OUT_DIR}/output_nc"
readonly python_dir="${PROC_DIR}/venv/bin/python3" #non capisco perche si deve definire il path di python
# Input parameters available as shell variables

if test -f "${WPS_PROPS}"
then
    source ${WPS_PROPS}
fi

# SNAP specific
readonly GPT_BIN="/usr/local/snap/bin/gpt"
readonly LOCAL_SNAP_GRAPH_c2rcc="${PROC_DIR}/GPT_config_template_subset_idepix_c2rcc.xml"
readonly LOCAL_SNAP_GRAPH_reproj="${PROC_DIR}/GPT_config_template_subset_flag_reproject_chl.xml"

log() {

  local log_level=$1
  local log_msg=${@:2}

  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [${log_level}] - ${log_msg}" >&2
}

info() {
  log "INFO" $@
}

err() {
  log "ERROR" $@
}

prepare_env() {
  mkdir -p ${RESULT_PATH_GTIF}
  mkdir -p ${RESULT_PATH_NETCDF}
}

launch_snap() {

  info "${GPT_BIN} $@"
  ${GPT_BIN} $@ || return $?

}

main() {

  prepare_env || return $?
  res=$?
  if [[ ${res} -ne 0 ]]; then
    return ${res}
  fi

  input="${IN_DIR}/input"
  input_xml=$(find ${input} -name "xfdumanifest.xml" -type f)

  # == workaround working only for single product input!!!,
  # as SNAP expects for Sentinel3 the input folder name after the productName, which is not always the case
  sentinel3_product_name=$(sed -n 's#.*<sentinel3:productName>\(.*\)</sentinel3:productName>.*$#\1#p' ${input_xml})
  mkdir -p ${input}/${sentinel3_product_name}
  find ${input}/ -type f -print0 | xargs -0 mv -t ${input}/${sentinel3_product_name}
  input_xml=$(find ${input}/${sentinel3_product_name} -name "xfdumanifest.xml" -type f)
  # == end of workaround

  input_nc=$(find ${input} -maxdepth 1 -name '*.SEN3' -type d)
  filename=$(basename ${input_nc%.SEN3})
  tmp_file="${PROC_DIR_TMP}/${filename}_c2rcc.nc"
  out_file="${PROC_DIR_TMP}/${filename}_CHL_NN.tif"
  echo -e "Processing Sentinel3 file: \natmospheric correction, \nscene classification \nand generation of some phisical paramethers i.e. chlorophyll content"
  ${GPT_BIN} ${LOCAL_SNAP_GRAPH_c2rcc} -Pinput_img="${input_xml}" -Pgeo_region="${aoi}" -Poutput_product="${tmp_file}" || return $?
  echo -e "Extracting chlorophyll percentage concentration \nand converting netcdf file to geotiff"
  ${GPT_BIN} ${LOCAL_SNAP_GRAPH_reproj} -Pinput_img="${tmp_file}" -Pgeo_region="${aoi}" -Poutput_product="${out_file}" || return $?

  path_code="${WORKFLOW}/extract_tif.py"

  ${python_dir} ${path_code} -input_path "${PROC_DIR_TMP}" -output_path "${RESULT_PATH_GTIF}" || return $?
  if [ $? -ne 0 ]
  then
  exit 1
  fi
  cp ${tmp_file} ${RESULT_PATH_NETCDF}/
}

main $@ || exit $?
