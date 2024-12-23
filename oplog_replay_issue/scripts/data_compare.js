var data_compare = function(db_name, collection_name){
  conn2 = new Mongo("mongodb://testuser:testpwd@localhost:27041/admin?replicaSet=rsBlogSource")
  db2 = conn2.getDB(db_name)

  var total = db.getSiblingDB(db_name).getCollection(collection_name).estimatedDocumentCount()
  var print_progress = 5000
  var batch_size = 1000
  var skip_docs = 0

  print("Datetime: " + JSON.stringify(new Date()) + ". Total: " + total)
  for (skip_docs = 0; skip_docs < total + batch_size; skip_docs += batch_size ) {

    var rs_ids = db.getSiblingDB(db_name).getCollection(collection_name).find({},{_id: 1}).sort({_id: 1}).skip(skip_docs).limit(batch_size)
    var ls_ids = rs_ids.map(function(id1){return id1['_id']}).toArray()
    var ls_size = ls_ids.length

    var rs_result1 = db.getSiblingDB(db_name).getCollection(collection_name).find({_id: {$in: ls_ids}}).sort({_id: 1}).toArray()
    var rs_result2 = db2.getSiblingDB(db_name).getCollection(collection_name).find({_id: {$in: ls_ids}}).sort({_id: 1}).toArray()

    for (y = 0; y < ls_size; y++ ) {

      var result1 = rs_result1[y]
      var result2 = rs_result2[y]
      var ls_fieldlist = Object.keys(result1)

      ls_fieldlist.forEach(function(field_name){
        var field_result1 = result1[field_name]
        var field_result2 = result2[field_name]

        var unmatch_msg = ''
        if (field_result1.toString() != field_result2.toString()){
          unmatch_msg = unmatch_msg + 'Collection: ' + collection_name + ', _id: ' + result1["_id"] + ' field ' + field_name + ' toString does not match: ' + field_result1.toString() + ', ' + field_result2.toString()
        }
        if (field_name=='bindata0' || field_name=='bindata2' || field_name=='bindata3'){
          var result1_string = new String(field_result1.value())
          var result2_string = new String(field_result2.value())
          if ((!result1_string.startsWith(result2_string)) || (!result2_string.startsWith(result1_string))){
            unmatch_msg = unmatch_msg +  ' /  value does not match: ' + result1_string + ', ' + result2_string
          }
          if (field_result1.length() != field_result2.length()){
            unmatch_msg = unmatch_msg +  ' /  length does not match: ' + field_result1.length() + ', ' + field_result2.length()
          }
        }
        if (!(unmatch_msg =='')){
          print(unmatch_msg)
        }
      })
    }
    if (skip_docs % print_progress == 0){
      print("Datetime: " + JSON.stringify(new Date()) + ". Progress (" + print_progress + "): " + skip_docs + ". Total: " + total)
    }
  }
  print("Datetime: " + JSON.stringify(new Date()) + ". End: " + (skip_docs))
}

var coll_name = 'collection01'
data_compare('test', coll_name)
