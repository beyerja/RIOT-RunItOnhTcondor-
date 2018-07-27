#!/bin/bash

# run_it_on_conder.sh script allows you to take bash script
# and its arguments and run it on condor using default settings.

# Location of this run_it_on_conder.sh script
THIS_SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
TMP_DIR=${THIS_SCRIPT_DIR}/tmp_submit_files
starter_name=starter_script.sh


if [[  $# < 1 ]] ; then
	echo "ERROR: Script execution: run_it_on_condor [--long-job] script.sh [arguments]."
	echo "Exiting."
	exit
fi

# Separate from input line: is it a long job?, bash script name, arguments
# and set submit file according to length of job
if [[ ${1,,} == "--long-job" ]]; then
	echo "0"
	template_name="template_submit_files/long_job.submit"
	bash_script_name=${2}
	shift 1 # Take all arguments after the long job flag
else
	echo "1"
	template_name="template_submit_files/short_job.submit"
	bash_script_name=${1}
fi

# Create output dir if non-existent
condor_output_dir=${THIS_SCRIPT_DIR}/Condor_output
if [ ! -d ${condor_output_dir} ]; then
	mkdir ${condor_output_dir}
fi

# Create dir for temporary steering files if non-existent
if [ ! -d ${TMP_DIR} ]; then
	mkdir ${TMP_DIR}
fi

arguments="$@"

# Get path from which this script was called
BASH_SCRIPT_DIR=$(pwd)

# Create temporary submit file and starter file that does setup
date_base="$(date +%Y%m%d%H%M%S%N)"
submit_file_path=${TMP_DIR}/${date_base}".submit"
cp ${THIS_SCRIPT_DIR}/${template_name} ${submit_file_path}
starter_file_path=${TMP_DIR}/${date_base}".sh"
cp ${THIS_SCRIPT_DIR}/${starter_name} ${starter_file_path}
chmod u+x ${starter_file_path}

# Replace bash script name in template with this script
local_dir_line_number=5
sed -i "${local_dir_line_number}s\.*\ cd ${BASH_SCRIPT_DIR}\  " ${starter_file_path}
executable_line_number=7
sed -i "${executable_line_number}s\.*\ ${bash_script_name} $arguments \  " ${starter_file_path}
starter_line_number=12
starter_line_string="Executable = ${starter_file_path}"
sed -i "${starter_line_number}s\.*\ ${starter_line_string} \  " ${submit_file_path}

# Replace logging paths
output_line_number=7
error_line_number=$(( output_line_number + 1 ))
log_line_number=$(( output_line_number + 2 ))
output_line_string="output = ${condor_output_dir}/last_job.out"
error_line_string="error = ${condor_output_dir}/last_job.err"
log_line_string="log = ${condor_output_dir}/last_job.log"
sed -i "${output_line_number}s\.*\ ${output_line_string} \  " ${submit_file_path}
sed -i "${error_line_number}s\.*\ ${error_line_string} \  " ${submit_file_path}
sed -i "${log_line_number}s\.*\ ${log_line_string} \  " ${submit_file_path}

# Send submit to HTCondor
echo "Executing"
condor_job_output=$(condor_submit ${submit_file_path})
condor_job_ID=${condor_job_output##* }

# Wait until job is done before removing submit file
username=$USER
while [[ $(condor_q -nobatch ${username}) == *$condor_job_ID* ]] ; do
	sleep 5
done

echo "Done."

# Clean up
rm ${submit_file_path}
rm ${starter_file_path}
