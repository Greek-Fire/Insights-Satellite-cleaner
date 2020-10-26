#/bin/bash
#set -x

list_gen () {
  FILE_RE='/var/tmp/file-redaction.yaml'
  FILE_CT='/var/tmp/file-content-redaction.yaml'
  REPOS=$(ls /etc/yum.repos.d/)
  FILE_P='- /etc/yum.repos.d/'
  echo -e '---\nfiles:' > $FILE_RE
  echo -e "---\npatterns:\n  regex:\n  - '\[.*?\]'" > $FILE_CT
  chmod 0600 $FILE_RE $FILE_CT
  for r in $REPOS; do
    echo -e "$FILE_P$r" >> $FILE_RE 
  done
}

install_insights () {
  INSTALL=$(rpm -q insights-client)
  if [[ $INSTALL == *'not installed'* ]]; then
    echo "Insights in not Install"
    subscription-manager repos --enable=*
    yum install insights-client -y
    subscription-manager repos --disable=* 
  fi
}

repo_list () {
  REPOS=$(ls /etc/yum.repos.d/)
  TEST=(grep -r 'enabled = 0' /etc/yum.repos.d/*)
  FILE_P='/etc/yum.repos.d/'
  ENABLED=()
  if [[ -z $TEST ]]; then
    for r in $REPOS; do
      echo  $FILE_P$r
      enb=$(cat $FILE_P$r | grep enabled)
      if [[ $enb == *'1'* ]]; then
        ENABLED+=( $r )
        echo ${ENABLED[@]}
      fi
    done
  fi
}

temp_disable_repo_list () {
  list_gen
  repo_list
  echo "Disabling all Repos"
  subscription-manager repos --disable=*
  sed -i 's/^enabled = 1/enabled = 0/' /etc/yum.repos.d/*
  yum clean all
}

enable_repo_list () {
  subscription-manager repos --enable=*satellite-tools*
  for r in ${enabled[@]}; do
    echo $r
    sed -i 's/^enabled = 0/enabled = 1/' $FILE_P$r
  done
  echo ${enabled[@]}
}

run_insights () {
  INSTIGHT_TEST=$(insights-client --status)
  if [[ $INSTIGHT_TEST == 'System is NOT registered'* ]]; then
    echo " System is NOT registered, registering..."
    insights-client --register
    mv $FILE_RE /etc/insights-client/file-redaction.yaml
    mv $FILE_CT /etc/insights-client/file-content-redaction.yaml
  else
    rm -f /etc/insights-client/file-* /etc/insights-client/remove.conf
    insights-client
    mv $FILE_RE /etc/insights-client/file-redaction.yaml
    mv $FILE_CT /etc/insights-client/file-content-redaction.yaml
  fi
}

run_time () {
  temp_disable_repo_list
  install_insights
  run_insights
  enable_repo_list
}

run_time
