component name="rimraf" extends="foundry.core" {
    variables.path = require("path");
    variables.fs = require("fs");
    variables.futil = createObject("java","org.apache.commons.io.FileUtils");
    variables._ = require("util").init();
    variables.console = require("console");

    variables.isWindows = (server.os.name CONTAINS "windows");

    // for EMFILE handling
    variables.timeout = 0;
    this['emfile_max'] = 1000;
    this['busytries_max'] = 3;

    public any function rmrf(p, cb) {
        if (!structKeyExists(arguments,'cb')) console.log("No callback passed to rimraf()");

        var busyTries = 0;
        var currFile = createObject("java", "java.io.File").init(p);

        var callB = function(er) {
            if (er) {
                if (er.code EQ "EBUSY" && busyTries < this.BUSYTRIES_MAX) {
                    busyTries++
                    var time = busyTries * 100
                    // try again, with the same exact callback as this one.
                    sleep(time);
                    rimraf_(p, callB);
                }

                // this one wont happen if graceful-fs is used.
                if (er.code EQ "EMFILE" && timeout < this.EMFILE_MAX) {
                    sleep(timeout++);
                    rimraf_(p, callB);
                }

                // already gone
                if (er.code EQ "ENOENT") er = null
            }

            timeout = 0
            cb(er)
        }

        rimraf_(currFile,cb);
    }
    
    variables.rimraf_ = function(p, cb) {
        fs.stat(p, function (er, s) {
            if (structKeyExists(arguments, 'er') && !_.isEmpty(er)) {
                // already gone
                if (er.errorCode EQ "ENOENT") return cb();

                // some other kind of error, permissions, etc.
                cb(er);
            }

            cb(rm_(p, s, false, cb));
        });
    };

    variables.myGid = function() {
      var g = process.getuid && process.getgid();
      myGid = function() { return g; }
      return g;
    };

    variables.myUid = function() {
      var u = process.getuid && process.getuid();
      myUid = function() { return u; }
      return u;
    }


    variables.writable = function(s) {
        var fileInfo = {};

        if(fileExists(s) || directoryExists(s)) {
            fileInfo = getFileInfo(s);

            if(fileInfo.canWrite) return false;
        }

        return false;
    }

    /**
    * 
    * @PARAM p Path of the file or directory
    * @PARAM s Stat info for path or directory
    * @PARAM didWritableCheck Boolean of if func didWritableCheck() was ran on dir/file
    * @PARAM cb Callback function for previous function
    */ 
    variables.rm_ = function(p, s, didWritableCheck, cb) {
        var directoryListing = "";

        if (!didWritableCheck && !writable(p)) {
            // make file writable
            // user/group/world, doesn't matter at this point
            // since it's about to get nuked.

            fs.chmod(p, 'rw', function (er) {
                if (er) return cb(er);
                    rm_(p, s, true, cb);
                });
        }

        // if (!s.isDirectory) {
        //     return fileDelete(p);
        // }

        // directory
        directoryListing = directoryList(absolute_path=expandPath("../" & p), recurse=true, listInfo="path");

        // asyncForEach(_map(directoryListing, function (f) {
        //  return path.join(p, f);
        // }), function (file, cb) {
        //  rmrf(file, cb);
        // }, function (er) {
        //  if (er) return cb(er);
        //  fs.rmdir(p, cb);
        // });
        try {
            //fs.rmdirSync(p, cb);
            futil.forceDelete(p)
        }
        catch(any err) {
            cb(err);
        }
        

        // fs.readdir(p, function (er, files) {
            
        // });
    }

     variables.asyncForEach = function(list, fn, cb) {
        // if (arrayLen(list) = 0) {
        //  cb();
        // }
        var c = arrayLen(list);
        var errState = "";

        for(i = 1; i <= c; i++) {
            fn(list[i], function(er) {
                if(_.isEmpty(errState)) return false;
                if(structKeyExists(arguments, 'er') && !_.isEmpty(er)) return cb(errState = er);
                if(-- c EQ 0) return cb();
            })
        }
        // list.forEach(function (item, i, list) {
        //  fn(item, function (er) {
        //      if (errState) return false;
        //      if (er) return cb(errState = er);
        //      if (-- c EQ 0) return cb();
        //  })
        // })
    }

    // this looks simpler, but it will fail with big directory trees,
    // or on slow stupid awful cygwin filesystems
    this.rimraf.sync = function(p) {
      try {
        var s = fs[lstatSync](p);
      } catch (er) {
        if (er.code EQ "ENOENT") return;
        throw er;
      }

      if (!writable(s)) {
        fs.chmodSync(p, s.mode || 0222);
      }

      if (!s.isDirectory()) return fs.unlinkSync(p);

      fs.readdirSync(p).forEach(function (f) {
        this.rimraf.sync(path.join(p, f));
      });

      fs.rmdirSync(p);
    };

    public array function _map(obj,iterator = _.identity, this = {}) {
    var result = [];

    if (isArray(arguments.obj)) {
      var index = 1;
      var resultIndex = 1;
      for (element in arguments.obj) {
        if (!arrayIsDefined(arguments.obj, index)) {
          index++;
          continue;
        }
        var local = {};
        local.tmp = iterator(element, index, arguments.obj, arguments.this);
        if (structKeyExists(local, "tmp")) {
          result[resultIndex] = local.tmp;
        }
        index++;
        resultIndex++;
      }
    }

    else if (isObject(arguments.obj) || isStruct(arguments.obj)) {
      var index = 1;
      for (key in arguments.obj) {
        var val = arguments.obj[key];
        var local = {};
        local.tmp = iterator(val, key, arguments.obj, arguments.this);
        if (structKeyExists(local, "tmp")) {
          result[index] = local.tmp;
        }
        index++;
      }
    }
    else {
      // query or something else? convert to array and recurse
      result = _map(toArray(arguments.obj), iterator, arguments.this);
    }

    return result;
  }

}