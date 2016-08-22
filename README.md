title: Lab ? - Docker
---

# Lab ? - Docker


### Pedagogical objectives

* Build your own Docker images

* Understand core concepts for scaling of an application in production

This lab builds on a previous lab on load balancing.

In this lab you will perform a number of tasks and document your progress in a
lab report. Each task specifies one or more deliverables to be produced.
Collect all the deliverables in your lab report. Give the lab report a structure
that mimics the structure of this document.

We expect you to have in your repository (you will get the instructions later
for that) a folder called `report` and a folder called `logs`. Ideally, your
report should be in Markdown format directly in the repository.

The lab will consist of 6 tasks and one initial task (the initial task should
should be quick if you already completed the lab on load balancing):

0. [Install the tools](#task-0-install-the-tools)
1. [Add a process supervisor to your images](#task-1-add-a-process-manager-to-your-images)
2. [Add a cluster membership management tool](#task-2-add-a-cluster-membership-management-tool)
3. [Play with handler scripts](#task-3-play-with-handler-scripts)
4. [Play with a template engine](#task-4-play-with-a-template-engine)
5. [Generate the HAProxy config based on Serf events](#task-5-generate-the-haproxy-config-based-on-serf-events)
6. [Make everything working like a charm](#task-6-make-everything-working-like-a-charm)

**Remarks**:

- Use the Task numbers and question numbers in reference in your report.

- The version of HAProxy used in this lab is `1.5`. When reading the doc, take care to read the doc corresponding to this version. Here is the link: <http://cbonte.github.io/haproxy-dconv/configuration-1.5.html>

  **Warning**: There is an exception for that later in the lab. The
               documentation for a part of HAProxy (the command line help) is
               not available in 1.5. Therefore, we use the doc for 1.6 which is
               not different for our usage.

- You must give the URL of the repository that you forked off this lab.

- You must create one branch per task (from task 1, no branch for task 0). You
  can take a look on the small [Git reference guide](git quick reference.md).

- It's really important to make each task in a separate branch. In doubt,
  ask us. Non-respect of this point will be penalized.

  There is a summary of the commands you probably need to create a branch and
  work on it (replace `<taskNumber>` by the corresponding number):

  ```bash
  # Create and checkout the branch
  git checkout -b task-<taskNumber>

  # Keep track of your branch on GitHub
  git push -u origin task-<taskNumber>
  ```

  And the commands to track your changes, commit them and push to the GitHub
  remote repo (replace `<your commit message>` by your **relevant** commit messge).

  ```bash
  # Add all the untracked files
  git add .

  # Commit your files
  git commit -m "<your commit message>"

  # Push your work on GitHub
  git push
  ```

  You will need to repeat quite often those commands to create and manage a
  branch per task.

- The images and web application are a bit different from the lab on load
  balancing. The web app does no longer require a tag. An environment variable
  is defined in the Docker files to specify a role for each image. We will see
  later how use that.

- We expect, at least, to see in your report:

  - An introduction describing briefly the lab

  - A chapter whit the answer of the first questions

  - Six chapters, one for each task

  - A table of content

  - A chapter named "Difficulties" where you describe the problems and
    solutions you have encountered

  - A conclusion

**DISCLAIMER**: In this lab, we will go through one possible approach to manage a scalable infrastructure where we can add and remove nodes without having to rebuild the HAProxy image. This is not the only way to achieve this goal. If you do some research, you will find a lot of tools and services to achieve the same kind of behavior.

In the previous lab, we have built an architecture with a load balancer and two
web applications. The architecture of our distributed web application is shown
in the following diagram:

![Architecture](assets/img/initial-architecture.png)

The two web app containers stand for two web servers. They run a
NodeJS sample application that implements a simple REST API. Each
container exposes TCP port 3000 to receive HTTP requests.

The HAProxy load balancer is listening on TCP port 80 to receive HTTP
requests from users. These requests will be forwarded to and
load-balanced between the web app containers. Additionally it exposes
TCP ports 1936 and 9999 which we will cover later.

For more details about the web application, take a look to the [previous lab](https://github.com/SoftEng-HEIGVD/Teaching-HEIGVD-AIT-2015-Labo-02)

Based on the previous lab, answer the following questions. The questions are numbered
from `M1` to `Mn` to refer to them later in the lab. Please, in your report, give
the reference of the question when you answer them.

1. <a name="M1"></a>**[M1]** What are the main problems of the current solution for a production
  environment? Do you think we can use this solution for a production environment?

2. <a name="M2"></a>**[M2]** Describe what you need to do to add new `webapp` container to the
  infrastructure. Give the exact steps of what you have to do without modifiying
  the way the things are done. Hint: You probably have to modify some
  configuration and script files in a Docker images.

3. <a name="M3"></a>**[M3]** Based on your previous answers, you have detected some issues on the
  current solution. Then, can you propose your approach in high level details.

4. <a name="M4"></a>**[M4]** You probably noticed that we have the list of web application nodes
  hardcoded. How can we manage the web app nodes in a more dynamic fashion?

5. <a name="M5"></a>**[M5]** In traditional infrastructures with physical or virtual machines, we
  have a lot of side processes to manage a machine properly.

  For example, it is common to collect in one centralized place all the logs
  from several machines. Therefore, for that, we need something on each machine
  that will send to centralized place all the collected logs. We can also think
  that a tool will gather the logs of each machine. That's a push vs. pull
  problem. It's quite common to see a push mechanism for this kind of task.

  Do you think our current solution is able to accomplish that? If no, what is
  missing / required to reach the goal? If yes, how do proceed to collect the
  logs?

6. <a name="M6"></a>**[M6]** In our current solution, we have a fake approach
  of real dynamic configuration management. If we take a closer look to the
  `run.sh` script, we will set two calls to `sed` which in fact will replace
  two lines in the `haproxy.cfg` configuration file just before we start
  `haproxy` when the `ha` container start. You clearly see that the
  configuration file has two lines and the script will replace these two
  lines.

  What happens if we want more nodes? Do you think it is really dynamic? It's
  only a far far approach of a dynamic configuration. Can you propose a
  solution to solve this?

## Task 0: Install the tools

> This task will ensure that your setup is ready to run Vagrant VM with the
  previous lab Docker containers. The Docker images are a little bit different
  from the previous lab and we will work with these images during this lab.

You should have done this already in the lab of HAProxy. But if not, here are the installation instructions.

Install on your local machine Vagrant to create a virtual environment. We provide scripts for installing and running Docker inside this virtual environment:

* [Vagrant](https://www.vagrantup.com/)

Fork the following repository and then clone the fork to your machine:
<https://github.com/SoftEng-HEIGVD/Teaching-HEIGVD-AIT-2015-Labo-Docker>

To fork the repo, just click on the `Fork` button in the GitHub interface.

Once you have installed everything, start the Vagrant VM from the
project folder with the following command:

```bash
vagrant up
```

This will download an Ubuntu Linux image and initialize a Vagrant
virtual machine with it. Vagrant then runs a provisioning script
inside the VM that installs Docker and creates three Docker
containers. One contains HAProxy, the other two contain each a sample
web application.

The containers with the web application stand for two web servers that
are load-balanced by HAProxy.

The provisioning of the VM and the containers will take several
minutes. You should see output similar to the following:

```
vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'phusion/ubuntu-14.04-amd64'...
==> default: Matching MAC address for NAT networking...
==> default: Checking if box 'phusion/ubuntu-14.04-amd64' is up to date...
[...]
==> default: Removing intermediate container 4a23f3ea2a27
==> default: Successfully built 69388325f98a
==> default: ************************  run webapps  ************************
==> default: 3fb984306e36090f18e9da5b86c32d2360ad7768a0ab11dff7f9b588c2869e4a
==> default: c845c95bfb48d67625d67367a1a12226a6d35269d26ec452c90b0fd095a29d28
==> default: ************************  run haproxy  ************************
==> default: 5882839613b57e8b97737787a33678116237a80e0643cdd13fb34ac5f9e7d22b
```

There will be occasional error messages from `dpkg-preconfigure`,
`debconf` or `invoke-rc.d`. You can safely ignore them.

When deployment is finished you can log into the VM like so:

```bash
vagrant ssh
```

Once inside the VM you can list the running containers like so:

```bash
docker ps
```

You should see output similar to the following:

```
CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS                                                                NAMES
2b277f0fe8da        softengheigvd/ha       "./run.sh"          21 seconds ago      Up 20 seconds       0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
0c7d8ff6562f        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s2
d9a4aa8da49d        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s1
```

You can now navigate to the address of the load balancer <http://192.168.42.42>
in your favorite browser. The load balancer forwards your HTTP request to one
of the web app containers.

**Deliverables**:

1. Take a screenshot of the stats page of HAProxy at <http://192.168.42.42:1936>. You should see your backend nodes.

2. Give your repository URL as we can navigate your branches.

## Task 1: Add a process supervisor to your images

> In this task, we will learn to install a process supervisor that will help us
  to solve the issue presented in the question [M5](#M5). Installing a process
  supervisor let us the possibility to run multiple processes at the same time
  in a Docker environment.

A central piece of the Docker design is the principle (which for some people is a big limitation):

  > One process per container

This means that the designers of Docker assumed that in the normal case there is only a single process running inside a container. But ???

Docker is designed around this principle and as a consequence a container is running only if there is a foreground process running. When the foreground process stops, the container stops as well.

When you normally run server software like Nginx or Apache, which are designed to be run as daemons, you run a command to start them. The command is a foreground process. What happens usually is that this process then forks a background process (the daemon) and exits. Thus when you run the command in a container the process starts and right after stops and your container stops, too.

To avoid this behavior, you need to start your foreground process with an option to avoid the process to fork a daemon, but continue running in foreground. In fact, HAProxy starts by default in this "no daemon" mode.

So, the question is now, how can we run multiple processes inside one container? The answer involves using an _init system_. An init system is usually part of an operating system where it manages deamons and coordinates the boot process. There are many different init systems, like _init.d_, _systemd_ and _Upstart_. Sometimes they are also called _process supervisors_.

In this lab, we will use a small init system called `S6` <http://skarnet.org/software/s6/>.
And more specifically, we will use the `s6-overlay` scripts <https://github.com/just-containers/s6-overlay> which
simplify the use of `S6` in our containers. For more details about the
features, see <https://github.com/just-containers/s6-overlay#features>

Is this in line with the Docker philosophy? You have a good explanation of the `s6-overlay` maintainers' viewpoint here: <https://github.com/just-containers/s6-overlay#the-docker-way>

The use of a process supervisor will give us the possibility to run one or more processes at
a time in a Docker container. That's just what we need.

So to add it to your images, you will find `TODO: [S6] Install` placeholders in
the Docker images of [HAProxy](ha/Dockerfile#L11) and the [web application](webapp/Dockerfile#L16)

Replace the `TODO: [S6] Install` with the following Docker instruction:

```
# Download and install S6 overlay
RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz
```

Take the opportunity to change the `MAINTAINER` of the image by your name and email.
Replace in both Docker files the `TODO: [GEN] Replace with your name and email`.

To build your images, run the following commands inside your Vagrant VM instance:

```bash
# Build the haproxy image
cd /vagrant/ha
docker build -t softengheigvd/ha .

# Build the webapp image
cd /vagrant/webapp
docker build -t softengheigvd/webapp .
```

or use the script which do the same for you:

```bash
/vagrant/build-images.sh
```

**References**:

  - [RUN](https://docs.docker.com/engine/reference/builder/#/run)
  - [docker build](https://docs.docker.com/engine/reference/commandline/build/)

**Remarks**:

  - If you run your containers right now, you will notice that there is no
    difference between now and the previous state of our images. It's normal as
    we do not have configured anything for `S6` and we do not start it in
    the container.

To start the containers, first you need to stop the current containers and remove
them. You can do that with the following commands:

```bash
# Stop and force to remove the containers
docker rm -f s1 s2 ha

# Start the containers
docker run -d --name s1 softengheigvd/webapp
docker run -d --name s2 softengheigvd/webapp
docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --link s1 --link s2 --name ha softengheigvd/ha
```

or you can use the script to start two base containers:

```bash
/vagrant/start-containers.sh
```

You can check the state of your containers as we already did it in previous task with `docker ps` which should produce an output similar to the following:

```
CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS                                                                NAMES
2b277f0fe8da        softengheigvd/ha       "./run.sh"          21 seconds ago      Up 20 seconds       0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
0c7d8ff6562f        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s2
d9a4aa8da49d        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s1
```

**Remarks**:

  - Later in this lab, the two scripts `start-containers.sh` and `build-images.sh`
    will be less relevant. During this lab, will build and run extensively the `ha`
    proxy image. Get familiar with the docker `build` and `run` commands.

**References**:

  - [docker ps](https://docs.docker.com/engine/reference/commandline/ps/)
  - [docker run](https://docs.docker.com/engine/reference/commandline/run/)
  - [docker rm](https://docs.docker.com/engine/reference/commandline/rm/)

We need to configure `S6` as our main process and then replace the current one. For that
we will update our Docker images [HAProxy](ha/Dockerfile#L47) and the [web application](webapp/Dockerfile#L38) and
replace the: `TODO: [S6] Replace the following instruction` by the following Docker instruction:

```
# This will start S6 as our main process in our container
ENTRYPOINT ["/init"]
```

**References**:

  - [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#/entrypoint)

You can build and run the updated images (use the commands already provided earlier).
As you can observe if you try to go to http://192.168.42.42, there is nothing live.

It's the expected behavior for now as we just replaced the application process by
the process supervisor one. We have a superb process supervisor up and running but no more
application.

To remedy to this situation, we will prepare the starting scripts for `S6` and copy
them at the right place. Once we do this, they will be automatically taken into account and
our applications will be available again.

Let's start by creating a folder called `service` in `ha` and `webapp` folders. You can
use the above commands (do this command in your Vagrant VM):

```bash
mkdir -p /vagrant/ha/services/ha /vagrant/webapp/services/node
```

You should have the following folders structure:

```
|-- Root directory
  |-- ha
    |-- config
    |-- scripts
    |-- services
      |-- ha
    |-- Dockerfile
  |-- webapp
    |-- app
    |-- services
      |-- node
    |-- .dockerignore
    |-- Dockerfile
    |-- run.sh
```

We need to copy the `run.sh` scripts as `run` files in the service directories.
You can achieve that by the following commands (do these commands in your Vagrant VM):

```bash
cp /vagrant/ha/scripts/run.sh /vagrant/ha/services/ha/run && chmod +x /vagrant/ha/services/ha/run
cp /vagrant/webapp/scripts/run.sh /vagrant/webapp/services/node/run && chmod +x /vagrant/webapp/services/node/run
```

Once copied, replace the hashbang instruction in both files. Replace the first line of the `run` script

```bash
#!/bin/sh
```
by:

```bash
#!/usr/bin/with-contenv bash
```

This will instruct `S6` to give the environment variables from the container to the run script.

The start scripts are ready but now we must copy them to the right place in the Docker image. In both
`ha` and `webapp` Docker files, you need to add a `COPY` instruction to setup the service correctly.

In `ha` Docker file, you need to replace: `TODO: [S6] Replace the two following instructions` by

```
# Copy the S6 service and make the run script executable
COPY services/ha /etc/services.d/ha
RUN chmod +x /etc/services.d/ha/run
```

Do the same in the `webapp`Docker file with the following replacement: `TODO: [S6] Replace the two following instructions` by

```
# Copy the S6 service and make the run script executable
COPY services/node /etc/services.d/node
RUN chmod +x /etc/services.d/node/run
```  

**References**:

  - [COPY](https://docs.docker.com/engine/reference/builder/#/copy)
  - [RUN](https://docs.docker.com/engine/reference/builder/#/run)

**Remarks**:

  - We can discuss if is is really necessary to do `RUN chmod +x ...` in the
    image creation as we already created the `run` files with `+x` rights. Doing
    so make sure that we will never have issue with copy/paste of the file or
    transferring between unix world and windows world.

Build again your images and run them. If everything is working fine, you should be able
to open http://192.168.42.42 and see the same content as the previous task.

**Deliverables**:

1. Take a screenshot of the stats page of HAProxy at <http://192.168.42.42:1936>. You
  should see your backend nodes. It should be probably really similar than the screenshot
  of previous task

2. Give the name of the branch you do your current task

3. Describe your difficulties for this task and your understanding of
  what is happening during this task. Explain in your own words why are we
  installing a process supervisor. Do not hesitate to do more researches and to
  find more articles on that topic to illustrate the problem.

## Task 2: Add a cluster membership management tool

> Installing a cluster membership management tool will help us to solve the
  problem we detected in [M4](#M4). In fact, we will start to use what we put
  in place with the [M5](#M5) resolution. We will build two images with our
  process supervisor running a Serf agent.

In this task, we will focus on how to make our infrastructure more flexible. To
achieve this goal, we will use a tool that allows each node to know about the state of other nodes.

We will use `Serf` for this. You can read more about this tool at <https://www.serf.io/>.

The idea is that each container will have a _serf agent_ running on it. When a node appears or disappears, we will be able to react accordingly. `Serf` propagates events in its cluster and then each node can trigger scripts depending on which event was fired.

So in summary, in our infrastructure, we want the following:

1. Start our load balancer (HAProxy) and let it stay alive forever (or at least for the longest uptime as possible).

2. Start one or more backend nodes at any time after the load balancer has been started.

3. Make sure the load balancer knows about the nodes that appear and the nodes that disappear. For this,
  it means we want to react and reconfigure the load balancer accordingly to the topology state.

On paper, the things seems quite clear and easy but to achieve everything, there remain a few
steps to be done before we are ready. So we will start by installing `Serf` and see how it is working with simple events
and triggers.

To install `Serf`, we have to add the following Docker instruction in the `ha`
and `webapp` Docker files. Replace the line `TODO: [Serf] Install` in
[ha/Dockerfile](ha/Dockerfile#L13) and [webapp/Dockerfile](webapp/Dockerfile#L18)
with the following instruction:

```
# Install serf (for decentralized cluster membership: https://www.serf.io/)
RUN mkdir /opt/bin \
    && curl -sSLo /tmp/serf.gz https://releases.hashicorp.com/serf/0.7.0/serf_0.7.0_linux_amd64.zip \
    && gunzip -c /tmp/serf.gz > /opt/bin/serf \
    && chmod 755 /opt/bin/serf \
    && rm -f /tmp/serf.gz
```

You can build your images as we did in the previous task. As expected, nothing new
is happening when we run our updated images. `Serf` will not start before we add
the proper service into `S6`. The next steps will allow us to have the following
containers:

```
HAProxy container
  S6 process
    -> HAProxy process
    -> Serf process

WebApp containers
  S6 process
    -> NodeJS process
    -> Serf process
```

Each container will run a `S6` main process with, at least, two processes that are
our application processes and `Serf` processes.

To start `Serf`, we need to create the proper service for `S6`. Let's do that with
the creation of the service folder in `ha/services` and `webapp/services`. Use the
following command to do that (run this command in your Vagrant VM).

```bash
mkdir /vagrant/ha/services/serf /vagrant/webapp/services/serf
```

You should have the following folders structure:

```
|-- Root directory
  |-- ha
    |-- config
    |-- scripts
    |-- services
      |-- ha
      |-- serf
    |-- Dockerfile
  |-- webapp
    |-- app
    |-- services
      |-- node
      |-- serf
    |-- .dockerignore
    |-- Dockerfile
    |-- run.sh
```

In each directory, create an executable file called `run`. You can achieve that
by the following commands:

```bash
touch /vagrant/ha/services/serf/run && chmod +x /vagrant/ha/services/serf/run
touch /vagrant/webapp/services/serf/run && chmod +x /vagrant/webapp/services/serf/run
```

In the `ha/services/serf/run` file, add the following script. This will start and
enable the capabilities of `Serf` on the load balancer. Do not pay attention of the
tricky part of the script about the process management. You can read the comments
and ask us fore more info if you want.

The principal part between `SERF START` and `SERF END` is the command we prepare
to run the serf agent.

```bash
#!/usr/bin/with-contenv bash

# ##############################################################################
# WARNING
# ##############################################################################
# S6 expects to manage that reacts to SIGTERM signal to be stopped. Serf agent
# does not support SIGTERM signal to be stopped properly.
#
# Therefore, we need a tricky approach to remedy the situation. We need to
# "simulate" the SIGTERM and to quit Serf correctly.
#
# Basically, there are the steps we need:
# 1. Keep track of the process id (PID) of Serf Agent
# 2. Catch the SIGTERM from S6 and transform it to another mechanism to Serf
# 3. Make sure this shell script will never end before S6 stop it but when
#    SIGTERM is sent, we need to stop everything.

# Get the current process ID to avoid killing an unwanted process
pid=$$

# Define a function to kill the Serf process as Serf does not accept SIGTERM. In
# place, we will send a SIGINT signal to the process to stop it correctly.
sigterm() {
  kill -INT $pid
}

# Trap the SIGTERM and in place run the function that will kill the process
trap sigterm SIGTERM

# ##############################################################################
# SERF START
# ##############################################################################

# We build the Serf command to run the agent
COMMAND="/opt/bin/serf agent"
COMMAND="$COMMAND --join ha"
COMMAND="$COMMAND --replay"
COMMAND="$COMMAND --event-handler member-join=/serf-handlers/member-join.sh"
COMMAND="$COMMAND --event-handler member-leave,member-failed=/serf-handlers/member-leave.sh"
COMMAND="$COMMAND --tag role=$ROLE"

# ##############################################################################
# SERF END
# ##############################################################################

# Log the command
echo "$COMMAND"

# Execute the command in the background
exec $COMMAND &

# Retrieve the process ID of the command run in background. Doing that, we will
# be able to send the SIGINT signal through the sigterm function we defined
# to replace the SIGTERM.
pid=$!

# Wait forever to simulate a foreground process for S6. This will act as our
# blocking process that S6 is expecting.
wait
```

Let's take the time to analyze the `Serf` agent command. We launch the `Serf` agent
with the command:

```bash
serf agent
```

Next, we append to the command the way to join a specific `Serf` cluster where the
address of the cluster is `ha`. In fact, our `ha` node will act as a sort of master
node but as we are in a decentralized architecture, it can be any of the nodes with
a `Serf` agent.

For example, if we start `ha` first, then `s2` and finally `s1`, we can imagine
that `ha` will connect to itself as it is the first one. Then, `s2` will
reference to `ha` to be in the same cluster and finally `s1` can reference `s2`.
Therefore, `s1` will join the same cluster than `s2` and `ha` but through `s2`.

For simplicity, all our nodes will register to the same cluster trough the `ha`
node.

```bash
--join ha
```

**Remarks**:

  - Once the cluster is created in `Serf` agent, the first node which created
    the `Serf` cluster can leave the cluster. In fact, leaving the cluster will
    not stop it as long as the `Serf` agent is running.

    Anyway, in our current solution, there is kind of missconception around the
    way we create the `Serf` cluster. In the deliverables, describe which
    problem exists with the current solution based on the previous explanations and
    remarks. Propose a solution to solve the issue.

To make sure that `ha` load balancer can leave and enter the cluster again, we add
the `--replay` option. This will allow to replay the past events and then react to
these events. In fact, due to the problem you have to guess, this will probably not
be really useful.

```bash
--replay
```

Then we append the event handlers to react to some events.

```bash
--event-handler member-join=/serf-handlers/member-join.sh
--event-handler member-leave,member-failed=/serf-handlers/member-leave.sh
```

At the moment the `member-join` and `member-leave` scripts are missing. We will add
them in a moment. These two scripts will manage the load balancer configuration.

And finally, we set a tag `role=<rolename>` to our load balancer. The `$ROLE` is
the environment variable that we have in the Docker files. With the role, we will
be able to differentiate between the `balancer` and the `backend` nodes.

```bash
--tag role=$ROLE
```

In fact, each node that will join or leave the `Serf` cluster will trigger a `join`,
respectively `leave` events. It means that the handler scripts on the `ha` node
will be called for all the nodes, including itself. We want to avoid reconfiguring
`ha` proxy when itself `join`s or `leave`s the `Serf` cluster.

**References**:

  - [Serf agent](https://www.serf.io/docs/agent/basics.html)
  - [Event handlers](https://www.serf.io/docs/agent/event-handlers.html)
  - [Serf agent configuration](https://www.serf.io/docs/agent/options.html)
  - [Join -replay](https://www.serf.io/docs/commands/join.html#_replay)

Let's prepare the same kind of configuration. Copy the `run` file you just created
in `webapp/services/serf` and replace the content between `SERF START` and `SERF END`
by the following one:

```bash
# We build the Serf command to run the agent
COMMAND="/opt/bin/serf agent"
COMMAND="$COMMAND --join serf-cluster"
COMMAND="$COMMAND --tag role=$ROLE"
```

This time, we do not need to have event handlers for the backend nodes. The
backend nodes will just appear and disappear at some point in the time and
nothing else. The `$ROLE` is also replaced by the `-e "ROLE=backend"` from
the Docker `run` command.

Again, we need to update our Docker images to add the `Serf` service to `S6`.

In both Docker image files, in the [ha](ha) and [webapp](webapp) folders,
replace `TODO: [Serf] Add Serf S6 setup` with the instruction to copy the
Serf agent run script and to make it executable.

And finally, you can expose the `Serf` ports through your Docker image files. Replace
the `TODO: [Serf] Expose ports` by the following content:

```
# Expose the ports for Serf
EXPOSE 7946 7373
```

**References**:

  - [EXPOSE](https://docs.docker.com/engine/reference/builder/#/expose)

It's time to build the images and to run the containers. You can use the provided scripts
run the command manually. At this stage, you should have your application running as the
`Serf` agents. To ensure that, you can access http://192.168.42.42 to see if you backends
are responding and you can check the Docker logs to see what is happening. Simply run:

```bash
docker logs <container name>
```

where container name is one of:

  - ha
  - s1
  - s2

You will notice the following in the logs (or something similar).

```
==> Joining cluster...(replay: false)
==> lookup ha on 10.0.2.3:53: no such host
```

This means that our nodes are not joining the `Serf` cluster and more important
cannot resolve the DNS names of the nodes.

You can do a simple experiment to see you yourself there is no name resolution.
Connect to a container and run a ping command.

```bash
# From Vagrant VM
docker exec -ti ha /bin/bash

# From ha container
ping s1
```

The problem is due to the latest versions of Docker where the networking have
been totally reworked.

In latest Docker versions, the network part was totally rewritten and changed
a lot. In fact, the default networks we have used until now seen their behavior
changed.

Previously, these default networks embedded automatically the DNS resolution for
the network where the containers are attached but this is not no more the case.

To solve this issue, we need to go a little more deeper in Docker commands and we
need to create our own Docker network. For that, we will use the following command.
Creating a bridged network with Docker that is not the default one, automatically
embedded a DNS resolution.

```bash
docker network create --driver bridge heig
```

Stop all your containers:

```bash
docker rm -f ha s1 s2
```

If you want to know more about Docker networking, take the time to read the different
pages in the references. Docker team provide a good overview and lot of details about
this important topic.

From now, to start our containers, we need to add the following argument to the `docker run` command

```bash
--network heig
```

So to start the `ha` container the command become:

```bash
docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --link s1 --link s2 --name ha softengheigvd/ha
```

And for the backend nodes:

```bash
docker run -d --network heig --name s1 softengheigvd/webapp
```

**Remarks**:

  - When we reach this point, we have a problem. If we start the HAProxy first,
    it will not start as the two `s1` and `s2` containers are not started and we
    try to link them through the Docker `run` command.

    You can try and get the logs. You will see error logs where `s1` and `s2`

    If we start `s1` and `s2` nodes before `ha`, we will have an error from `Serf`.
    They try to connect the `Serf` cluster via `ha` container which is not running.

    So the reverse proxy is not working but what we can do at least is to start
    the containers beginning by `ha` and then backend nodes. It will make the `Serf`
    part working and that's what we are working on at the moment and in the next
    task.

**References**:

  - [docker network create](https://docs.docker.com/engine/reference/commandline/network_create/)
  - [Understand Docker networking](https://docs.docker.com/engine/userguide/networking/)
  - [Embedded DNS server in user-defined networks](https://docs.docker.com/engine/userguide/networking/configure-dns/)
  - [docker run](https://docs.docker.com/engine/reference/commandline/run/)

**Cleanup**:

  - As we have changed the way we start our reverse proxy and web application, we
    can remove the original `run.sh` scripts. You can use the following commands to
    clean these two files (and folder in case of web application).

    ```bash
    rm /vagrant/ha/scripts/run.sh
    rm -r /vagrant/webapp/scripts
    ```

**Deliverables**:

1. Provides the docker logs output for each of the containers:  `ha`, `s1` and `s2`. You need to
  create a folder logs in your repository to track the files aside the report. Create a folder
  per task for the logs and name it from the task number. No need to create folder when no logs.

  Example:

  ```
  |-- root folder
    |-- logs
      |-- task 1
      |-- task 3
      |-- ...
  ```

2. Give the name of the branch for the current task

3. Give the answer to the question about the existing problem with the current solution

4. Give an explanation on how `Serf` is working. Read the official website to get more
  details about the `GOSSIP` protocol used in `Serf`. Try to find other solutions
  that can be used to solve such situation where we need some auto-discovery mechanism.

## Task 3: Play with handler scripts

> Serf is really simple to use as it let the user to write their own shell
  scripts to react to the cluster events. During this task, we will start
  gently to write the mandatory handler scripts we need to build our solution.
  We will start by just logging members that join the cluster and the members
  that leave the cluster. We are preparing to solve concretely the issue
  discovered in [M4](#M4).

We reached a state where we have nearly all the pieces in place to make the infrastructure
really dynamic. At the moment, we are missing the scripts that will manage the events
of `Serf` and then react to member `leave` or member `join`.

We will start by creating the scripts in [ha/scripts](ha/scripts). So create two files in
this directory and set them as executable. You can use these commands:

```bash
touch /vagrant/ha/scripts/member-join.sh && chmod +x /vagrant/ha/scripts/member-join.sh
touch /vagrant/ha/scripts/member-leave.sh && chmod +x /vagrant/ha/scripts/member-leave.sh
```

In the `member-join.sh` script, put the following content:

```bash
#!/usr/bin/env bash

echo "Member join script triggered" >> /var/log/serf.log

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  echo "Member join event received from: $HOSTNAME with role $HOSTROLE" >> /var/log/serf.log
done
```

Do the same for the `member-leave.sh` with the following content:

```bash
#!/usr/bin/env bash

echo "Member leave/join script triggered" >> /var/log/serf.log

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  echo "Member $SERF_EVENT event received from: $HOSTNAME with role $HOSTROLE" >> /var/log/serf.log
done
```

We have to update our Docker file for `ha` node. Replace the
`TODO: [Serf] Copy events handler scripts` with appropriate content to:

  1. Make sure there is directory `/serf-handlers`
  2. The `member-join` and `member-leave` scripts are placed in this folder
  3. Both of the scripts are executable

Stop all your containers to have a fresh state:

```bash
docker rm -f ha s1 s2
```

Now, build your `ha` image:

```bash
# Build the haproxy image
cd /vagrant/ha
docker build -t softengheigvd/ha .
```

From there, you will be notified when you need to keep track of the logs. The logs
will be asked as a deliverable of the lab. You will notice: (**keep logs**) to remind
you to keep them for the report.

Run the `ha` container first and capture the logs with `docker logs` (**keep the logs**).

```bash
docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --name ha softengheigvd/ha
```

Now, one of the two backend containers and capture the logs (**keep the logs**). Quite quickly after
started the container, capture also the logs of `ha` node (**keep the logs**).

```bash
docker run -d --network heig --name s1 softengheigvd/webapp
docker run -d --network heig --name s2 softengheigvd/webapp
```

**Remarks**:

  - You probably noticed that we removed the `links` to container `s1` and `s2`.
    In few words, we will not rely on that mechanism for the next steps and for
    the moment, the communication between the reverse proxy and the backend
    nodes is broken.

Once started, get the logs (**keep the logs**) of the backend container.

To check there is something happening on the node `ha`, you will need to connect
to the running container to gather the custom log file that is created in the
handler scripts. For that, use the following command to connect to `ha`
container in interactive mode.

```bash
docker exec -ti ha /bin/bash
```

**References**:

  - [docker exec](https://docs.docker.com/engine/reference/commandline/exec/)

Once done, you can simply run the following command. This command is run inside
the running `ha` container. (**keep the logs**)

```bash
cat /var/log/serf.log
```

Once you have finished, you have simply to type `exit` in the container to quit
your shell session and at the same time the container. The container itself will
continue to run.

**Deliverables**:

1. Provides the docker logs output for each of the containers:  `ha`, `s1` and `s2`.
  Put your logs in the logs folder you created in the previous task.

2. Give the branch name of the current task

3. Provide the logs from `ha` container gathered directly from the `/var/log/serf.log`
  file present in the container. Put the logs in the logs directory in your repo.

## Task 4: Play with a template engine

> To manage a configuration dynamically, we have several possibility but we
  have chosen the way of templates. In this task, we will put in place a
  template engine and use it with a basic example. We will not become experts
  in template engines but it will give you a great taste of applying a technique
  usually used in different contexts (like web templates, mail templates, ...)
  to manage a configuration. We will be able to solve the issue raised in
  [M6](#M6).

There are several ways to regenerate a configuration and to fill it with real values
in a dynamic fashion. In this lab, we decided to use `NodeJS` and `Handlebars` for the
template engine.

According to Wikipedia:

  > a template engine is a software designed to combine one or more templates
    with a data model to produce one or more result documents

In our case, our template is the `HAProxy` configuration file with the template engine
language placeholders and the configuration is the resulted document after the processing
done by the template engine. And finally, our data model is the data provided by the
handlers scripts from `Serf`.

**References**:

  - [NodeJS](https://nodejs.org/en/)
  - [Handlebars](http://handlebarsjs.com/)
  - [Template Engine definition](https://en.wikipedia.org/wiki/Template_processor)

To be able to use `Handlebars` as a template engine in our `ha` container, we need
to install `NodeJS` and `Handlebars`.

To install `NodeJS`, just replace `TODO: [HB] Install NodeJS` by the following content:

```
# Install NodeJS
RUN curl -sSLo /tmp/node.tar.xz https://nodejs.org/dist/v4.4.4/node-v4.4.4-linux-x64.tar.xz \
  && tar -C /usr/local --strip-components 1 -xf /tmp/node.tar.xz \
  && rm -f /tmp/node.tar.xz
```

We also need to update the base tools installed in the image to be able to extract the `NodeJS`
archive. So we need to add `xz-utils` to the `apt-get install` present above the line
`TODO: [HB] Update to install required tool to install NodeJS`.

**Remarks**:

  - You probably noticed that we have the backend image with a `NodeJS` application.
    So the image already contains `NodeJS`. We have based our backend image on an
    existing image that provide an installation of `NodeJS`. In our `ha` image,
    we take a shortcut and do a manual installation of `NodeJS` with at least one
    bad practice.

    In the original image of `NodeJS` the download of the required files and then
    check the downloads against `GPG` signatures. We have skipped this part in
    our `ha`image but in practice, you should check everything you do to avoid
    issues like the `man in the middle` attack.

    You can take a look to the following links if you want:

      - [NodeJS official Dockerfile](https://github.com/nodejs/docker-node/blob/ae9e2d4f04a0fa82261df86fd9556a76cefc020d/6.3/wheezy/Dockerfile#L4-L26)
      - [GPG](https://en.wikipedia.org/wiki/GNU_Privacy_Guard)
      - [Man in the middle attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack)

    The other reason why we have to manually install `NodeJS` by hand is that we
    cannot inherit from two images at the same time. As in our `ha` image, we
    already come `FROM` the `haproxy` official image, then we cannot use
    the `NodeJS` at the same time.

    In fact, the `FROM` instruction from Docker can be see like Java Inheritance
    model. You can inherit only from one super class at a time. For example, we
    have the following hierarchy for our HAProxy image.

    <p style="text-align:center;">
      <a href="https://github.com/SoftEng-HEIGVD/Teaching-HEIGVD-AIT-2016-Labo-Docker/blob/master/assets/img/image-hierarchy.png">
        <img style="width:600px;" src="https://github.com/SoftEng-HEIGVD/Teaching-HEIGVD-AIT-2016-Labo-Docker/raw/master/assets/img/image-hierarchy.png" alt="HAProxy Image Hierarchy">
      </a>
    </p>

    There is the `FROM` Docker documentation reference:

      - [FROM](https://docs.docker.com/engine/reference/builder/#/from)

It's time to install `Handlebars` and a small command line util to make it working
properly. For that, replace the `TODO: [HB] Install Handlebars and cli` by this
Docker instruction:

```
# Install the handlebars-cmd node module and its dependencies
RUN npm install -g handlebars-cmd
```

**Remarks**:

  - [NPM](http://npmjs.org/) is a package manager for `NodeJS`. Like other package
    manager, one of his tasks is to manage the dependencies of any package. That's
    the reason why we have only to install `handlebars-cmd`. This package has
    `handlebars` as its dependencies.

Now we will update the handler scripts to use `Handlebars`. For the moment, we
will just play with a simple template. So, first create a file in `ha/config` called
`haproxy.cfg.hb` with a simple template content. Use the following command for that:

```bash
echo "Container {{ name }} has joined the Serf cluster with the following IP address: {{ ip }}" >> /vagrant/ha/config/haproxy.cfg.hb
```

We need our template present in our `ha` image. We have to add the following
Docker instructions for that. Let's replace `TODO: [HB] Copy the haproxy configuration template`
in [ha/Dockerfile](ha/Dockerfile#L32) with the required stuff to:

  1. Have a directory `/config`
  2. Have the `haproxy.cfg.hb` in it

Then, update the `member-join.sh` script in [ha/scripts](ha/scripts) with the following content:

```bash
#!/usr/bin/env bash

echo "Member join script triggered" >> /var/log/serf.log

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  echo "Member join event received from: $HOSTNAME with role $HOSTROLE" >> /var/log/serf.log

  # Generate the output file based on the template with the parameters as input for placeholders
  handlebars --name $HOSTNAME --ip $HOSTIP < /config/haproxy.cfg.hb > /tmp/haproxy.cfg
done
```

<a name="ttb"></a>
Time to build our `ha` image and to run it. We will also run `s1` and `s2`. As usual, there
are the commands to build and run our image and containers:

```bash
# Remove running containers
docker rm -f ha s1 s2

# Build the haproxy image
cd /vagrant/ha
docker build -t softengheigvd/ha .

# Run the HAProxy container
docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --name ha softengheigvd/ha
```

**Remarks**:

  - Installing a new util with `apt-get` means building the whole image again as
    it is in our Docker file. This will take few minutes.

Take the time to retrieve the output file in the `ha` container. Connect to the container:

```bash
docker exec -ti ha /bin/bash
```

and get the content from the file (**keep it for deliverables, handle it as you do for the logs**)

```bash
cat /tmp/haproxy.cfg
```

**Remarks**:

  - It can be really convenient to have two or more terminal with a ssh session
    to your Vagrant VM. With multiple session you can keep your connection to
    `ha` container alive during you start your backend nodes.

    To open another ssh session to Vagrant, simply run `vagrant ssh` in the root
    directory of your repository from another terminal tab/window.

And quit the container with `exit`.

Now, do the same for `s1` and `s2` and retrieve the `haproxy.cfg` file.

```bash
# 1) Run the S1 container
docker run -d --network heig --name s1 softengheigvd/webapp

# 2) Connect to the ha container (optional if you have another ssh session)
docker exec -ti ha /bin/bash

# 3) From the container, extract the content (keep it for deliverables)
cat /tmp/haproxy.cfg

# 4) Quit the ha container (optional if you have another ssh session)
exit

# 5) Run the S2 container
docker run -d --network heig --name s2 softengheigvd/webapp

# 6) Connect to the ha container (optional if you have another ssh session)
docker exec -ti ha /bin/bash

# 7) From the container, extract the content (keep it for deliverables)
cat /tmp/haproxy.cfg

# 8) Quit the ha container
exit
```

**Deliverables**:

1. You probably noticed when we added `xz-utils`, we have to rebuild the whole image
  which took some time. What can we do to mitigate that? You can take a look on
  the Docker documentation about the [image layers](https://docs.docker.com/engine/userguide/storagedriver/imagesandcontainers/#images-and-layers).
  Tell us about the pros and cons to merge as much as possible of the command. In
  fact, argument about:

  ```
  RUN command 1
  RUN command 2
  RUN command 3
  ```

  vs.

  ```
  RUN command 1 && command 2 && command 3
  ```

  There are also some articles about techniques to reduce the image size. Try to
  find them. They are talking about `squashing` or `flattening` images.

2. Propose a different approach to architecture our images to be able to reuse
  as much as possible what we have done. Your proposition should also take care
  to avoid as much as possible the repetition between your images.

3. Give the branch for the current task

4. Give the `/tmp/haproxy.cfg` generated in the `ha` container after each steps.
  Place the output into the logs folder like you already done for the Docker logs
  in the previous tasks.

5. Based on the three output files gathered, what can you tell about the way we
  generate it? What is the problem if any?

## Task 5: Generate the HAProxy config based on Serf events

> With S6 and Serf ready in our HAProxy image. With the member join/leave
  handler scripts and the handlebars template engine. We have all the pieces
  ready to generate the HAProxy configuration dynamically. We will update
  our handler scripts to manage the list of nodes and to generate the
  HAProxy configuration each time the cluster has a member leave/join event.
  The modification in this task will let us solving the problem in [M4](#M4).

At this stage, we have:

  - Two images with `S6` process supervisor that starts `Serf agent` and an
    `Application` (HAProxy or Node app)

  - The `ha` image contains the required stuff to react to `Serf` events when a
    container join or leave the `Serf` cluster

  - A template engine in `ha` image ready to used to generate the HAProxy configuration

Now, we need to refine our `join` and `leave` scripts to generate a proper HAProxy
configuration file.

First, we will copy/paste the content of [ha/config/haproxy.cfg](ha/config/haproxy.cfg)
file into [ha/config/haproxy.cfg.hb](ha/config/haproxy.cfg.hb). You can simply
run the following command:

```bash
cp /vagrant/ha/config/haproxy.cfg /vagrant/ha/config/haproxy.cfg.hb
```

Then we will replace the content between `# HANDLEBARS START` and
`# HANDLEBARS STOP` by the following content:

```
{{#each addresses}}
server {{ host }} {{ ip }}:3000 check
{{/each}}
```

**Remarks**:

  - `each` iterates over a collection of data

  - `{{` and `}}` are the bars that will be interpreted by `Handlebars`

  - `host` and `ip` are the data contained in the JSON format of the collection
    that handlebars will receive. We will see that right after in the `member-join.sh`
    script. The JSON format will be: `{ "host": "<hostname>", "ip": "<ip address>" }`.

Our configuration template is ready. Let's update the `member-join.sh` script to
generate the correct configuration.

The mechanism in place to manage the `join` and `leave` events is the following:

  1. We check if the event comes from a backend node (the role is used)

  2. We create a file with the hostname and ip of each backend node that join the cluster

  3. We build the handlebars command to generate the new configuration from the list
    of files that represent our backend nodes

The same logic also apply when a node leave the cluster. In this case, the second step
will remove the file with the node data.

In the file [ha/scripts/member-join.sh](ha/scripts/member-join.sh)
replace the whole content by the following one. Take the time to read the comments.

```bash
#!/usr/bin/env bash

echo "Member join script triggered" >> /var/log/serf.log

BACKEND_REGISTERED=false

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  # We only register the backend nodes
  if [[ "$HOSTROLE" == "backend" ]]; then
    echo "Member join event received from: $HOSTNAME with role $HOSTROLE" >> /var/log/serf.log

    # We simply register the backend IP and hostname in a file in /nodes
    # with the hostname for the file name
    echo "$HOSTNAME $HOSTIP" > /nodes/$HOSTNAME

    # We have at least one new node registered
    BACKEND_REGISTERED=true
  fi
done

# We only update the HAProxy configuration if we have at least one new  backend node
if [[ "$BACKEND_REGISTERED" = true ]]; then
  # To build the collection of nodes
  HOSTS=""

  # We iterate over each backend node registered
  for hostfile in $(ls /nodes); do
    # We convert the content of the backend node file to a JSON format: { "host": "<hostname>", "ip": "<ip address>" }
    CURRENT_HOST=`cat /nodes/$hostfile | awk '{ print "{\"host\":\"" $1 "\",\"ip\":\"" $2 "\"}" }'`

    # We concatenate each host
    HOSTS="$HOSTS$CURRENT_HOST,"
  done

  # We process the template with handlebars. The sed command will simply remove the
  # trailing comma from the hosts list.
  handlebars --addresses "[$(echo $HOSTS | sed s/,$//)]" < /config/haproxy.cfg.hb > /usr/local/etc/haproxy/haproxy.cfg

  # TODO: [CFG] Add the command to restart HAProxy
fi
```

And here we go for the `member-leave.sh` script. The script differs only for the part where
we remove the backend nodes registered via the `member-join.sh`.

```bash
#!/usr/bin/env bash

echo "Member leave/join script triggered" >> /var/log/serf.log

BACKEND_UNREGISTERED=false

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  # We only remove the backend nodes
  if [[ "$HOSTROLE" == "backend" ]]; then
    echo "Member $SERF_EVENT event received from: $HOSTNAME with role $HOSTROLE" >> /var/log/serf.log

    # We simply remove the file that was used to track the registered node
    rm /nodes/$HOSTNAME

    # We have at least one new node that leave the cluster
    BACKEND_UNREGISTERED=true
  fi
done

# We only update the HAProxy configuration if we have at least a backend that
# left the cluster. The process to generate the HAProxy configuration is the
# same than for the member-join script.
if [[ "$BACKEND_UNREGISTERED" = true ]]; then
  # To build the collection of nodes
  HOSTS=""

  # We iterate over each backend node registered
  for hostfile in $(ls /nodes); do
    # We convert the content of the backend node file to a JSON format: { "host": "<hostname>", "ip": "<ip address>" }
    CURRENT_HOST=`cat /nodes/$hostfile | awk '{ print "{\"host\":\"" $1 "\",\"ip\":\"" $2 "\"}" }'`

    # We concatenate each host
    HOSTS="$HOSTS$CURRENT_HOST,"
  done

  # We process the template with handlebars. The sed command will simply remove the
  # trailing comma from the hosts list.
  handlebars --addresses "[$(echo $HOSTS | sed s/,$//)]" < /config/haproxy.cfg.hb > /usr/local/etc/haproxy/haproxy.cfg

  # TODO: [CFG] Add the command to restart HAProxy
fi
```

**Remarks**:

  - The way we keep track the backend nodes is pretty simple and make the assumption
    there is no concurrency issue with `Serf`. That's reasonable enough to get a
    quite simple solution.

**Cleanup**:

  - In the main configuration file that is used for bootstrap HAProxy the first time
    when there is no backend nodes, we have the list of servers that we used in the first
    task and the previous lab. We can remove the list. So find `TODO: [CFG] Remove all the servers`
    and remove the list of nodes.

  - In [ha/services/ha/run](ha/services/ha/run), we can remove the two lines
    above `TODO: [CFG] Remove the following two lines`.

We need to make sure the image has the folder `/nodes` created. In the Docker file,
replace the `TODO: [CFG] Create the nodes folder` by the correct instruction to create
the `/nodes` folder.

We are ready to build and test our `ha` image. Let's proceed the same as the [previous task](#ttb).
You should keep track the same outputs for the deliverables. Remind you that we have
moved the file `/tmp/haproxy.cfg` to `/usr/local/etc/haproxy/haproxy.cfg`
(**keep track of the config file like in previous step**).

You can also get the list of registered nodes from inside the `ha` container. Simply
list the files from the directory `/nodes`.
(**keep track of the output of the command like the logs in previous tasks**)

Now, use the Docker commands to stop `s1`.

You can connect again to the `ha` container and get the haproxy configuration
file and also the list of backend nodes. Use the previous command to reach this goal.
(**keep track of the output of the ls command and the configuration file
like the logs in previous tasks**)

**Deliverables**:

1. Give the branch for the current task

2. Give the `/usr/local/etc/haproxy/haproxy.cfg` generated in the `ha` container after each steps

3. Give the list of files from `/nodes` folder inside the `ha` container.

4. Give the configuration file after you stopped one container and the list of
  nodes present in the `/nodes` folder.

5. Propose a different approach to manage the list of backend nodes. You do
  not need to implement it. You can also propose your own tools or the ones you
  discovered online. In that case, do not forget to cite your references.

## Task 6: Make everything working like a charm

> Finally, we have all the required stuff to finish our solution. HAProxy will
  be reconfigured automatically in regard of the web app nodes leaving/joining
  the cluster. We will solve the problems you have discussed in [M1 - 3](#M1).
  Again, the solution built during this lab is one example of tools and
  techniques we can use to solve this kind of sitatuation. There are several
  other ways.

We have all the pieces ready to work and we just need to make sure the configuration
of HAProxy is up-to-date and taken into account by HAProxy.

We will try to make HAProxy reload his config with the minimal downtime. At the moment,
we will replace `TODO: [CFG] Replace this command` in [ha/services/ha/run](ha/services/ha/run)
by the following script part. As usual, take the time to read the comments.

```bash
#!/usr/bin/with-contenv bash

# ##############################################################################
# WARNING
# ##############################################################################
# S6 expects to manage that reacts to SIGTERM signal to be stopped. HAProxy
# does not gracefully stop when he receives such signals. In place, the SIGUSR1
# is used to do a graceful shutdown.
#
# Therefore, we need a tricky approach to remedy the situation. We need to
# "simulate" the SIGTERM and to quit HAProxy correctly. This trick is mainly
# based on the same we applied for Serf. We will see in few lines where is the
# difference.
#
# Basically, there are the steps we need:
# 1. Keep track of the process id (PID) of HAProxy
# 2. Catch the SIGTERM from S6 and transform it to another mechanism to HAProxy
# 3. Make sure this shell script will never end before S6 stop it but when
#    SIGTERM is sent, we need to stop everything.

# Get the current process ID to avoid killing an unwanted process
pid=$$

# Define a function to stop HAProxy process in a proper way. In
# place, we will send a SIGUSR1 signal to the process to stop it correctly.
sigterm() {
  kill -USR1 $pid
}

# Trap the SIGTERM and in place run the function that will kill the process
trap sigterm SIGTERM

# We need to keep track of the PID of HAProxy in a file for the restart process.
# We are forced to do that because the blocking process for S6 is this shell
# script. When we send to S6 a command to restart our process, we will loose
# the value of the variable pid. The pid variable will stay alive until any
# restart or stop from S6.
#
# In the case of the restart need to keep the HAProxy PID to give it back to
# HAProxy. The comments on the HAProxy command will complete this exaplanation.
if [ -f /var/run/haproxy.pid ]; then
    HANDOFFPID=`cat /var/run/haproxy.pid`
fi

# HAProxy allows to give the PID of current running processes via -sf/-st
# argument. This will allow to start new HAProxy processes and to stop the
# ones given in argument. With this approach, we can warranty a lower outage
# when we restart HAProxy. It will stay alive until new processes are ready,
# once the new processes are ready, the old ones can be stopped.
#
# The HANDOFFPID keep track of the PID of HAProxy. We retrieve it from the
# the file we written the last time we (re)started HAProxy.
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -sf $HANDOFFPID &

# Retrieve the process ID of the command run in background. Doing that, we will
# be able to send the SIGINT signal through the sigterm function we defined
# to replace the SIGTERM.
pid=$!

# And write it a file to get it on next restart
echo $pid > /var/run/haproxy.pid

# Finally, we wait as S6 launch this shell script. This will simulate
# a foreground process for S6. All that tricky stuff is required because
# we use a process supervisor in a Docker environment. The applications need
# to be adapted for such environments.
wait
```

**Remarks**:

  - In this lab, we will not do a real zero downtime (or nearly) HAProxy
    restart. You will find an article about that in the references.

**References**:

  - [Stopping HAProxy](http://cbonte.github.io/haproxy-dconv/1.6/management.html#4)
  - [Sending signal to Processes](https://bash.cyberciti.biz/guide/Sending_signal_to_Processes)
  - [Zero downtime with HAProxy article](http://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html)

We need to update our `member-join` and `member-leave` scripts to make sure HAProxy
will be restarted when its configuration is modified. For that, in both files, replace
`TODO: [CFG] Add the command to restart HAProxy` by the following command.

```bash
# Send a SIGHUP to the process. It will restart HAProxy
s6-svc -h /var/run/s6/services/ha
```

**References**:

  - [S6 svc doc](http://skarnet.org/software/s6/s6-svc.html)

It's time to build and run our images. At this stage, if you try to reach
`http://192.168.42.42`, it will not work. No surprise as we do not start any
backend node. Let's start one container and try to reach the same URL.

You can start the web application nodes. If everything works well, you could
reach your backend application through the load balancer.

And now you can start and stop the number of nodes you want to see the dynamic
reconfiguration occurring. Keep in mind that HAProxy will take few seconds
before nodes will be available. The reason is that HAProxy is not so quick to
restart inside the container and your web application is also taking time to
bootstrap. And finally, depending of the health checks of HAProxy, your web
app will not be available instantly.

Finally, we achieved our goal to build an architecture that is dynamic and react
to new nodes and nodes that are leaving.

![Final architecture](assets/img/final-architecture.png)

**Deliverables**:

1. Take a screenshots of the HAProxy stat page showing more than 2 web
  application running. Additional screenshots are welcome to see a sequence
  of experimentations like shutting down a node and starting more nodes.

2. Give your own feelings about the final solution. Propose improvements or ways
  to do the things differently. If any, provides the links of your readings for
  the improvements.

3. Present a live demo where you add and remove a backend container.

## Lab due date

Deliver your results at the latest 15 minutes before class TBD

## Windows troubleshooting

It appears that Windows users can encounter a `CRLF` vs. `LF` problem when the repos is cloned without taking care of the ending lines. Therefore, if the ending lines are `CRFL`, it will produce an error message with Docker during the Vagrant provisioning phase:

```bash
... no such file or directory
```

(Take a look to this Docker issue: https://github.com/docker/docker/issues/9066, the last post show the error message).

The error message is not really relevant and difficult to troubleshoot. It seems the problem is caused by the line endings not correctly interpreted by Linux when they are `CRLF` in place of `LF`. The problem is caused by cloning the repos on Windows with a system that will not keep the `LF` in the files.

Fortunatelly, there is a procedure to fix the `CRLF` to `LF` and then be sure Docker will recognize the `*.sh` files.

First, you need to add the file `.gitattributes` file with the following content:

```bash
* text eol=lf
```

This will ask the repos to force the ending lines to `LF` for every text files.

Then, you need to reset your repository. Be sure you do not have **modified** files.

```bash
# Erease all the files in your local repository
git rm --cached -r .

# Restore the files from your local repository and apply the correct ending lines (LF)
git reset --hard
```

Then, you are ready to go. You can provision your Vagrant VM again and start to work peacefully.

There is a link to deeper explanation and procedure about the ending lines written by GitHub: https://help.github.com/articles/dealing-with-line-endings/
