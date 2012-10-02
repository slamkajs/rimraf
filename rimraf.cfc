component name="rimraf" extends="foundry.core" {
	variables.path = require("path");
	variables.fs = require("fs");
	variables.e = require("emitter");

	this['emitter'] = new foundry.core.emitter();
	variables.isWindows = (server.os.name CONTAINS "windows");

	// for EMFILE handling
	variables.timeout = 0;
	this['emfile_max'] = 1000;
	this['busytries_max'] = 3;

	public any function rmrf(p, cb) {
	  if (!structKeyExists(arguments,'cb')) console.log("No callback passed to rimraf()");

	  var busyTries = 0;

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

	  rimraf_(p,cb)
	}
	
	variables.rimraf_ = function(p, cb) {
	  fs.lstat(p, function (er, s) {
	    if (er) {
	      // already gone
	      if (er.code EQ "ENOENT") return cb();
	      // some other kind of error, permissions, etc.
	      return cb(er);
	    }

	    return rm_(p, s, false, cb);
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
		
		if(fileExists(s)) {
	 		fileInfo = getFileInfo(s);

	 		if(fileInfo.canWrite) return true;
		}
	}

	variables.rm_ = function(p, s, didWritableCheck, cb) {
	  if (!didWritableCheck && !writable(s)) {
	    // make file writable
	    // user/group/world, doesn't matter at this point
	    // since it's about to get nuked.
	    return fs.chmod(p, s.mode || 0222, function (er) {
	      if (er) return cb(er);
	      rm_(p, s, true, cb);
	    });
	  };

	  if (!s.isDirectory()) {
	    return fs.unlink(p, cb);
	  }

	  // directory
	  fs.readdir(p, function (er, files) {
	    if (er) return cb(er);
	    asyncForEach(files.map(function (f) {
	      return path.join(p, f);
	    }), function (file, cb) {
	      rimraf(file, cb);
	    }, function (er) {
	      if (er) return cb(er);
	      fs.rmdir(p, cb);
	    });
	  });
	}

	 variables.asyncForEach = function(list, fn, cb) {
	  if (!list.length) cb();
	  var c = list.length;
	  var errState = null;
	  list.forEach(function (item, i, list) {
	    fn(item, function (er) {
	      if (errState) return;
	      if (er) return cb(errState = er);
	      if (-- c EQ 0) return cb();
	    })
	  })
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

}