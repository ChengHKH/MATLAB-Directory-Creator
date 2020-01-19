#!/bin/bash
#
#  doAtlasRegByTask <task-list>
#      call doAtlasInstanceRegistration.sh within a task-array sge job
#
#$ -t 6-21
#$ -tc 2
#$ -e logs
#$ -o logs
#$ -l h_rt=7:00:00
#$ -l rmem=4G
#$ -pe smp 8
#####

outputDirName=output

if [[ $# < 1 ]]
then
    echo "Usage: ${0##*/}  <task-list>"
    exit 1
fi

if [[ ${SGE_TASK_ID:-x} == x ]]
then
    echo "${0##*/}: script is not called as part of a task array. Exiting ..."
    exit 1
fi

if [[ ! -d ${outputDirName} ]]
then
    echo "${0##*/}: folder \"${outputDirName}\" not found. Exiting ..."
    exit 1
fi


taskListFile=${1}
if [[ ! -s ${taskListFile} ]]
then
    echo "${0##*/}: task list file not found or empty"
    exit 1
fi


declare -a taskList
taskList=( SKIP_ZERO_INDEX $(cat ${taskListFile}) )


mvgCaseName=${taskList[${SGE_TASK_ID}]}

mvgCaseDirPath=${outputDirName}/${mvgCaseName}/mapping/

echo ${mvgCaseName}

JFScript=doAtlasJF.sh

cd ${mvgCaseDirPath}
exec ./${JFScript}