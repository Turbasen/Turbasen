//var mongodb = require('mongodb');
//
//server  = new mongodb.Server('127.0.0.1', 27017)
//db      = new mongodb.Db('ntb_07', server, {w:1});
//
//db.on('error', function(error, db) {
//  console.log('error', error);
//  cb.close();
//});
//
//db.open(function(err, db) {
//  console.log('fuck');
//  thisMethodDoesNotExists('foo', 'bar', 123);
//});
//

"use strict";

var cluster = require('cluster');

if (cluster.isMaster) {
  console.log('I am master');
  cluster.fork();

  cluster.on('disconnect', function(worker) {
    console.error('disconnect!');
    cluster.fork();
  });
} else {
  console.log('I am slave');

  var domain = require('domain');

  var d = domain.create();
  d.on('error', function(er) {
    console.error('error', er.stack);
    process.exit(0);
  });
  d.run(function() {
    var mongodb = require('mongodb');

    var replSet = new mongodb.ReplSet([
      new mongodb.Server('localhost', 27017, {})
      ,new mongodb.Server('localhost', 27018, {})
      ,new mongodb.Server('localhost', 27019, {})
    ]);

    var db = new mongodb.Db('ntb_07', replSet, {w:0});

    db.on('close', function(err, db) {
      console.log('close');
      process.exit(0);
    });

    process.on("uncaughtException", function(err) {
      console.log(err);
      pricess.exit(1);
    });

    db.on('error', function(err, db) {
      console.log(err);
      process.exit(1);
    });

    db.open(function(err, db) {
      err = new Error('foo');
      if (err) throw err;

      console.log('connected');
    
      try {
        foobar();
      } catch (e) {
        db.close();
        throw e
      }
    });
  });
}
