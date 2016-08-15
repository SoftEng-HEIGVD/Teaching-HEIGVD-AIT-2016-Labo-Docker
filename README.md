title: Lab ? - Docker
---

## Lab ? - Docker


#### Pedagogical objectives

* Reuse part of a previous labo concepts about the load balancing

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

** DISCLAIMER **: In this lab, we will go through a possible manner to manage a
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

```bash
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

```bash
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

    $ vagrant ssh

Once inside the VM you can list the running containers like so:

    $ docker ps

You should see output similar to the following:

    CONTAINER ID        IMAGE                  COMMAND             CREATED             STATUS              PORTS                                                                NAMES
    2b277f0fe8da        softengheigvd/ha       "./run.sh"          21 seconds ago      Up 20 seconds       0.0.0.0:80->80/tcp, 0.0.0.0:1936->1936/tcp, 0.0.0.0:9999->9999/tcp   ha
    0c7d8ff6562f        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s2
    d9a4aa8da49d        softengheigvd/webapp   "./run.sh"          22 seconds ago      Up 21 seconds       3000/tcp                                                             s1

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

```json
{
  "hello": "world!",
  "ip": "172.17.0.7",
  "host": "2b277f0fe8da",
  "tag": "s1",
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

### Task 1: Add a process manager to your images

Actually, Docker has for some people a big limitation but it was designed as a core
feature:

  `One container == one process`

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

  - (RUN)[https://docs.docker.com/engine/reference/builder/#/run]
  - (docker build)[https://docs.docker.com/engine/reference/commandline/build/]

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
  sudo docker run -d --restart=always -e "TAG=s1" --name s1 softengheigvd/webapp
  sudo docker run -d --restart=always -e "TAG=s2" --name s2 softengheigvd/webapp
  sudo docker run -d -p 80:80 -p 1936:1936 -p 9999:9999 --restart=always -v /supervisor:/supervisor --link s1 --link s2 --name ha softengheigvd/ha
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

  - (docker ps)[https://docs.docker.com/engine/reference/commandline/ps/]
  - (docker run)[https://docs.docker.com/engine/reference/commandline/run/]
  - (docker rm)[https://docs.docker.com/engine/reference/commandline/rm/]

We need to configure `S6` as our main process and then replace the current ones. For that
we will update our Docker images [HAProxy](ha/Dockerfile) and the [web application](webapp/Dockerfile) and
replace the: `TODO: [S6] Replace the following line` by the following Docker instruction:

  ```
  ENTRYPOINT ["/init"]
  ```

**References**:

  - (ENTRYPOINT)[https://docs.docker.com/engine/reference/builder/#/entrypoint]

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
  touch /vagrant/ha/services/ha/run && chmod +x /vagrant/ha/services/node/run
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

In `ha` Docker file, you need to replace: `TODO: [S6] Replace the two lines above` by

  ```
  COPY services/ha /etc/services.d/ha
  RUN chmod +x /etc/services.d/ha/run
  ```

Do the same in the `webapp`Docker file with the following replacement: `TODO: [S6] Replace the two lines above` by

  ```
  COPY services/node /etc/services.d/node
  RUN chmod +x /etc/services.d/node/run
  ```  

**References**:

  - (COPY)[https://docs.docker.com/engine/reference/builder/#/copy]
  - (RUN)[https://docs.docker.com/engine/reference/builder/#/run]

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

2. Provide the Docker files in their updated form for this task

3. Provide the run scripts used for `S6`

4. Describe your difficulties for this task and your understanding of
  what is happening during this task. Explain in your own words why are we
  installing a process manager. Do not hesitate to do more researches and to
  find more articles on that topic to illustrate the problem.






### Task 1: Install the tools

**Deliverables:**

1. Explain how the load balancer behaves when you open and refresh the
  URL <http://192.168.42.42> in your browser. Add screenshots to
  complement your explanations. We expect that you take a deeper a
  look at session management.

2. Explain what should be the correct behavior of the load balancer for
  session management.

3. Provide a sequence diagram to explain what is happening when one
  requests the URL for the first time and then refreshes the page. We
  want to see what is happening with the cookie. We want to see the
  sequence of messages exchanged (1) between the browser and HAProxy
  and (2) between HAProxy and the nodes S1 and S2. Here is an example:

  ![Sequence diagram for part 1](assets/img/seq-diag-1.png)

4. Provide a screenshot of the summary report from JMeter.

5. In the Vagrant VM, run the following command:

  ```bash
  $ docker stop s1
  ```

  Clear the results in JMeter and re-run the test plan. Explain what
  is happening when only one node remains active. Provide another
  sequence diagram using the same model as the previous one.


### Task 2: Sticky sessions

It's time to go further. At this stage, we now have a load balanced
web application but the session management is totally messed up. In
this task your job is to fix the configuration of HAProxy to enable
sticky session management.

For that, you will have to play with docker a little bit more. You
might want to consult the file [Docker quick reference](Docker quick reference.md) for some
useful commands and hints.

**Deliverables:**

1. There is different way to implement the sticky session. One possibility is to use the SERVERID provided by HAProxy. Another way is to use the NODESESSID provided by the application. Briefly explain the difference between both approaches (provide a sequence diagram with cookies to show the difference).

  * Choose one of the both stickiness approach for the next tasks.

2. Provide the modified `haproxy.cfg` file with a short explanation of
  the modifications you did to enable sticky session management.

3. Explain what is the behavior when you open and refresh the URL
  <http://192.168.42.42> in your browser. Add screenshots to
  complement your explanations. We expect that you take a deeper a
  look at session management.

4. Provide a sequence diagram to explain what is happening when one
  requests the URL for the first time and then refreshes the page. We
  want to see what is happening with the cookie. We want to see the
  sequence of messages exchanged (1) between the browser and HAProxy
  and (2) between HAProxy and the nodes S1 and S2. We also want to see
  what is happening when a second browser is used.

5. Provide a screenshot of JMeter's summary report. Is there a
  difference with this run and the run of Task 1?

  * Clear the results in JMeter.

  * Now, update the JMeter script. Go in the HTTP Cookie Manager and
  <del>uncheck</del><ins>verify that</ins> the box `Clear cookies each iteration?`
  <ins>is unchecked</ins>.

6. Provide a screenshot of JMeter's summary report. This time, is there
  a difference with this run and the run of Task 1?

  * Once again, update the JMeter script. Go in `Thread Group` and
  update the `Number of threads`. Set the value to 2.

7. Provide a screenshot of JMeter's summary report. Give a short
  explanation of what the load balancer is doing.


### Task 3: Drain mode

HAProxy provides a mode where we can set a node to DRAIN state. In
this case, HAProxy will let _current_ sessions continue to make
requests to the node in DRAIN mode and will redirect all other traffic
to the other nodes.

In our case, it means that if we put `s1` in DRAIN mode, all new
traffic will reach the `s2` node and all current traffic directed to
`s1` will continue to communicate with `s1`.

Another mode is MAINT mode which is more intrusive than DRAIN. In this
mode, all current and new traffic is redirected to the other active
nodes even if there are active sessions.

In this task, we will experiment with these two modes. We will base
our next steps on the work done on Task 2. We expect you have a
working Sticky Session configuration with two web app nodes up and
running called `s1` and `s2`.

When all the infra is up and running, perform the following steps:

1. Open a browser on your host

2. Navigate to `http://192.168.42.42`. You will reach one of the two
   nodes. Let's assume it is `s1` but in your case, it could be `s2`
   as the balancing strategy is roundrobin.

