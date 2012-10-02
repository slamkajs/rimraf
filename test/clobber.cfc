/**
*
* @file  /home/likewise-open/UCADS/slamkajs/Sites/mkdirp/test/clobber.cfc
* @author  Justin Slamka
* @description Tests the ability to create a file and then prevent a directoryCreate() via the created file.
*/

component output="false" displayname="clobber test" extends="mxunit.framework.TestCase" {
	variables.path = new foundry.core.path();
	variables.fs = new foundry.core.fs();
	variables.console = new foundry.core.console();
	variables._ = new foundry.core.util().init();

	variables.ps = [ '', 'tmp' ];

	for (i = 0; i < 25; i++) {
	    dir = formatBaseN(int(rand() * (16^4)), 16).toString();
	    ps.append(dir);
	}

	variables.file = arrayToList(ps, '/');

	// a file in the way
	variables.inTheWay = arrayToList(ps.slice(1, 4), '/');


	public any function clobber_pre() {
	    console.error('about to write to ' & inTheWay);

	    fs.writeFile(inTheWay, 'I AM IN THE WAY.');

	    fs.stat(inTheWay, function (er, stat) {
	        assertTrue(structKeyExists(arguments, 'stat') && stat.isFile, 'should be file');
	    });
	}

	public any function clobber() {
	    var mkdirp = new mkdirp();

	   	for(i=1; i <= 2; i++) {
	   		console.log("Test run ##" & i);
		    mkdirp.mkdirp(file, 0755, function (err) {
		        assertTrue(structKeyExists(arguments, 'err'), "err should be defined.");
		        assertTrue((findNoCase("can't create directory", err.message) GT 0) ? true : false, "err.code should be ENOTDIR");
		    });
		}
	}

	public void function setUp() {    
		console.log("========START========");
	}
	public void function tearDown() {
		console.log("=========END=========");
	}
}