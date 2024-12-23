mkdir -pv /bigdisk/pablo.claudino/blog_oplog/scripts/
echo "" > /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.js && vim -c 'startinsert' -c 'set paste' /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.js
echo "" > /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.BULK.js && vim -c 'startinsert' -c 'set paste' /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.BULK.js
echo "" > /bigdisk/pablo.claudino/blog_oplog/scripts/data_compare.js && vim -c 'startinsert' -c 'set paste' /bigdisk/pablo.claudino/blog_oplog/scripts/data_compare.js

# mlaunch highram
mng_version="8.0.3"
tools_version="100.10.0"
coll_name="collection01"

mlaunch kill --dir /bigdisk/pablo.claudino/blog_oplog/source
sleep 5
rm -rf /bigdisk/pablo.claudino/blog_oplog/source
mlaunch init --replicaset --nodes 1 --name rsBlogSource --binarypath /opt/mongodb/${mng_version}/bin --dir /bigdisk/pablo.claudino/blog_oplog/source --auth  --username testuser --password testpwd --port 27041

# drop collections
mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection01').drop()"
mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection02').drop()"

mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection01').drop()"
mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection02').drop()"

# create all data in Source
rm -fv /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.BULK.out && nohup mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --quiet < /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.BULK.js > /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.BULK.out &
tail -F /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.BULK.out

# insert data for oplog and take backup
mkdir -pv /bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump

rm -fv /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.out && nohup mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --quiet < /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.js > /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.out &

tail -f /bigdisk/pablo.claudino/blog_oplog/scripts/data_generator.out

# mongodump same mongo-tools version
nohup /opt/mongodb/${tools_version}/bin/mongodump --host localhost --port 27041 --username testuser -p "testpwd" --authenticationDatabase=admin --numParallelCollections=1 --oplog --out "/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump" > /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongodump.out &
tail -F /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongodump.out

# mongodump different mongo-tools version
# nohup /opt/mongodb-database-tools/${tools_version}/bin/mongodump --host localhost --port 27041 --username testuser -p "testpwd" --authenticationDatabase=admin --numParallelCollections=1 --oplog --out "/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump" > /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongodump.out &
tail -F /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongodump.out

# launch Target
mlaunch kill --dir /bigdisk/pablo.claudino/blog_oplog/target
sleep 5
rm -rf /bigdisk/pablo.claudino/blog_oplog/target
mlaunch init --replicaset --nodes 1 --name rsBlogTarget --binarypath /opt/mongodb/${mng_version}/bin --dir /bigdisk/pablo.claudino/blog_oplog/target --auth  --username testuser --password testpwd --port 27042

# permission to replay oplog
mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval 'db.getSiblingDB("admin").createRole({ role: "oplogReplay", privileges: [ { resource: { anyResource: true }, actions: [ "anyAction" ] }], roles:[]})'

mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval 'db.getSiblingDB("admin").grantRolesToUser("testuser", [{ role: "oplogReplay", db: "admin" }])'

mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval 'db.getSiblingDB("admin").getUser("testuser")'

# mongorestore same mongo-tools version
nohup /opt/mongodb/${tools_version}/bin/mongorestore -vvvv --host localhost --port 27042 --username testuser -p "testpwd" --oplogReplay --authenticationDatabase=admin "/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump" > /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongorestore.out &

# mongorestore different mongo-tools version
# nohup /opt/mongodb-database-tools/${tools_version}/bin/mongorestore -vvvv --host localhost --port 27042 --username testuser -p "testpwd" --oplogReplay --authenticationDatabase=admin "/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump" > /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongorestore.out &

tail -F /bigdisk/pablo.claudino/blog_oplog/${mng_version}/mongorestore.out


# create indexes
mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection01').createIndexes([{bindata2: 1}])"
mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection02').createIndexes([{bindata2: 1}])"
mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection01').createIndexes([{bindata2: 1}])"
mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('collection02').createIndexes([{bindata2: 1}])"


##### debug1 - empty bindata2 created before mongodump
mongosh --host rsBlogSource/localhost:27041 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('${coll_name}').find({bindata2:Binary.createFromBase64('', 2)},{bindata2:1}).sort({_id:1}).limit(2)"

# query same docs in source and target
/opt/percona_mongodb/5.0.27/bin/mongo --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd

conn2 = new Mongo("mongodb://testuser:testpwd@localhost:27041/admin?replicaSet=rsBlogSource")
db2 = conn2.getDB('test')
coll_name="collection01"
db2.getSiblingDB('test').getCollection(coll_name).find({_id: ObjectId('6759d891f325711f68a26b9e')})
db.getSiblingDB('test').getCollection(coll_name).find({_id: ObjectId('6759d891f325711f68a26b9e')})
// query oplog
db2.getSiblingDB('local').getCollection('oplog.rs').find({"o._id": ObjectId('6759d891f325711f68a26b9e')})
db.getSiblingDB('local').getCollection('oplog.rs').find({"o._id": ObjectId('6759d891f325711f68a26b9e')})