3. Refresh the page. You should get the same result except that the
   views counter is incremented.

4. Refresh multiple times the page and verify that you continue to
   reach the same node and see the sessionViews counter increased.

5. In a different tab, open `http://192.168.42.42:1936` and take a
   look. You should have something similar to the following
   screenshot.

![Admin Stat view of HAProxy](assets/img/stats.png)

  You should be able to see the `s1` and `s2` nodes and their state.

For the next operations, you will use HAProxy's built-in command line
to query its status and send commands to it. HAProxy provides the
command line via a TCP socket so that a system administrator is able
to connect to it when HAProxy runs on a remote server. You will use
`socat` to connect to the TCP socket. `socat` is a universal
command-line tool to connect pretty much anything with anything. The
tool is already installed in the Vagrant VM and therefore you do not
need any additional install on your host.

To use it, log into the Vagrant VM via ssh (`vagrant ssh`) and then
type the following:

```bash
$ socat - tcp:localhost:9999
prompt

> help
Unknown command. Please enter one of the following commands only :
  clear counters : clear max statistics counters (add 'all' for all counters)
  clear table    : remove an entry from a table
  help           : this message
  prompt         : toggle interactive mode with prompt
  quit           : disconnect
  show info      : report information about the running process
[...]
```

After typing `socat - tcp:localhost:9999` and pressing enter you will
see... nothing. You are connected to HAProxy, but it remains silent
for the time being. You have to turn on the prompt by typing
`prompt`. You will see a new line starting with `>`. Now you can enter
commands that will be directly interpreted by HAProxy.

First, increase the client timeout to avoid losing connections.

```bash
> set timeout cli 1d
```

Now, to set a node's state to `ready`, `maint` or `drain`, enter the
following command:

