// import.js

var yaml = require("js-yaml")
  , fs = require("fs")
  , mongodb = require("mongodb")
  , assert = require("assert")

var url = "mongodb://localhost/asl"
  , db
  , coll
mongodb.MongoClient.connect(url, function (err, database) {
  assert.equal(null, err)
  db = database
  coll = db.collection("signs")
  main()
})

function main() {
  var doc = ""
  try {
    doc = yaml.safeLoad(fs.readFileSync("signs.yml", "utf8"))
  } catch (e) {
    console.log(e)
    assert.equal(1, 0)
  }

  var signs = doc.signs

  coll.insertMany(signs, function(err, r) {
    assert.equal(null, err)
    console.log("inserted %d signs", r.insertedCount)
    db.close()
  })
}
