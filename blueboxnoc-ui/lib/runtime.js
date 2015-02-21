/**
 * Info about the run-time environment
 */

var path = require("path"),
    fs = require("fs");

var isDocker;
module.exports.isDocker = function() {
    if (typeof isDocker === "undefined") {
        isDocker = fs.existsSync("/this_is_docker");
    }
    return isDocker;
};

var srcDir;
module.exports.srcDir = function() {
    if (! srcDir) {
        srcDir = path.resolve(__dirname, "../..");
    }
    return srcDir;
};

var srvDir;
module.exports.srvDir = function (opt_set) {
    if (opt_set) {
        // Let Perl know through an environment variable.
        srvDir = process.env.DOCKER_SRVDIR_FOR_TESTS = opt_set;
    } else if (! srvDir) {
        if (module.exports.isDocker()) {
            srvDir = "/srv";
        } else {
            srvDir = path.resolve(module.exports.srcDir(), "var");
        }
    }
    return srvDir;
};
