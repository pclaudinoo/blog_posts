function generateString(slimit) {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for( var i=0; i < slimit; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    return text;
}

function generateStringSpecial(slimit) {
  var text = "";
  var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789ºª!#%&/()=?*+§±-_";
  for( var i=0; i < slimit; i++ )
      text += possible.charAt(Math.floor(Math.random() * possible.length));
  return text;
}

function generateInt(slimit, possible="0123456789") {
  var text = "";
  for( var i=0; i < slimit; i++ )
      text += possible.charAt(Math.floor(Math.random() * possible.length));
  return parseInt(text);
}

function generateIntCapped(slimit, possible="12345") {
  var text = "";
  for( var i=0; i < slimit; i++ )
      text += possible.charAt(Math.floor(Math.random() * possible.length));
  return parseInt(text);
}

function generateDate(startHour=0, endHour=23) {
  var epoch = parseInt(generateInt(1,"01").toString() + generateInt(1,"01234657").toString() + generateInt(8).toString()) * 1000
  var date = new Date(epoch);
  var hour = startHour + Math.random() * (endHour - startHour) | 0;
  date.setHours(hour);
  return date;
}

function generateTFalse() {
  return ((Math.floor((Math.random() * 2) + 1) % 2) == 0);
}

db.getSiblingDB('test').createCollection('collection02', { collation: { locale: "es@collation=search" } })

var x = 1
var total = 500000
var print_progress = 5000
var bulk_collection01 = db.getSiblingDB('test').getCollection('collection01').initializeUnorderedBulkOp()
var bulk_collection02 = db.getSiblingDB('test').getCollection('collection02').initializeUnorderedBulkOp()

print("Datetime: " + JSON.stringify(new Date()) + ". Start: " + x + ". Total: " + total)
for (x = 1; x <= total; x++ ) {
  var mode = 'bulk'
  var name = generateStringSpecial(4)
  var lastname = generateStringSpecial(4)
  var birthdate = generateDate()
  var age = generateInt(2)
  var company = generateStringSpecial(5)
  var receive_sms = generateTFalse()
  var myUUID4 = new BinData(4, generateStringSpecial(32))
  var bindata0 = new BinData(0, generateStringSpecial(32))
  var bindata2 = new BinData(2, generateStringSpecial(32))
  var bindata3 = new BinData(3, generateStringSpecial(32))
  var self_bio = generateStringSpecial(1024)
  var create_date = new Date()

  bulk_collection02.insert( {'mode': mode, 'name' : name, 'lastname' : lastname, 'birthdate' : birthdate, 'age': age, 'company' : company , 'receive_sms': receive_sms, 'uuid4': myUUID4, 'bindata0': bindata0 ,'bindata2': bindata2 ,'bindata3': bindata3 , 'self_bio' :self_bio, 'create_date': create_date } );

  if (x % 2 == 0){
    bulk_collection01.insert( {'mode': mode, 'name' : name, 'lastname' : lastname, 'birthdate' : birthdate, 'age': age, 'company' : company , 'receive_sms': receive_sms, 'uuid4': myUUID4, 'bindata0': bindata0 ,'bindata2': bindata2 ,'bindata3': bindata3 , 'self_bio' :self_bio, 'create_date': create_date } );
  }

  if (x % print_progress == 0){
    bulk_collection01.execute()
    bulk_collection02.execute()
    print("Datetime: " + JSON.stringify(new Date()) + ". Progress (" + print_progress + "): " + x + ". Total: " + total)
    var bulk_collection01 = db.getSiblingDB('test').getCollection('collection01').initializeUnorderedBulkOp()
    var bulk_collection02 = db.getSiblingDB('test').getCollection('collection02').initializeUnorderedBulkOp()
  }
}
print("Datetime: " + JSON.stringify(new Date()) + ". End: " + (x - 1))
