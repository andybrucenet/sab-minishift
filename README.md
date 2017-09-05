# E-Z MiniShift

Want a quick [MiniShift](https://github.com/minishift/minishift) that auto-adjusts to your Mac and does not interfere with any existing Docker you have running? (Remember that MiniShift on Mac OSx runs its own Docker.)

You've come to the right place. Pull down this repo, and issue a single command to set everything up.

# Table of Contents

1. [Prerequisites](#prerequisites)
1. [Running the Environment](#running-the-environment)
1. [MiniShift Access and Commands](#minishift-access-and-commands)
1. [Destroy the Environment](#destroy-the-environment)
1. [Configure the Environment](#configure-the-environment)

And we also provide some helpful [expected output](#some-expected-output)

## Prerequisites

You will need to have:

* GNU `make` - https://www.gnu.org/software/make/
* Docker - https://www.docker.com

That should be it.

## Running the Environment

You can easily build, start, and stop the MiniShift environment:

* _Up_ - Builds / starts the local MiniShift environment.

    ```
    ./scripts/build-utils.sh up
    ```
* _Down_ - Halts the local MiniShift environment:
    Example:

    ```
    ./scripts/build-utils.sh down
    ```
* _Is Running?_ - Use the following to detect if MiniShift is currently running:
    Example:

    ```
    ./scripts/build-utils.sh minishift-is-running && echo I am Running!
    ```
* _Access MiniShift Docker_ - Run a command through the Docker associated with the running
    Example:

    ```
    ./scripts/build-utils.sh minishift-docker ps -a
    ```

## MiniShift Access and Commands

You can use the same `build-utils.sh` script to access and run commands through the MiniShift:

* _Login_ - Login to the local MiniShift as `system:admin`:
    Example:

    ```
    ./scripts/build-utils.sh minishift login
    ```
    Login credentials are cached just as they would be if you issued the `oc login` command yourself.
* _Run `oc` command_ - You can access the [OpenShift CLI](https://docs.openshift.org/latest/cli_reference/get_started_cli.html) as well
    Example:

    ```
    MacBook-Pro:sab-minishift l.abruce$ ./scripts/build-utils.sh minishift oc get project
    NAME              DISPLAY NAME   STATUS
    default                          Active
    kube-public                      Active
    kube-system                      Active
    myproject         My Project     Active
    openshift                        Active
    openshift-infra                  Active
    ```
* _Check MiniShift Availability_ - Is your MiniShift currently available for use?
    Example:

    ```
    ./scripts/build-utils.sh minishift is-avail && echo MiniShift Available
    ```
* _Check if MiniShift is Running_ - Duplicate functionality to the `minishift-is-running` command above, but it's here as well:
    Example:

    ```
    ./scripts/build-utils.sh minishift is-running && echo MiniShift Running
    ```
* _Run generic MiniShift command_ - You can run any additional command you want through `minishift`; simply use our `./scripts/env-wrapper.sh` helper:
    Example:

    ```
    MacBook-Pro:sab-minishift l.abruce$ ./scripts/env-wrapper.sh minishift status
    Stopped
    ```

## Destroy the Environment

Are you all done with MiniShift? No worries, use our handy `./scripts/make-wrapper.sh distclean` command to tear everything down:

Example:
```
MacBook-Pro:sab-minishift l.abruce$ ./scripts/make-wrapper.sh distclean
Stop MiniShift...
Clean MiniShift...
Removed the cache at: /Users/l.abruce/.minishift/cache
Deleting the Minishift VM...
Minishift VM deleted.
Clean environment...
```

All vestiges of MiniShift are now gone.

## Configure the Environment

Want to customize your local MiniShift runtime environment? Take a look at the file `./scripts/env-wrapper.sh`. It provides a list of all the environment variables you can set.

Keep in mind you can create the file `$HOME/.sab-projects/sab-minishift` and populate it with any environment variables (or other commands you want). This file is automatically [sourced](http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x237.html) before running any other command when you use any of the following scripts:

* `./scripts/env-wrapper.sh` - Configures the environment for other commands
* `./scripts/build-utils.sh` - Used to execute command commands; automatically sources `./scripts/env-wrapper.sh`
* `./scripts/make-wrapper.sh` - Used to run commands from the `Makefile` in the project; automatically sources `./scripts/env-wrapper.sh`

# Some Expected Output

Because it makes us feel important and relevant, here is what common operations look like. If your own environment reports problems, you can at least see what we were aiming at when we wrote these scripts:

## Example MiniShift `up` Output - First Run

Here's a full output from our local MacBook Pro:

```
MacBook-Pro:sab-minishift l.abruce$ ./scripts/build-utils.sh up
***Build project...
Start MiniShift...
-- Checking if xhyve driver is installed ...
   Driver is available at /usr/local/bin/docker-machine-driver-xhyve
   Checking for setuid bit ... OK
-- Starting local OpenShift cluster using 'xhyve' hypervisor ...
-- Minishift VM will be configured with ...
   Memory:    2 GB
   vCPUs :    2
   Disk size: 20 GB

   Downloading ISO 'https://github.com/minishift/minishift-b2d-iso/releases/download/v1.1.0/minishift-b2d.iso'
 40.00 MiB / 40.00 MiB [=======================================================================================================================================] 100.00% 0s
-- Starting Minishift VM ... OK
-- Checking for IP address ... OK
-- Checking if external host is reachable from the Minishift VM ...
   Pinging 8.8.8.8 ... OK
-- Checking HTTP connectivity from the VM ...
   Retrieving http://minishift.io/index.html ... OK
-- Checking if persistent storage volume is mounted ... OK
-- Checking available disk space ... 0% OK
-- Downloading OpenShift binary 'oc' version 'v3.6.0'
 33.74 MiB / 33.74 MiB [=======================================================================================================================================] 100.00% 0s
-- OpenShift cluster will be configured with ...
   Version: v3.6.0
-- Checking `oc` support for startup flags ...
   host-config-dir ... OK
   host-data-dir ... OK
   host-pv-dir ... OK
   host-volumes-dir ... OK
   routing-suffix ... OK
Starting OpenShift using openshift/origin:v3.6.0 ...
Pulling image openshift/origin:v3.6.0
Pulled 1/4 layers, 26% complete
Pulled 2/4 layers, 74% complete
Pulled 3/4 layers, 82% complete
Pulled 4/4 layers, 100% complete
Extracting
Image pull complete
OpenShift server started.

The server is accessible via web console at:
    https://192.168.64.2:8443

You are logged in as:
    User:     developer
    Password: <any value>

To login as administrator:
    oc login -u system:admin

OK
Init MiniShift...
MiniShift: Initialize...
```

The steps we use are:

1. Install MiniShift
1. Verify connectivity to Minishift VM
1. Login as `system:admin`

## Example MiniShift `up` Output - Restart

If local MiniShift is already pulled down but is currently stopped, then running the `up` command simply restarts it.

```
MacBook-Pro:sab-minishift l.abruce$ ./scripts/build-utils.sh up
***Build project...
Start MiniShift...
-- Checking if xhyve driver is installed ...
   Driver is available at /usr/local/bin/docker-machine-driver-xhyve
   Checking for setuid bit ... OK
-- Starting local OpenShift cluster using 'xhyve' hypervisor ...
-- Starting Minishift VM ... OK
-- Checking for IP address ... OK
-- Checking if external host is reachable from the Minishift VM ...
   Pinging 8.8.8.8 ... OK
-- Checking HTTP connectivity from the VM ...
   Retrieving http://minishift.io/index.html ... OK
-- Checking if persistent storage volume is mounted ... OK
-- Checking available disk space ... 11% OK
-- OpenShift cluster will be configured with ...
   Version: v3.6.0
-- Checking `oc` support for startup flags ...
   host-volumes-dir ... OK
   routing-suffix ... OK
   host-config-dir ... OK
   host-data-dir ... OK
   host-pv-dir ... OK
Starting OpenShift using openshift/origin:v3.6.0 ...
OpenShift server started.

The server is accessible via web console at:
    https://192.168.64.2:8443

OK
Init MiniShift...
MiniShift: Initialize...
```

