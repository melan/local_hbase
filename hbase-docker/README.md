# HBase in container

## HBase in Docker

This configuration builds a docker container to run HBase with Apache Phoenix. It includes:
 * Hadoop Name Node
 * Hadoop Data Node
 * HBase master
 * HBase region
 * Zookeeper

Any of the components can be either enabled or disabled if needed - they can run as subprocesses in one container as well as independent connected containers

## Build image

```
    make build
```

### Build settings

* **IMAGE_NAME** - a name for the result image. Default: `melan/hbase:1.3.1`
* **HBASE_PHOENIX_RELEASE** - target release of Phoenix. Default: `4.13.0`

## Run image

### Standalone image

To run the container in a standalone mode run: 

```
    docker run -d --name hbase melan/hbase:1.3.1
```

### Runtime configuration

#### Environment variables

* **HBASE_LOCAL_ZOOKEEPER** - run a local zookeeper. Default: `yes`
* **HBASE_SHARED_STORAGE** - should be set to `yes` if a shared folder is mounted into the containers. When enabled - every node will store data under own hostname. Default: `no`
* **HBASE_ENABLE_THRIFT** - should a HBase thrift service be enabled. Default: yes
* **HBASE_ENABLE_REST** - should a HBase REST service be enabled. Default: yes
* **HBASE_ENABLE_REGIONSERVER** - should a HBase Region service be enabled. Default: yes
* **HBASE_ENABLE_MASTER** - should a HBase Master service be enabled. Default: yes
* **HADOOP_ENABLE_NAMENODE** - should a Hadoop DFS Name Node service be enabled. Default: no
* **HADOOP_ENABLE_DATANODE** - should a Hadoop DFS Data Node service be enabled. Default: no
* **HADOOP_NAMENODE_URL** - URL of the Hadoop DFS Name Node. Default: hdfs://localhost/
* **ZK_HOST** - a name of a host where zookeeper quorum can be accessed on a default port (`2181`). This variable is used only when local zookeeper is disabled

#### Volumes

**/data** - HBase stores data in the folder. If you want to persist the date between hbase runs - mount a local folder to this mount point.

#### Ports

* **2181** - Zookeeper
* **8020** - HDFS NameNode
* **8080** - REST API
* **8085** - REST Web UI
* **9090** - Thrift API
* **9095** - Thrift Wen UI
* **16000** - HBase master port
* **16010** - HBase master info port
* **16020** - HBase region server port
* **16030** - HBase region server info port
* **50010** - Hadoop DFS Data Node
* **50020** - Hadoop DFS Data Node IPC
* **50070** - Hadoop Name Node WebUI
* **50075** - Hadoop DFS Data Node WebUI

### Find Hbase status

Master status if docker container DNS name is 'hbase-docker'

    http://hbase-docker:16010/master-status

The region servers status pages are linked from the above page.

Thrift UI

    http://hbase-docker:9095/thrift.jsp

REST server UI

    http://hbase-docker:8085/rest.jsp

(Embedded) Zookeeper status

    http://hbase-docker:16010/zk.jsp


### Test HBase is working via python over Thrift

Here I am connecting to a docker container with the name 'hbase-docker'
(such as created by the start-hbase.sh script).  The port 9090 is the
Thrift API port because [Happybase][1] [2] uses Thrift to talk to HBase.

    $ ipython
    Python 2.7.9 (default, Mar  1 2015, 12:57:24)
    Type "copyright", "credits" or "license" for more information.
    
    IPython 2.3.0 -- An enhanced Interactive Python.
    ?         -> Introduction and overview of IPython's features.
    %quickref -> Quick reference.
    help      -> Python's own help system.
    object?   -> Details about 'object', use 'object??' for extra details.
    
    In [1]: import happybase
    
    In [2]: connection = happybase.Connection('hbase-docker', 9090)
    
    In [3]: connection.create_table('table-name', { 'family': dict() } )
    
    In [4]: connection.tables()
    Out[4]: ['table-name']
    
    In [5]: table = connection.table('table-name')
    
    In [6]: table.put('row-key', {'family:qual1': 'value1', 'family:qual2': 'value2'})
    
    In [7]: for k, data in table.scan():
       ...:     print k, data
       ...:
    row-key {'family:qual1': 'value1', 'family:qual2': 'value2'}
    
    In [8]:
    Do you really want to exit ([y]/n)? y
    $

(Simple install for happybase: `sudo pip install happybase` although I
use `pip install --user happybase` to get it just for me)

### Test HBase is working from Java

    $ docker run --rm -it --link $id:hbase-docker dajobe/hbase hbase shell
    HBase Shell; enter 'help<RETURN>' for list of supported commands.
    Type "exit<RETURN>" to leave the HBase Shell
    Version 0.94.11, r1513697, Wed Aug 14 04:54:46 UTC 2013

    hbase(main):001:0> status
    1 servers, 0 dead, 3.0000 average load

    hbase(main):002:0> list
    TABLE
    table-name
    1 row(s) in 0.0460 seconds

Showing the `table-name` table made in the happybase example above.

Alternatively if you have the Hbase distribution available on the
host you can use `bin/hbase shell` if the hbase configuration has
been set up to connect to host `hbase-docker` zookeeper port 2181 to
get the servers via configuration property `hbase.zookeeper.quorum`

## Notes

[1] http://happybase.readthedocs.org/en/latest/

[2] https://github.com/wbolster/happybase
