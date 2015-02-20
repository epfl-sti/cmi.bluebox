/**
 * Support for models materialized in JSON classes
 */

var assert = require("assert"),
    path = require("path"),
    fs = require("fs"),
    readdirp = require("readdirp"),
    runtime = require("../lib/runtime");


module.exports.loadAllConfigs = function(dir, done) {
    var results = {};
    readdirp({ root: dir, fileFilter: 'config.json' })
        .on('warn', function (err) {
            console.error('loadAllConfigs: warning: ', err);
            // optionally call stream.destroy() here in order to abort and cause 'close' to be emitted
        })
        .on('error', function (err) {
            console.error('loadAllConfigs: fatal: ', err);
            done(null, err);
            done = undefined;  // Prevents double call
        })
        .on('end', function() {
            done(results);
            done = undefined;
        })
        .on('data', function (entry) {
            var insertInto = results;
            var pathElems = entry.path.split(path.sep);
            assert.equal(pathElems.pop(), "config.json");
            pathElems.forEach(function (pathElem) {
                insertInto[pathElem] = insertInto[pathElem] || {};
                insertInto = insertInto[pathElem];
            });
            var data = JSON.parse(fs.readFileSync(entry.fullPath));
            Object.keys(data).forEach(function (k) {
                insertInto[k] = data[k];
            })
        });
};

module.exports.asyncProcessAllVPNs = function(done, result_cb) {
    module.exports.loadAllConfigs(path.join(runtime.srvDir(), "vpn"), function(jsonTree, err) {
        if (err) {
            done(null, err);
        } else {
            try {
                done(result_cb(jsonTree));
            } catch (err) {
                done(null, err);
            }
        }
    });
};