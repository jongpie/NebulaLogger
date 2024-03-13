now=$(date +"%Y-%m-%dT%H_%M_%S%z")
logDirectory="logs"

echo "Starting sf apex tail log at ${now}"
[[ -d ${logDirectory} ]] || mkdir ${logDirectory}
sf apex tail log --color | tee ./${logDirectory}/sf_tail_${now}.log
