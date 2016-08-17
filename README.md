title: Lab ? - Docker
---

## Lab ? - Docker


#### Pedagogical objectives

* Reuse part of a previous lab concepts about the load balancing

* Build your own Docker images

* Understand core concepts for production scaling of an application

In this lab you will perform a number of tasks and document your
progress in a lab report. Each task specifies one or more deliverables
to be produced.  Collect all the deliverables in your lab report. Give
the lab report a structure that mimics the structure of this document.

**Remark**:

  - Use the Task numbers and question numbers in reference in your report.

  - The version of HAProxy used in this lab is `1.5`. When reading the doc, take care to read the doc corresponding to this version. Here is the link: http://cbonte.github.io/haproxy-dconv/configuration-1.5.html

  - You must give the fork URL of the repository of this lab.

  - You must create one branch per task (from task 1, no branch for task 0)

    - `Create a branch`: `git checkout -b <branch name>`. Ex: `git checkout -b task-1`

    - `Push a branch (first time)`: `git push -u origin <branch name>`. Ex: `git branch -u origin task-1`

    - `Push updates (second time and following)`: `git push`

    - `Add updates to staging`: `git add <file path>`. Ex: `git add .` (will add all modifications)

    - `Committing staged changes`: `git commit -m "<message>"`. Ex: `git commit -m "Added run script"`

    - `Checkout a branch`: `git checkout <branch name>`. Ex: `git checkout task-1`

    - `Fetching changes from remote`: `git fetch`.

    - `Applying remote changes`: `git pull`

    - Any git issue, ask us for help.

  - It's really important to make each task in a separate branch. In doubts, ask us. No respect of
    this point will be penalized.

  - The images and web application have been modified since the previous lab. The web app does
    no more require a tag. An environment variable is defined in the Docker files to specify a
    role for each image. We will see later how use that.

  - We expect, at least, in your report to see:

    - An introduction describing briefly the lab

    - 6 chapters, one for each task

    - A table of content

    - If any, difficulties chapter where you will describe the problems and
      solutions you have encountered

    - A Conclusion

**DISCLAIMER**: In this lab, we will go through a possible manner to manage a
scalable infrastructure where we can add and remove nodes without having to rebuild
the HAProxy server. This is not the only one possibility to achieve such a goal.
Doing some researches, you will find a lot of tools and services to achieve the
same kind of behavior.

### Task 0: Install the tools

This should be already done in the lab of HAProxy. But if not, here we go we the
installation requirements.

Install on your local machine Vagrant to create a virtual
environment. We provide scripts for installing and running inside this
virtual environment Docker. Install also JMeter for load testing web
applications:

