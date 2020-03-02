#!/bin/bash
# build-utils.sh, ABr
# Helper functions for the POC

########################################################################
# local folder
g_CURDIR="$(pwd)"
g_SCRIPT_FOLDER_RELATIVE=$(dirname "$0")
cd "$g_SCRIPT_FOLDER_RELATIVE"
g_SCRIPT_FOLDER_ABSOLUTE="$(pwd)"
cd ..
g_SCRIPT_FOLDER_PARENT_ABSOLUTE="$(pwd)"
cd "$g_CURDIR"

# send output to stderr
echoerr() { echo "$@" 1>&2; }

########################################################################
# internal: MiniShift data file
build-utils-i-minishift-last-start-data() {
  local l_minishift_data_file='./.localdata/minishift/last-start/data.txt'
  echo "$l_minishift_data_file"
}

########################################################################
# internal: scan file for MiniShift server connector
build-utils-i-minishift-server-host() {
  local i_data_file="$1" ; shift

  # if no last-start data available, get out
  [ ! -s "$i_data_file" ] && echo '' && return 0

  # read host line from last-start file - required
  local l_minishift_host_line=$(tac "$i_data_file" | grep -m1 -e 'https\?://' | sed -e 's#\s##g')
  [ x"$l_minishift_host_line" = x ] && echoerr "Missing server line in '$i_data_file'"  && return 2

  # return the value
  echo $l_minishift_host_line | sed -e 's#^https\?://\(.*\)#\1#'
}

########################################################################
# internal: MiniShift server connector IP
build-utils-i-minishift-server-host-ip() {
  build-utils-i-minishift-server-host "$@" | awk -F':' '{print $1}'
}

########################################################################
# internal: MiniShift server connector port
build-utils-i-minishift-server-host-port() {
  build-utils-i-minishift-server-host "$@" | awk -F':' '{print $2}'
}

########################################################################
# internal: forward or cleanup mac port forward
build-utils-i-minishift-mac-port-forward() {
  # input
  local i_command="$1" ; shift

  # local vars
  local l_minishift_data_file=$(build-utils-i-minishift-last-start-data)
  local l_minishift_host_ip=$(build-utils-i-minishift-server-host-ip "$l_minishift_data_file")
  [ x"$l_minishift_host_ip" = x ] && return 0
  local l_minishift_host_port=$(build-utils-i-minishift-server-host-port "$l_minishift_data_file")
  [ x"$l_minishift_host_port" = x ] && return 0

  # invoke command
  lm-docker-mac-port-forward.sh $i_command \
    ${SAB_MINISHIFT_HOST_IP_ADDR} ${SAB_MINISHIFT_HOSTPORT} \
    $l_minishift_host_port $l_minishift_host_ip
}

########################################################################
# internal: account for "improved" 'minishift status'
build-utils-i-minishift-status() {
  minishift status | grep -ie '^minishift:\s' | awk -F' ' '{print $2}' | tr '[A-Z]' '[a-z]'
}