```bash
> set server nodes/<containerName> state <state>
```

**Note:** In fact, the `nodes` is the group of backend nodes
  labelled. You will find the corresponding `backend nodes` in ha
  config.

**Note 2:** The containerName is the label of the node. In fact, in
this lab, we used the same name as Docker container names but both
names are not linked together. We can choose different names if we
want. The name set in this command is the name present in the HAProxy
admin stats interface (or also found in the config file).

**Note 3:** We will use only the three states presented there. Take
  care that the command only accept lower cases states.

**Deliverables:**

1. Take a screenshot of the Step 5 and tell us which node is answering.

2. Based on your previous answer, set the node in DRAIN mode. Take a
  screenshot of the HAProxy state page.

3. Refresh your browser and explain what is happening. Tell us if you
  stay on the same node or not. If yes, why? If no, why?

4. Open another browser and open `http://192.168.42.42`. What is
  happening?

5. Clear the cookies on the new browser and repeat these two steps
  multiple times. What is happening? Are you reaching the node in
  DRAIN mode?

6. Reset the node in READY mode. Repeat the three previous steps and
  explain what is happening. Provide a screenshot of HAProxy's stats
  page.

7. Finally, set the node in MAINT mode. Redo the three same steps and
  explain what is happening. Provide a screenshot of HAProxy's stats
  page.

### Task 4: Round robin in degraded mode.

In this part, we will try to simulate a degraded mode based on the round-robin previously configured.

To help expermimenting the balancing when an application started to behave strangely, the web application
has a REST resource to configure a delay in the response. You can set
an arbitrary delay in milliseconds. Once the delay is configured, the
response will take the amount of time configured.

To set the timeout, you have to do a `POST` request with the following
content (be sure the `Content-Type` header is set to
`application/json`. The configuration is applicable on each
node. Therefore, you can do one `POST` request on
`http://192.168.42.42/delay` and taking a look at the response cookies
will tell you which node has been configured.

```json
{
  "delay": 1000
}
```

The previous example will set a delay of 1 second.

Or from the Vagrant VM, retrieve the IP of the container you want to
configure and then do the `curl` command to configure the delay.

```bash
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' <containerName>

$ curl -H "Content-Type: application/json" -X POST -d '{"delay": 1000}' http://<containerIp>:3000/delay
```

To reset the delay configuration, just do a `POST` with 0 as the delay
value.

Prepare your JMeter script with cookies erased (this will simulate new
clients for each requests) and 10 threads this will simulate 10
concurrent users.

*Remark*: In general, take a screenshot of the summary report in
 JMeter to explain what is happening.

**Deliverables:**

*Remark*: Make sure you have the cookies are kept between two requests.

1. Be sure the delay is of 0 milliseconds is set on `s1`. Do a run to have base data to compare with the next experiments.

2. Set a delay of 250 milliseconds on `s1`. Relaunch a run with the
  JMeter script and explain what it is happening?

3. Set a delay of 2500 milliseconds on `s1`. Same than previous step.

4. In the two previous steps, are there any error? Why?

5. Update the HAProxy configuration to add a weight to your nodes. For
  that, add `weight [1-256]` where the value of weight is between the
  two values (inclusive). Set `s1` to 2 and `s2` to 1. Redo a run with 250ms delay.

6. Now, what happened when the cookies are cleared between each requests and the delay is set to 250ms ? We expect just one or two sentence to summarize your observations of the behavior with/without cookies.

### Task 5: Balancing strategies

In this part of the lab, you will be less guided and you will have more opportunity to play and discover HAProxy. The main goal of this part is to play with various strategies and compare them together.

We propose that you take the time to discover the different strategies in [HAProxy documentation](http://cbonte.github.io/haproxy-dconv/configuration-1.6.html#balance) and then pick two of them (can be round-robin but will be better to chose two others). Once you have chosen your strategies, you have to play with them (change configuration, use Jmeter script, do some experiments).

**Deliverables:**

1. Briefly explain the strategies you have chosen and why you have chosen them.

2. Provide evidences that you have played with the two strategies (configuration done, screenshots, ...)

3. Compare the both strategies and conclude which is the best for this lab (not necessary the best at all).

#### References

* [HAProxy Socket commands (drain, ready, ...)](https://cbonte.github.io/haproxy-dconv/configuration-1.5.html#9.2-set%20server)
* [Socat util to run socket commands](http://www.dest-unreach.org/socat/)
* [Socat command examples](https://stuff.mit.edu/afs/sipb/machine/penguin-lust/src/socat-1.7.1.2/EXAMPLES)

#### Lab due date

Deliver your results at the latest 15 minutes before class Wednesday, November 25.

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