* [Vagrant](https://www.vagrantup.com/)

Fork the following repository and then clone the fork to your machine:
<https://github.com/SoftEng-HEIGVD/Teaching-HEIGVD-AIT-2015-Labo-02>

To fork the repo, just click on the `Fork` button in the GitHub interface.

Once you have installed everything, start the Vagrant VM from the
project folder with the following command:

```
$ vagrant up
```

This will download an Ubuntu Linux image and initialize a Vagrant
virtual machine with it. Vagrant then runs a provisioning script
inside the VM that installs Dockerand creates three Docker
containers. One contains HAProxy, the other two contain each a sample
web application.

The containers with the web application stand for two web servers that
are load-balanced by HAProxy.

The provisioning of the VM and the containers will take several
minutes. You should see output similar to the following:

```
$ vagrant up
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

`$ vagrant ssh`

Once inside the VM you can list the running containers like so:

`$ docker ps`

You should see output similar to the following:

```
CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS                                                                NAMES
2b277f0fe8da        softengheigvd/ha       "./run.sh"          21 seconds ago      Up 20 seconds       0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
0c7d8ff6562f        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s2
d9a4aa8da49d        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s1
```

The two web app containers stand for two web servers. They run a
NodeJS sample application that implements a simple REST API. Each
container exposes TCP port 3000 to receive HTTP requests.

The HAProxy load balancer is listening on TCP port 80 to receive HTTP
requests from users. These requests will be forwarded to and
load-balanced between the web app containers. Additionally it exposes
TCP ports 1936 and 9999 which we will cover later.

The architecture of our distributed web application is shown in the
following diagram:

![Architecture](assets/img/archi.png)

You can now navigate to the address of the load balancer
<http://192.168.42.42> in your favorite browser. The load balancer
forwards your HTTP request to one of the web app containers.

Both containers run the same simple test web app. It is modeled as a
REST resource. To make this lab more "interesting" the app uses
sessions. The app is written in Node.js and uses a cookie named
`NODESESSID`.

The app returns an HTTP response with a JSON payload that is designed
to help you with testing and debugging. You should see output similar
to the following:

```
{
  "hello": "world!",
  "ip": "172.17.0.7",
  "host": "2b277f0fe8da",
  "sessionViews": 1,
  "id": "pdoSpuStaotzO4us2l_uYArG0w6S57eV"
}
```

The fields have the following meaning:

* The field `ip` contains the internal IP address of the
  container. This allows you to identify the container, as each
  receives a different IP address from Docker.

* The field `host` is the hostname of the container and in the Docker
  context this represents the container ID.

* The `tag` represents the server tag corresponding, in our case, to
  the container name (docker **--name s1**).

* The field `sessionViews` returns a counter that is a session
  variable. The counter is incremented each time the app receives a
  request.  **Hint**: Use this field to observe the session behavior
  of the load balancer.

* Finally, the field `id` is the session id. You should be able to
  find that same session id embedded in the session cookie that is
  sent to the client.

** Deliverables **

1. Take a screenshot of the stats page of HAProxy http://192.168.42.42:1936. You
  should see your backend nodes.

2. Give your repository URL as we can navigates your branches.

### Task 1: Add a process manager to your images

Actually, Docker has for some people a big limitation but it was designed as a core
feature: **One container == one process**

In summary, this means that you should not be able to run multiple processes at the
same time in a Docker container. But ???

This can be easily explained by the fact that a container is running only there
is a front process running. When run processes like Nginx or Apache which
are designed to be run as daemons by defaults without doing anything special. The
processes will start and right after they will stop and your container too.

To avoid this behavior, you need to start your front process with a flag to avoid
the process to run in daemon mode. In fact, HAProxy starts by default with a no
daemon mode.

So, how can we do to run multiple processes inside one container. There we go for
the `process managers` family. There is plenty of solution to manage the processes
like we have `init.d`.

In this lab, we will use a small one called `S6` http://skarnet.org/software/s6/.
And more specifically, we will use https://github.com/just-containers/s6-overlay which
bring some simplification of using `S6` in our containers. For more details about the
features: https://github.com/just-containers/s6-overlay#features

You have also a good explanation about the Docker way perception from the maintainers
 of `S6`: https://github.com/just-containers/s6-overlay#the-docker-way

This process manager will give us the possibility to start one or more process at
a time in a Docker container. That's just what we need.

So to add it to your images, you will find `TODO: [S6] Install` placeholders in
the Docker images of [HAProxy](ha/Dockerfile) and the [web application](webapp/Dockerfile)

Replace the `TODO` with the following Docker instruction:

```
RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz
```

To build your images, run the following commands inside your Vagrant VM instance:

```
# Build the haproxy image
cd /vagrant/ha
sudo docker build -t softengheigvd/ha .

# Build the webapp image
cd /vagrant/webapp
sudo docker build -t softengheigvd/webapp .
```

or use the script which do the same for you:

```
/vagrant/build-images.sh
```

**References**:

  - [RUN](https://docs.docker.com/engine/reference/builder/#/run)
  - [docker build](https://docs.docker.com/engine/reference/commandline/build/)

Ok, this part was the easiest one. We just installed one more stuff inside our image
and now we need to do something with that.

**Note**: If you run your containers right now, you will notice that there is no difference
between now and the previous state of our images. It's normal as we do not have configured
anything for `S6` and we do not start it in the container.

To run your images as containers, first you need to stop the current containers and remove
them. You can do that with the following commands:

```
# Stop and force to remove the containers
sudo docker rm -f s1
sudo docker rm -f s2
sudo docker rm -f ha

# Start the containers
sudo docker run -d --name s1 softengheigvd/webapp
sudo docker run -d --name s2 softengheigvd/webapp
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --link s1 --link s2 --name ha softengheigvd/ha
```

or you can use the script to start two base containers:

```
/vagrant/start-containers.sh
```

You can check the state of your containers as we already did it in previous task with `docker ps` which should results with something like that:

```
CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS                                                                NAMES
2b277f0fe8da        softengheigvd/ha       "./run.sh"          21 seconds ago      Up 20 seconds       0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
0c7d8ff6562f        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s2
d9a4aa8da49d        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s1
```

**Remarks**:

  - If you have more than 2 backends, you will need to adapt these commands for
    the additional containers. Same for the script.

  - You have better to train the Docker commands as the next tasks will require more and
    more of them. The scripts provided for the basics will no more be usable.

**References**:

  - [docker ps](https://docs.docker.com/engine/reference/commandline/ps/)
  - [docker run](https://docs.docker.com/engine/reference/commandline/run/)
  - [docker rm](https://docs.docker.com/engine/reference/commandline/rm/)

We need to configure `S6` as our main process and then replace the current ones. For that
we will update our Docker images [HAProxy](ha/Dockerfile) and the [web application](webapp/Dockerfile) and
replace the: `TODO: [S6] Replace the following instruction` by the following Docker instruction:

```
# This will start S6 as our main process in our container
ENTRYPOINT ["/init"]
```

**References**:

  - [ENTRYPOINT](https://docs.docker.com/engine/reference/builder/#/entrypoint)

You can build and run the updated images (use the commands already provided earlier). As you
can observe if you try to go to http://192.168.42.42, there is nothing live.

It's the expected behavior for now as we just replaced the application process by
the process manager one. We have a superb process manager up and running but no more
application.

To remedy to this situation, we will prepare the starting scripts for `S6` and to copy
them at the right place. Once done, they will be automatically taken into account and
our applications will be available again.

Let's start by creating a folder called `service` in `ha` and `webapp` folders. You can
use the above commands:

```
mkdir -p /vagrant/ha/services/ha /vagrant/webapp/services/node
```

**Remarks**:

  - `mkdir -p` will make directory recursively. If one is missing in the hierarchy,
    it will be created. More info: `man mkdir`.

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

In each directory, create an executable file called `run`. You can achieve that
by the following commands:

```
touch /vagrant/ha/services/ha/run && chmod +x /vagrant/ha/services/ha/run
touch /vagrant/webapp/services/node/run && chmod +x /vagrant/webapp/services/node/run
```

**Remarks**:

  - The `&&` in the previous command mean: if `touch` command return RC == 0 then
    do command `chmod`.

  - `touch` will create the file and `chmod` will make it executable. For more info
    of the commands, run: `man touch` or `man chmod`.

Copy the content of the file [ha/scripts/run.sh](ha/scripts/run.sh) into the newly created
file `ha/services/run`. Do the same for [webapp/run.sh](webapp/run.sh) into `webapp/services/run`.

Once copied, replace the hashbang instruction in both files. Replace `#!/bin/sh` by `#!/usr/bin/with-contenv sh`.
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
COPY services/node /etc/services.d/node
RUN chmod +x /etc/services.d/node/run
```  

**References**:

  - [COPY](https://docs.docker.com/engine/reference/builder/#/copy)
  - [RUN](https://docs.docker.com/engine/reference/builder/#/run)

**Remarks**:

  - We can discuss if is is really necessary to do `RUN chmod +x ...` in the image creation as we already
    created the `run` files with `+x` rights. Doing so make sure that we will never have issue with copy/paste of
    the file or transferring between unix world and windows world.

Build again your images and run them. If everything is working fine, you should be able
to open http://192.168.42.42 and see the same content as the previous task.

** Deliverables **

1. Take a screenshot of the stats page of HAProxy http://192.168.42.42:1936. You
  should see your backend nodes. It should be probably really similar than the screenshot
  of previous task

2. Give the name of the branch you do your current task

3. Provide the Docker files in their updated form for this task

4. Provide the run scripts used for `S6`

5. Describe your difficulties for this task and your understanding of
  what is happening during this task. Explain in your own words why are we
  installing a process manager. Do not hesitate to do more researches and to
  find more articles on that topic to illustrate the problem.

### Task 2: Add a cluster membership management tool

During this task, we will focus on how to make our infrastructure more flexible. To
achieve this goal, we need a tool that allow each node to know about the other nodes.

We will use `Serf` for this. You can read more about this tool on https://www.serf.io/

The idea is that each container will have a `serf agent` running on it. When a node
appear or disappear, we will be able to react accordingly. `Serf` propagates events
in its cluster and then each node can trigger scripts depending which event was fired.

So in summary, in our infrastructure, we want the following:

1. Start our load balancer (HAProxy) and let it stay alive forever (or at least for the longest uptime as possible).

2. Start one or more backend nodes at anytime after the load balancer has been started

3. Make sure the load balancer knows about the nodes that appears and the nodes that disappear. For this,
  it means we want to react and reconfigure the load balancer accordingly to the topology state.

On the paper, the things seems quite clear and easy but to achieve everything, it remains few
steps to be ready. So we will start by installing `Serf` and see how it is working with simple events
and triggers.

To install `Serf`, we have to add the following Docker instruction in the `ha` and `webapp` Docker
files. Replace the `TODO: [Serf] Install` in [ha/Dockerfile](ha/Dockerfile) and [webapp/Dockerfile](webapp/Dockerfile)
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
following command to do that.

```
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

```
touch /vagrant/ha/services/serf/run && chmod +x /vagrant/ha/services/serf/run
touch /vagrant/webapp/services/serf/run && chmod +x /vagrant/webapp/services/serf/run
```

In the `ha/services/serf/run` file, add the following script. This will start and
enable the capabilities of `Serf` on the load balancer. Do not pay attention of the
tricky part of the script about the process management. You can read the comments
and ask us fore more info if you want.

The principal part between `SERF START` and `SERF END` is the command we prepare
to run the serf agent.

```
#!/usr/bin/with-contenv bash

# WARNING: The tricky part in this script is the way we manage the process of Serf. We
#          do that because Serf does not handle the SIGTERM correctly. Therefore, we
#          need a different way to manage the process to start/stop it correctly.

# Get the current process ID to avoid killing an unwanted process
pid=$$

# Define a function to kill the Serf process as Serf does not accept SIGTERM
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

# Retrieve the process ID of the command run in background
pid=$!

# Wait forever to simulate a foreground process for S6
wait
```

Let's take the time to analyze the `Serf` agent command. We launch the `Serf` agent
with the command:

```
serf agent
```

Next, we append to the command the way to join a specific `Serf` cluster where the
address of the cluster is `ha`. In fact, our `ha` node will act as a sort of master
node but as we are in a decentralized architecture, it can be any of the nodes with
a `Serf` agent.

For example, if we start `ha` first, then `s2` and finally `s1`, we can imagine
that `ha` will connect serf to itself as it is the first one. Then, `s2` will
reference to `ha` to be in the same cluster and finally `s1` can reference `s1`.
Therefore, `s1` will join the same cluster than `s2` and `ha` but through `s2`.

For simplicity, all our nodes will register to the same cluster trough the `ha`
node.

```
--join ha
```

**Remarks**:

  - Once the cluster is up, if `ha` node leave the cluster, it will not be a real
    issue. The cluster will continue to exist. In the deliverables, describe which
    problem exists with the current solution based on the previous explanations and
    remarks.

To make sure that `ha` load balancer can leave and enter the cluster again, we add
the `--replay` option. This will allow to replay the past events and then react to
these events. In fact, due to the problem you have to guess, this will probably not
be really useful.

```
--replay
```

Then we append the event handlers to react to some events.

```
--event-handler member-join=/serf-handlers/member-join.sh
--event-handler member-leave,member-failed=/serf-handlers/member-leave.sh
```

At the moment the `member-add` and `member-remove` scripts are missing. We will add
them in a moment. These two scripts will manage the load balancer configuration.

And finally, we set a tag `role=<rolename>` to our load balancer. The `$ROLE` is
an environment variable that will be given from Docker `run` command through `-e "ROLE=balancer"`
in this case. This will let us the possibility to make the difference between our
backend nodes and our load balancer later in the scripts.

```
--tag role=$ROLE
```

**References**:

  - [serf agent](https://www.serf.io/docs/agent/basics.html)
  - [event handlers](https://www.serf.io/docs/agent/event-handlers.html)
  - [serf agent configuration](https://www.serf.io/docs/agent/options.html)
  - [join -replay](https://www.serf.io/docs/commands/join.html#_replay)

Let's prepare the same kind of configuration. Copy the `run` file you just created
in `webapp/services/serf` and replace the content between `SERF START` and `SERF END`
by the following one:

```
# We build the Serf command to run the agent
COMMAND="/opt/bin/serf agent"
COMMAND="$COMMAND --join serf-cluster"
COMMAND="$COMMAND --tag role=$ROLE"
```

This time, we do not need to have event handlers for the backend nodes. The backend nodes
will just appear and disappear at some point in the time and nothing else. The `$ROLE` is also
replaced by the `-e "ROLE=backend"` from Docker `run` command.

Again, we need to update our Docker images to add the `Serf` service to `S6`.

In both Docker image files in [ha](ha) and [webapp](webapp) folders, replace `TODO: [Serf] Add Serf S6 setup`
by the following two Docker instructions:

```
COPY services/serf/ /etc/services.d/serf
RUN chmod +x /etc/services/serf/run
```

And finally, you can expose the `Serf` ports through your Docker image files. Replace
the `TODO: [Serf] Expose ports` by the following content:

```
EXPOSE 7946 7373
```

**References**:

  - [EXPOSE](https://docs.docker.com/engine/reference/builder/#/expose)

It's time to build the images and to run the containers. You can use the provided scripts
run the command manually. At this stage, you should have your application running as the
`Serf` agents. To ensure that, you can access http://192.168.42.42 to see if you backends
are responding and you can check the Docker logs to see what is happening. Simply run:

```
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
cannot resolve the DNS names of the nodes. This is due to the latest versions of
Docker where the networking have been totally reworked.

To solve this issue, we need to go a little more deeper in Docker commands and we
need to create our own Docker network. For that, we will use the following command:

```
sudo docker network create --driver bridge heig
```

If you want to know more about Docker networking, take the time to read the different
pages in the references. Docker team provide a good overview and lot of details about
this important topic.

From now, to start our containers, we need to add the following argument to the `docker run` command

```
--network heig
```

So to start the `ha` container the command become:

```
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --link s1 --link s2 --name ha softengheigvd/ha
```

And for the backend nodes:

```
sudo docker run -d --network heig --name s1 softengheigvd/webapp
```

**References**:

  - [docker network create](https://docs.docker.com/engine/reference/commandline/network_create/)
  - [Understand Docker networking](https://docs.docker.com/engine/userguide/networking/)
  - [Embedded DNS server in user-defined networks](https://docs.docker.com/engine/userguide/networking/configure-dns/)
  - [docker run](https://docs.docker.com/engine/reference/commandline/run/)

**Deliverables**:

1. Provides the first 50 lines of docker logs output for each of the containers:  `ha`, `s1` and `s2`

2. Give the name of the branch for the current task

3. Give the Docker files updated

4. Give the answer to the question about the existing problem with the current solution

5. Give an explanation on how `Serf` is working. Read the official website to get more
  details about the `GOSSIP` protocol used in `Serf`. Try to find other solutions
  that can be used to solve such situation where we need some auto-discovery mechanism.

### Task 3: Play with handler scripts

We reached a state where we have nearly all the pieces in place to make the infrastructure
really dynamic. At the moment, we are missing the scripts that will manage the events
of serf and then react to member leave or member join.

We will start by creating the scripts in [ha/scripts](ha/scripts). So create two files in
this directory and set them as executable. You can use these commands:

```
touch /vagrant/ha/scripts/member-join.sh && chmod +x /vagrant/ha/scripts/member-join.sh
touch /vagrant/ha/scripts/member-leave.sh && chmod +x /vagrant/ha/scripts/member-leave.sh
```

In the `member-join.sh` script, put the following content:

```
#!/usr/bin/env bash

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  echo "Member join event received from: $HOSTNAME with role $HOSTROLE"
done
```

Do the same for the `member-leave.sh` with the following content:

```
#!/usr/bin/env bash

# We iterate over stdin
while read -a values; do
  # We extract the hostname, the ip, the role of each line and the tags
  HOSTNAME=${values[0]}
  HOSTIP=${values[1]}
  HOSTROLE=${values[2]}
  HOSTTAGS=${values[3]}

  echo "Member $SERF_EVENT event received from: $HOSTNAME with role $HOSTROLE"
done
```

We have to update our Docker file for `ha` node. Let's replace the
`TODO: [Serf] Copy events handler scripts` by the following content:

```
RUN mkdir /serf-handlers
COPY scripts/member-join.sh /serf-handlers
COPY scripts/member-leave.sh /serf-handlers
RUN chmod +x /serf-handlers/*.sh
```

Stop all your containers to have a fresh state:

```
sudo docker rm -f ha
sudo docker rm -f s1
sudo docker rm -f s2
```

Now, build you images:

```
# Build the haproxy image
cd /vagrant/ha
sudo docker build -t softengheigvd/ha .

# Build the webapp image
cd /vagrant/webapp
sudo docker build -t softengheigvd/webapp .
```

From there, you will be notified when you need to keep track of the logs. The logs
will be asked as a deliverable of the lab. You will notice: (**keep logs**) to remind
you to keep them for the report.

Run the `ha` container first and capture the logs with `docker logs` (**keep the logs**).

```
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --name ha softengheigvd/ha
```

Now, one of the two backend containers and capture the logs (**keep the logs**). Quite quickly after
started the container, capture also the logs of `ha` node (**keep the logs**).

```
sudo docker run -d --network heig --name s1 softengheigvd/webapp
sudo docker run -d --network heig --name s2 softengheigvd/webapp
```

**Remarks**:

  - You probably noticed that we removed the `links` to container `s1` and `s2`. We will explain that later.

Once started, get the logs (**keep the logs**) of the backend container.

To check there is something happening on the node `ha`, you will need to connect to
the running container to gather the custom log file that is created in the handler scripts.

For that, use the following command to connect to `ha` container in interactive mode.

```
sudo docker exec -ti ha /bin/bash
```

**References**:

  - [docker exec](https://docs.docker.com/engine/reference/commandline/exec/)

Once done, you can simply run the following command. This command is run inside
the running `ha` container. (**keep the logs**)

```
cat /var/log/serf.log
```

Once you have finished, you have simply to type `exit` in the container to quit
your shell session and at the same time the container. The container itself will
continue to run.

**Deliverables**:

1. Provides the first 50 lines of the logs of nodes `ha`, `s1` and `s2`. Give
  the logs for each step where it was asked for.

2. Give the branch name of the current task

3. Provide the logs from `ha` container gathered directly from the `/var/log/serf.log`
  file present in the container.

4. Try to reach your application through http://192.168.42.42. Illustrate your
  test with a screenshot.

5. Update the `member-join` and `member-leave` scripts (then rebuild your `ha` image)
  to log also the role and name of the node that handle the events, in this case, the
  `ha` container. Provide your updated scripts.

  **hint**: Take a look in the documentation about the `Event handlers` on `Serf` official web site.

### Task 4: Play with a template engine

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
RUN curl -sSLo /tmp/node.tar.xz https://nodejs.org/dist/v4.4.4/node-v4.4.4-linux-x64.tar.xz \
  && tar -C /usr/local --strip-components 1 -xf /tmp/node.tar.xz \
  && rm -f /tmp/node.tar.xz
```

We also need to update the base tools installed in the image to be able to extract the `NodeJS`
archive. So we have to replace the `RUN` instruction above `TODO: [HB] Update to install required tool to install NodeJS`
by the following one. It will add the `xz-utils` tool.

```
RUN apt-get update && apt-get -y install wget curl vim rsyslog xz-utils
```

**Remarks**:

  - You probably noticed that we have the backend image with a `NodeJS` application.
    So the image already contains `NodeJS`. We have based our backend image on an
    existing image that provide an installation of `NodeJS`. In our `ha` image,
    we take a shortcut and do a manual installation of `NodeJS` with at least one
    bad practice.

    In the original image of `NodeJS` the download the required files and then check
    the downloads against `GPG` signatures. We have skipped this part in our `ha`
    image but in practice, you should check everything you do to avoid issues like
    `man in the middle`.

    You can take a look to the following links if you want:

      - [NodeJS official Dockerfile](https://github.com/nodejs/docker-node/blob/ae9e2d4f04a0fa82261df86fd9556a76cefc020d/6.3/wheezy/Dockerfile#L4-L26)
      - [GPG](https://en.wikipedia.org/wiki/GNU_Privacy_Guard)
      - [Man in the middle attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack)

    The other reason why we have to manually install `NodeJS` by hand is that we
    cannot inherit from two images at the same time. As in our `ha` image, we already
    come `FROM` the `haproxy` official image, then we cannot use the `NodeJS` at the same time.

    In fact, the `FROM` instruction from Docker can be see like Java Inheritance model. You
    can inherit only from one super class at a time. So, what we can imagine is the following:

    ```
    os base image <- haproxy <- node haproxy <- our custom proxy conf
    ```

    Where each stage is an image. Doing the things like that allow us to reuse our
    own haproxy enriched with `NodeJS` capability in a different context. You can
    take a look to the Docker doc:

      - [FROM](https://docs.docker.com/engine/reference/builder/#/from)

It's time to install `Handlebars` and a small command line util to make it working
properly. For that, replace the `TODO: [HB] Install Handlebars and cli` by this
Docker instruction:

```
RUN npm install -g handlebars-cmd
```

**Remarks**:

  - [NPM](http://npmjs.org/) is a package manager for `NodeJS`. Like other package
    manager, one of his tasks is to manage the dependencies of any package. That's
    the reason why we have only to install `handlebars-cmd`. This package has
    `handlebars` as its dependencies.

Now we will update the handler scripts to use `Handlebars`. For the moment, we
will just play with a simple template. So, first create a file in `ha/config` called
`haproxy.cfg.hb` with the following content:

```
Container {{ name }} has joined the Serf cluster with the following IP address: {{ ip }}
```

We need our template present in our `ha` image. This time, the plumbing is already done
for you. In fact, in the Docker file, we have `COPY config /config/` which will copy all
the files present in the folder `ha/config` to `/config` in the image.

Then, update the `member-join.sh` script in [ha/scripts](ha/scripts) with the following content:

```
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

```
# Remove running containers
sudo docker rm -f ha
sudo docker rm -f s1
sudo docker rm -f s2

# Build the haproxy image
cd /vagrant/ha
sudo docker build -t softengheigvd/ha .

# Run the HAProxy container
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --name ha softengheigvd/ha
```

Take the time to retrieve the output file in the `ha` container. Connect to the container:

```
sudo docker exec -ti ha /bin/bash
```

and get the content from the file (keep it for deliverables)

```
cat /tmp/haproxy.cfg
```

And quit the container with `exit`.

Now, do the same for `s1` and `s2` and retrieve the `haproxy.cfg` file.

```
# 1) Run the S1 container
sudo docker run -d --network heig --name s1 softengheigvd/webapp

# 2) Connect to the ha container
sudo docker exec -ti ha /bin/bash

# 3) From the container, extract the content (keep it for deliverables)
cat /tmp/haproxy.cfg

# 4) Quit the ha container
exit

# 5) Rune the S2 container
sudo docker run -d --network heig --name s2 softengheigvd/webapp

# 6) Connect to the ha container
sudo docker exec -ti ha /bin/bash

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

2. Give the branch for the current task

3. Give the `/tmp/haproxy.cfg` generated in the `ha` container after each steps

4. Based on the three output files gathered, what can you tell about the way we
  generate it?

### Task 5: Generate the HAProxy config based on Serf events

At this stage, we have:

  - Two images with `S6` process manager that starts `Serf agent` and an
    `Application` (HAProxy or Node app)

  - The `ha` image contains the required stuff to react to `Serf` events when a
    container join or leave the `Serf` cluster

  - A template engine in `ha` image ready to used to generate the HAProxy configuration

Now, we need to refine our `join` and `leave` scripts to generate a proper HAProxy
configuration file.

First, we will copy/paste the content of [ha/config/haproxy.cfg](ha/config/haproxy.cfg)
file into [ha/config/haproxy.cfg.hb](ha/config/haproxy.cfg.hb). Then we will replace
the content between `# HANDLEBARS START` and `# HANDLEBARS STOP` by the following
content:

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
generate the correct configuration. In the file [ha/scripts/member-join.sh](ha/scripts/member-join.sh)
replace the whole content by the following one. Take the time to read the comments.

The mechanism in place to manage the `join` and `leave` events is the following:

  1. We check if the event comes from a backend node (the role is used)

  2. We create a file with the hostname and ip of each backend node that join the cluster

  3. We build the handlebars command to generate the new configuration from the list
    of files that represent our backend nodes

The same logic also apply when a node leave the cluster. In this case, the second step
will remove the file with the node data.

```
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
fi
```

And here we go for the `member-leave.sh` script. The script differs only for the part where
we remove the backend nodes registered via the `member-join.sh`.

```
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
fi

```

**Remarks**:

  - The way we keep track the backend nodes is pretty simple and make the assumption
    there is no concurrency issue with `Serf`. That's reasonable enough to get a
    quite simple solution.

We need to make sure the image has the folder `/nodes` created. In the Docker file,
replace the `TODO: [CFG] Create the nodes folder` by the following Docker instruction:

```
RUN mkdir /nodes
```

And we can do a little bit of cleanup in some files. In [ha/services/ha/run](ha/services/ha/run), you can
remove the two lines above `TODO: [CFG] Remove the following two lines`.

We are ready to build and test our `ha` image. Let's proceed the same as the [previous task](#ttb).
You should keep track the same outputs for the deliverables. You will have to replace
the file in the `cat` command.

```
cat /tmp/haproxy.cfg
```

becomes

```
cat /usr/local/etc/haproxy/haproxy.cfg
```

You can also get the list of registered nodes from inside the `ha` container. Run
the following command to see the list of files that tracks the backend nodes:

```
ls /nodes
```

Stop one of the two containers with the following Docker command:

```
sudo docker stop s1
```

Now, you can connect again to the `ha` container and get the haproxy configuration
file and also the list of backend nodes. Use the previous command to reach this goal.

**Deliverables**:

1. Give the branch for the current task

2. Give the `/tmp/haproxy.cfg` generated in the `ha` container after each steps

3. Give the output of `ls /nodes` from inside the `ha` container.

4. Give the configuration file after you stopped one container and the list of
  nodes present in the `/nodes` folder.

5. Propose a different approach to manage the list of backend nodes. You do
  not need to implement it.

### Task 6: Make everything working like a charm

We have all the pieces ready to work and we just need to make sure the configuration
of HAProxy is up-to-date and taken into account by HAProxy.

We will try to make HAProxy reload his config with the minimal downtime. At the moment,
we will replace `TODO: [CFG] Replace this command` in [ha/services/ha/run](ha/services/ha/run)
by the following script part. As usual, take the time to read the comments.

```
# Get the current process ID to avoid killing an unwanted process
pid=$$

# Define a function to stop gracefully HAProxy
sigterm() {
  kill -USR1 $pid
}

# Trap the SIGTERM and in place run the function that will kill the process
trap sigterm SIGTERM

# Retrieve the PID value from
if [ -f /var/run/haproxy.pid ]; then
    HANDOFFPID=`cat /var/run/haproxy.pid`
fi

# In general, old applications are not designed to run through a process manager
# out of the box. That's the reason to do some tricks to catch manually the PID
# of the process and to manage manually the way we start/stop the process.
#
# In this case, the idea is to get the PID of HAProxy before we start it. If there
# is a PID, then it means for HAProxy a restart. In fact, HAProxy will start a new
# process with a different PID from the one we retrieved and once the new process
# is ready, the previous one is stopped.
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg -sf $HANDOFFPID &

# Then, we store the new PID
pid=$!

# And write it a file to get it on next restart
echo $pid > /var/run/haproxy.pid

# Finally, we wait as S6 launch this shell script. This will simulate
# a foreground process for S6. All that tricky stuff is required because
# we use a process manager in a Docker environment. The applications need
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

```
# Send a SIGHUP to the process. It will restart HAProxy
s6-svc -h /var/run/s6/services/ha
```

**References**:

  - [S6 svc doc](http://skarnet.org/software/s6/s6-svc.html)

It's time to build and run our images. Again, you can simply use the following instructions:

```
# Force remove the three containers
sudo docker rm -f ha
sudo docker rm -f s1
sudo docker rm -f s2

# Build the haproxy image
cd /vagrant/ha
sudo docker build -t softengheigvd/ha .

# Start ha container
sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --network heig --name ha softengheigvd/ha
```

At this stage, if you try to reach `http://192.168.42.42`, it will not work. No surprise as
we do not start any backend node. Let's start one container and try to reach the same URL.

```
# Start one backend node
sudo docker run -d --network heig --name s1 softengheigvd/webapp
```

If everything works well, you could reach your backend application through the
load balancer. And now we start a two more backend nodes.

```
# Start second backend node
sudo docker run -d --network heig --name s2 softengheigvd/webapp

# Start third backend node
sudo docker run -d --network heig --name s3 softengheigvd/webapp
```

This time, you can see the round robin balancing. It can take few seconds before
the second node become available. The HAProxy need to restart and this process
take a little time.

**Deliverables**:

1. Take a screenshot of the HAProxy stat page.

2. Give your own feelings about the final solution. Propose improvements or ways
  to do the things differently. If any, provides the links of your readings for
  the improvements.

3. A live demo where you add and remove a backend container.

#### Lab due date

Deliver your results at the latest 15 minutes before class TBD

#### Windows troubleshooting

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
