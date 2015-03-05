/**
 * Support for models materialized in JSON classes
 */

var assert = require("assert"),
    path = require("path"),
    fs = require("fs"),
    runtime = require("../lib/runtime");


module.exports.loadAllConfigs = function(dir, done) {
    done();
};

module.exports.asyncProcessData = function(done, result_cb) {
    try {
        var jsonTree = JSON.parse(fs.readFileSync(runtime.srvDir() + "/fleet_state.json"));
        process.nextTick(function () {
            done(result_cb(jsonTree));
        });
    } catch (err) {
        done(null, err);
    }
};