########################################################################
# internal: MiniShift wrappers
build-utils-i-minishift() {
  # input
  local i_command="$1" ; shift

  # locals
  local l_rc=0
  local l_minishift_status=''
  local l_tmp_file=''
  local l_performed_docker_restart=0

  # no minishift? we are Done
  if ! which minishift >/dev/null 2>&1 ; then
    echoerr "Missing minishift binary" && return 2
  fi

  # no hyperkit? we are Done
  if ! which hyperkit >/dev/null 2>&1 ; then
    echoerr "Missing hyperkit binary (is Docker Desktop installed?)" && return 2
  fi

  # handle commands
  l_tmp_file="/tmp/build-utils-i-minishift.$$"
  l_minishift_status=$(build-utils-i-minishift-status)
  case $i_command in
    status)
      minishift status
      return $?
      ;;
    is-avail)
      [ "$l_minishift_status" != x ] && return 0
      return 1
      ;;
    is-running)
      if echo "$l_minishift_status" | grep --quiet -i 'running' ; then
        return 0
      else
        return 1
      fi
      ;;
    start)
      if ! echo "$l_minishift_status" | grep --quiet -i 'running' ; then
        eval minishift start $SAB_MINISHIFT_START_ARGS 2>&1 | tee ./.localdata/minishift/last-start.txt
        l_rc=$?
        [ $l_rc -ne 0 ] && return $l_rc

        # post-process
        #$g_SCRIPT_FOLDER_ABSOLUTE/minishift-helpers.sh minishift-post-std-config >"$l_tmp_file" 2>&1
        echo 'OK'
        l_rc=$?
        l_performed_docker_restart=0
        if [ -f "$l_tmp_file" ] ; then
          if grep --quiet -e 'PERFORMED_DOCKER_RESTART' "$l_tmp_file" ; then
            l_performed_docker_restart=1
          fi
        fi
        if [ $l_rc -eq 0 ] ; then
          if [ $l_performed_docker_restart -eq 1 ] ; then
            # restart minishift - a one-time restart had to occur
            minishift stop
            eval minishift start $SAB_MINISHIFT_START_ARGS
            l_rc=$?
          fi
        fi
      fi
      ;;
    stop)
      if echo "$l_minishift_status" | grep --quiet -i 'running' ; then
        minishift stop
        l_rc=$?
        [ $l_rc -ne 0 ] && return $l_rc
      fi
      ;;
    oc)
      eval $(minishift oc-env)
      l_rc=$?
      [ $l_rc -ne 0 ] && return $l_rc
      oc "$@"
      ;;
    docker)
      eval $(minishift docker-env)
      l_rc=$?
      [ $l_rc -ne 0 ] && return $l_rc
      docker "$@"
      ;;
    delete)
      minishift delete --clear-cache
      rm -fR ~/.minishift
      rm -fR ~/.kube/192.168.64.5_8443
      yes | cp ~/.kube/kubeconfig-orig.config ~/.kube/config 
      ;;
    cmd)
      minishift "$@"
      l_rc=$?
      ;;
    login)
      if echo "$l_minishift_status" | grep --quiet -i 'running' ; then
        # set environment
        eval $(minishift oc-env)
        l_rc=$?
        [ $l_rc -ne 0 ] && return $l_rc

        # do a login
        oc login -u system:admin
        l_rc=$?
        [ $l_rc -ne 0 ] && return $l_rc
      fi
      ;;
  esac

  # final result
  rm -f "$l_tmp_file"
  return $l_rc
}

