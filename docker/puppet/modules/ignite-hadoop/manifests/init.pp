# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ignite-hadoop {
  define server() {
    package { "ignite-hadoop":
      ensure => latest,
    }

    package { "ignite-hadoop-service":
      ensure => latest,
    }

    file { "/etc/default/ignite-hadoop":
      content => template("ignite-hadoop/ignite-hadoop"),
      require => Package["ignite-hadoop"],
    }

    file { "/etc/hadoop/ignite.client.conf":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => Package["ignite-hadoop-service"],
    }
    file { "/etc/hadoop/ignite.client.conf/core-site.xml":
        content => template('ignite-hadoop/core-site.xml'),
        require => [File["/etc/hadoop/ignite.client.conf"]],
    }
    file {
      "/etc/hadoop/ignite.client.conf/mapred-site.xml":
        content => template('ignite-hadoop/mapred-site.xml'),
        require => [File["/etc/hadoop/ignite.client.conf"]],
    }
## let's make sure that ignite-hadoop libs are linked properly
    file {'/usr/lib/hadoop/lib/ignite-core.jar':
      ensure  => link,
      target  => '/usr/lib/ignite-hadoop/libs/ignite-core.jar',
      require => [Package["ignite-hadoop-service"]],
    }
    file {'/usr/lib/hadoop/lib/ignite-hadoop.jar':
      ensure  => link,
      target  => '/usr/lib/ignite-hadoop/libs/ignite-hadoop/ignite-hadoop.jar',
      require => [Package["ignite-hadoop-service"]],
    }

    service { "ignite-hadoop":
      ensure  => running,
      require => [ Package["ignite-hadoop", "ignite-hadoop-service"], File["/etc/default/ignite-hadoop"] ],
    }
  }
}