# bsondump same mongo-tools version
/opt/mongodb/${tools_version}/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/test/${coll_name}.bson

# bsondump different mongo-tools version
/opt/mongodb-database-tools/${tools_version}/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/test/${coll_name}.bson

# recheck due to subtype diff
# /opt/mongodb-database-tools/100.10.0/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.v100.10.0.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/test/${coll_name}.bson

# grep docs created before mongodump
grep '6759d891f325711f68a26b53\|6759d891f325711f68a26b9e' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.json

# grep '6759d891f325711f68a26b53\|6759d891f325711f68a26b9e' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.v100.10.0.json

##### debug2 - bindata caught by datacompare
# compare data
grep "var coll_name =" /bigdisk/pablo.claudino/blog_oplog/scripts/data_compare.js
sed -i "s/var coll_name =.*/var coll_name = '${coll_name}'/g" /bigdisk/pablo.claudino/blog_oplog/scripts/data_compare.js
grep "var coll_name =" /bigdisk/pablo.claudino/blog_oplog/scripts/data_compare.js

rm -fv /bigdisk/pablo.claudino/blog_oplog/${mng_version}/datacompare.out && nohup mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --quiet < /bigdisk/pablo.claudino/blog_oplog/scripts/data_compare.js > /bigdisk/pablo.claudino/blog_oplog/${mng_version}/datacompare.out &

tail -F /bigdisk/pablo.claudino/blog_oplog/${mng_version}/datacompare.out

# if no docs are found, get the two latest docs with empty bindata2
# mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd --eval "db.getSiblingDB('test').getCollection('${coll_name}').find({bindata2:Binary.createFromBase64('', 2)},{bindata2:1}).sort({_id:-1}).limit(2)"

# query same docs in source and target
/opt/percona_mongodb/5.0.27/bin/mongo --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd

conn2 = new Mongo("mongodb://testuser:testpwd@localhost:27041/admin?replicaSet=rsBlogSource")
db2 = conn2.getDB('test')
coll_name="collection01"
db2.getSiblingDB('test').getCollection(coll_name).find({_id: ObjectId('6759dd8a9cb7bf4160a29e2b')})
db.getSiblingDB('test').getCollection(coll_name).find({_id: ObjectId('6759dd8a9cb7bf4160a29e2b')})
// query oplog
db2.getSiblingDB('local').getCollection('oplog.rs').find({"o._id": ObjectId('6759dd8a9cb7bf4160a29e2b')})
db.getSiblingDB('local').getCollection('oplog.rs').find({"o._id": ObjectId('6759dd8a9cb7bf4160a29e2b')})

# parse the oplog file to understand where the update came from
## bsondump same mongo-tools version
/opt/mongodb/${tools_version}/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/oplog.bson

## bsondump different mongo-tools version
/opt/mongodb-database-tools/${tools_version}/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/oplog.bson

cat /bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.json | jq '.op' | sort -n | uniq -c

# grep docs found in comparedata in oplog file
grep '6759dd8a9cb7bf4160a29e0d\|6759dd8a9cb7bf4160a29e2b' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.json

# grep docs found in comparedata in collection file -> should find nothing
grep '6759dd8a9cb7bf4160a29e0d\|6759dd8a9cb7bf4160a29e2b' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.json

############## exceptional cases
# parse again with bsondump 100 because bsondump 4 gives wrong subtypes
/opt/mongodb-database-tools/100.10.0/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.v100.10.0.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/oplog.bson

grep '674f4a8a02cab2e3e9a26ac3\|674f4a8a02cab2e3e9a26a7b' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.v100.10.0.json

/opt/mongodb-database-tools/100.10.0/bin/bsondump --outFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.v100.10.0.json --bsonFile=/bigdisk/pablo.claudino/blog_oplog/${mng_version}/source/dump/test/${coll_name}.bson

grep '674f4a8a02cab2e3e9a26ac3\|674f4a8a02cab2e3e9a26a7b' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/${coll_name}.v100.10.0.json

## test with mongosh to triple check docs after mongodump
mongosh --host rsBlogTarget/localhost:27042 --authenticationDatabase admin -u testuser -p testpwd


# search for debug 1 docs in oplog parsed bson
grep '6759d891f325711f68a26b53\|6759d891f325711f68a26b9e' /bigdisk/pablo.claudino/blog_oplog/${mng_version}/oplog_dump.json