########################################################################
# MiniShift wrappers (accounts for MiniShift)
build-utils-x-minishift() {
  # input
  local i_command="$1" ; shift

  # locals
  local l_rc=0
  local l_minishift_status=''

  # setup env (sans KUBECONFIG)
  source "$g_SCRIPT_FOLDER_ABSOLUTE"/env-wrapper.sh 'source-only'
  l_rc=$?
  [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc

  # thunk to internal function
  build-utils-i-minishift "$i_command" "$@"
}

########################################################################
# start everything
build-utils-x-up() {
  # locals
  local l_rc=0
  local l_minishift_data_file=$(build-utils-i-minishift-last-start-data)

  # setup env
  source "$g_SCRIPT_FOLDER_ABSOLUTE"/env-wrapper.sh
  l_rc=$?
  [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc
  export KUBECONFIG=$SAB_MINISHIFT_KUBE_CONFIG

  # build the environment (deploys to local kubernetes)
  echo '***Build project...'
  "$g_SCRIPT_FOLDER_ABSOLUTE"/make-wrapper.sh -f "$g_SCRIPT_FOLDER_PARENT_ABSOLUTE"/Makefile build
  l_rc=$?
  [ $l_rc -ne 0 ] && return $l_rc
  echo ''
  echo ''

  # start minishift
  mkdir -p $(dirname "$l_minishift_data_file")
  if ! build-utils-i-minishift is-running ; then
    echo '***Start MiniShift...'
    build-utils-i-minishift start > "$l_minishift_data_file" 2>&1
    l_rc=$?
    [ $l_rc -ne 0 ] && return $l_rc
    echo ''
    echo ''
  fi

  # create port forwards
  if [ x"$SAB_MINISHIFT_IS_KUBE_FOR_MAC" != x ] ; then
    echo '***Create port forwarding...'
    #build-utils-i-minishift-mac-port-forward update
    "$g_SCRIPT_FOLDER_ABSOLUTE"/make-wrapper.sh -f "$g_SCRIPT_FOLDER_PARENT_ABSOLUTE"/Makefile mac-port-forwards
    l_rc=$?
    [ $l_rc -ne 0 ] && return $l_rc
    echo ''
    echo ''
  fi

  # all appears well
  return 0
}

########################################################################
# stop everything
build-utils-x-down() {
  # locals
  local l_rc=0
  local l_minishift_status=''

  # setup env
  source "$g_SCRIPT_FOLDER_ABSOLUTE"/env-wrapper.sh
  l_rc=$?
  [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc
  export KUBECONFIG=$SAB_MINISHIFT_KUBE_CONFIG

  # stop minishift
  echo '***Stop MiniShift...'
  build-utils-i-minishift stop
  l_rc=$?
  [ $l_rc -ne 0 ] && return $l_rc
  echo ''
  echo ''

  # cleanup environment
  echo '***Clean local project...'
  "$g_SCRIPT_FOLDER_ABSOLUTE"/make-wrapper.sh -f "$g_SCRIPT_FOLDER_PARENT_ABSOLUTE"/Makefile clean
  l_rc=$?
  [ $l_rc -ne 0 ] && return $l_rc
  echo ''
  echo ''

  # all appears well
  return 0
}

########################################################################
# is minishift running?
build-utils-x-minishift-is-running() {
  # locals
  local l_rc=0
  local l_status=0

  # check status
  l_status=$(build-utils-i-minishift-status)
  l_rc=$?
  [ $l_rc -ne 0 ] && return 1
  [ x"$l_status" = x'running' ] && return 0
  return 1
}

########################################################################
# run a command through the minishift docker
build-utils-i-minishift-docker() {
  # locals
  local l_rc=0

  # setup env
  eval $(minishift docker-env)
  l_rc=$? ; [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc

  # now the command
  docker run --rm -it --privileged --pid=host centos:7 nsenter -t 1 -m -u -n -i \
    sh -c "$@"
}

########################################################################
# run a command through the minishift docker
build-utils-x-minishift-docker() {
  # locals
  local l_rc=0

  # setup env
  eval $(minishift docker-env)
  l_rc=$? ; [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc

  # now the command
  docker run --rm -it --privileged --pid=host centos:7 nsenter -t 1 -m -u -n -i \
    "$@"
}

########################################################################
# initialize MiniShift environment
build-utils-x-minishift-init() {
  # locals
  local l_rc=0
  local l_pwd=''
  local l_msg=''

  # must be running
  if ! build-utils-x-minishift-is-running ; then
    echoerr 'MiniShift: Not Running'
    return 1
  fi

  echo 'MiniShift: Initialize...'

  # load the environment
  source "$g_SCRIPT_FOLDER_ABSOLUTE"/env-wrapper.sh 'source-only'
  l_rc=$?
  [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc

  # setup environment
  if [ x"$SAB_MINISHIFT_IS_MINISHIFT" != x ]; then
    echo 'Using MiniShift...'
    eval $(minishift oc-env)
    l_rc=$? ; [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc
    echo ''
    echo "Verify MiniShift Docker access to git host '$SAB_MINISHIFT_GIT_HOST'..."
    #build-utils-i-minishift-docker-install-host "$SAB_MINISHIFT_GIT_HOST"
    #l_rc=$? ; [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc
    #set -x
    l_msg=$(build-utils-i-minishift-docker "ping -c 1 -w 5 $SAB_MINISHIFT_GIT_HOST >/dev/null 2>&1; ping -c 1 -w 5 $SAB_MINISHIFT_GIT_HOST && echo PING_OK")
    l_rc=$? ; [ $l_rc -ne 0 ] && echoerr 'Failure' && return $l_rc
    set +x
    if ! echo "$l_msg" | grep --quiet -e 'PING_OK' ; then
      echoerr "  Failed accessing git host."
      return 1
    fi
  fi

  # all appears well
  return 0
}

########################################################################
# optional call support
l_do_run=0
if [ "x$1" != "x" ]; then
  [ "x$1" != "xsource-only" ] && l_do_run=1
fi
if [ $l_do_run -eq 1 ]; then
  l_func="$1"; shift
  [ x"$l_func" != x ] && eval build-utils-x-"$l_func" "$@"
fi

