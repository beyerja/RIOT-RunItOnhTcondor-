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

job_length="SHORT"
# Separate from input line: is it a long job?, bash script name, arguments
# and set submit file according to length of job
if [[ ${1,,} == "--long-job" ]]; then 
	job_length="LONG"
	template_name="template_submit_files/long_job.submit"
	bash_script_name=${2,,}
	shift 2 # Take all arguments after the long job flag and script name
else
	template_name="template_submit_files/short_job.submit"
	bash_script_name=${1,,}
	shift 1 # Take all arguments after script name
fi

arguments=( "$@" )

# Get path from which this script was called
BASH_SCRIPT_DIR=$(pwd)
bash_script_path=${BASH_SCRIPT_DIR}/${bash_script_name}

# Create temporary submit file and starter file that does setup 
date_base="$(date +%Y%m%d%H%M%S%N)"
submit_file_path=${TMP_DIR}/${date_base}".submit"
cp ${THIS_SCRIPT_DIR}/${template_name} ${submit_file_path} 
starter_file_path=${TMP_DIR}/${date_base}".sh"
cp ${THIS_SCRIPT_DIR}/${starter_name} ${starter_file_path}
chmod u+x ${starter_file_path}

# Replace bash script name in template with this script
executable_line_number=5
sed -i "${executable_line_number}s\.*\ ${bash_script_path} $arguments \  " ${starter_file_path}
starter_line_number=8
starter_line_string="Executable = ${starter_file_path}"  
sed -i "${starter_line_number}s\.*\ ${starter_line_string} \  " ${submit_file_path}

# Start job and get job ID to keep track of if it's still running
if [[ $arguments == "" ]]; then
	echo "Executing without arguments"
	condor_job_output=$(condor_submit ${submit_file_path}) 
else 
    echo "Executing with arguments"
	condor_job_output=$(condor_submit ${submit_file_path} arguments="${arguments}")
fi
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

