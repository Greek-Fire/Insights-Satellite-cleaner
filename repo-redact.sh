#/bin/bash
set -x

list_gen () {
  FILE_RE='/var/tmp/file-redaction.yaml'
  FILE_CT='/var/tmp/file-content-redaction.yaml'
  REPOS=$(ls /etc/yum.repos.d/)
  FILE_P='- /etc/yum.repos.d/'
  echo -e '---\nfiles:' > $FILE_RE
  chmod 0600 $FILE_RE $FILE_CT
  echo -e "---\npatterns:\n  regex:\n  - '\[.*?\]'" > $FILE_CT
  for r in $REPOS; do
    echo -e "$FILE_P$r" >> $FILE_RE 
  done
}

insights_prep () {
  list_gen
  if rpm -q insights-client; then
    rm -f /etc/insights-client/file-* /etc/insights-client/remove.conf
    mv $FILE_RE /etc/insights-client/file-redaction.yaml
    mv $FILE_CT /etc/insights-client/file-content-redaction.yaml
    insights-client
  else
    yum install insights-client -y
    mv $FILE_CT $FILE_IP
    mv $FILE_RE $FILE_IP
    insights-client --register
  fi
}

repo_list () {
  REPOS=$(ls /etc/yum.repos.d/)
  FILE_P='/etc/yum.repos.d/'
  enabled=()
  not_enabled=()
  for r in $REPOS; do
    enb=$(cat $FILE_P$r | grep -i 'enabled =')
    echo $enb
    if [[ $enb == 'enabled = 1' ]]; then
      echo "$(r)"
      enabled+=( $r )
    elif [[ $enb == 'enabled = 0' ]]; then
      echo $r
      not_enabled+=( $r )
    fi
  done
}

temp_disable_repo_list () {
  subscription-manager repos --disable=*
  repo_list
  $FILE_P='/etc/yum.repos.d/'
  for r in ${not_enabled[@]}; do
    sed -i "s/^enabled = 1/enabled = 0/g" $FILE_P*
  done 
  yum clean all
}

enable_repo_list () {
  subscription-manager repos --enable=*satellite-tools*
  for r in ${enabled[@]}; do
    sed -i "s/^enabled = 0/enabled = 1/g" $FILE_P$r
  done
}

run_time () {
  insights_prep
  temp_disable_repo_list
  enable_repo_list
}

run_time
