# quick-pomelo-demo

Demo of [quick-pomelo](http://github.com/memdb/quick-pomelo)

## Server Quick Start

#### Install MemDB
[Guide](https://github.com/memdb/memdb#install-dependencies)

#### Start MemDB 
```
memdbcluster start --conf=./game-server/config/development/memdb.conf.js
// WARN: remember to add --conf on every command, or copy it to ~/.memdb
```

#### Install pomelo
```
sudo apt-get install -g memdb/pomelo

```

#### Start server
```
cd game-server
npm install

pomelo start --harmony
```

## Client Quick Start
You don't need to compile the client yourself since it requires lots of dependencies,
There is precompiled client binary for OSX. To start the client, just run
```
./start_clients.sh
```
This will start 3 client instances, each player will join a random area-server and pick a random free room in the server.
