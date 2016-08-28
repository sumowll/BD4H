---
layout: page
title: CentOS VM in VirtualBox with Vagrant
description: Georgia Tech big data bootcamp training material
---

**Attention: only tested on Mac with admin previlege**

# Pre-requisite

In order to use the Docker environment we provide, you will need two pre-requisite
1. [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. [Vagrant](http://www.vagrantup.com/downloads.html)

Also, please make sure you have enough free memory (4GB) available.

{% msgwarning %}
For Windows Users: Install GIT bash for windows which include SSH for access to the VM.
{% endmsgwarning%}

# Settings
The settings for the Vagrant VM are located in *vagrantconfig.yaml*. You can tweak them as necessary, such as adjusting the *number_cpus* or *memory_size* settings, to improve the performance of your VM.

# Setup
With pre-requiste softwares properly installed, you could setup your Centos VM learning environment. Before you actually run commands, please make sure you have enough previlege. For example, virtual network adapter and network filesystem will be set up.

{% msgwarning %}
For Windows Users: You may need to configure line endings before running vagrant up so the VM is properly configured. You can do this as a gobal configuration with "git config --global core.autocrlf false", or only for a given repo by setting "* text eol=lf" in .gitattributes of that repo. Be sure to follow the directions for refreshing a repo after changing line endings, as documented [here](https://help.github.com/articles/dealing-with-line-endings/#refreshing-a-repository-after-changing-line-endings "Refreshing a repository after changing line endings").
{% endmsgwarning%}

Open a terminal and you need to

1. Navigate to *vm* folder.
2. Run `vagrant up` to provision and run the VM.

(Note that the first run of `vagrant up` may take a long time. Please be patient.)

# Connect
You could connect to master node by run `vagrant ssh` in `vm` folder. You will find all materials in `/bootcamp` folder.

# Terminate
After you finish, you may want to terminate the virtual cluster. You could achieve that by

1. Navigate to *vm* folder.
2. Run `vagrant destroy -f` to destroy the VM.

Alternatively, you may just perform a graceful shutdown (without removing all traces of the virtual machine like above) by
1. Navigate to *vm* folder.
2. Run `vagrant halt` to gracefully shutdown the VM.
