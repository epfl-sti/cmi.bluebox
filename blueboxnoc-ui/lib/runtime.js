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
module.exports.srvDir = function () {
    if (! srvDir) {
        if (module.exports.isDocker()) {
            srvDir = "/srv";
        } else {
            srvDir = path.resolve(module.exports.srcDir(), "var");
        }
    }
    return srvDir;
};
