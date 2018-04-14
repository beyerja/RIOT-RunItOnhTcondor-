# Run-It-On-hTcondor (RIOT)

Small script for DESY-NAF environment that allows user to run any bash command on the BIRD system via HTCondor by a simple command.

First make the bash files executable and export the command:

```shell
chmod u+x run_it_on_condor.sh starter_script.sh
export RIOT=___path_to_script___/run_it_on_condor
```
where *\_\_\_path\_to\_script\_\_\_* is the absolute path of the script directory.

Then any bash script can be run on BIRD via HTCondor (assuming your on the correct NAF):

```shell
RIOT [--long-job] user_script.sh [user_script_arguments]
```

If the *--long-job*  argument is supplied the job will execute as bide. (Details in submit template)
