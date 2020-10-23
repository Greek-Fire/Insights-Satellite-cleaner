#/bin/bash
set -x


list-gen () {
  FILE_RE='/var/tmp/file-redaction.yaml'
  REPOS=$(ls /etc/yum.repos.d/)
  FILE_P='- /etc/yum.repos.d/'
  echo -e "---\nfiles:" > $FILE_RE
  for r in $REPOS; do
    echo -e "$FILE_P$r" >> $FILE_RE
  done
}

insights-prep () {
  list-gen
  FILE_IP='/etc/insights-client/file-redaction.yaml'
  if rpm -q insights-client; then
    rm -f '/etc/insights-client/file-content-redaction.yaml /etc/insights-client/remove.conf'
    mv $FILE_RE $FILE_IP
    insights-client
  else
    yum install insights-client -y
    insights-client --register
  fi
}

insights-prep
