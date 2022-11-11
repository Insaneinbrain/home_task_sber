#!/bin/sh
SERVER=machine120.test
PORT=8180
PYTHON='/usr/bin/python3'
CURL='/usr/bin/curl -sSL'
PY=job.py
WORCK_DIR=/home/vagrant/Job

_erroe_exit()
{
 if [ "X$1" != "X0" ]; then
  echo `date`" $2" >&2
  exit $1
 fi
}

cd $WORCK_DIR
_erroe_exit $? "Error"
$CURL http://$SERVER:$PORT | $PYTHON ./$PY | grep -v '^{.*}$'
_erroe_exit $? "CURL terminated ERRORS"
