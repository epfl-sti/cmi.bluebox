var assert = require("assert"),
    fs = require("fs"),
    path = require("path"),
    temp = require("temp"),
    _json = require("../model/_json.js");

if (! process.env.DEBUG) {
    temp.track();
}

it("Loads a dir-ful of JSON", function(done) {
    var testDir = temp.mkdirSync("tests_json");

    var objsDir = path.resolve(testDir, "objs");
    fs.mkdirSync(objsDir);
    fs.writeFileSync(path.resolve(objsDir, "config.json"),
        JSON.stringify({
            name: "ROOT_NAME",
            desc: "ROOT DESC"
        }));
    var subdir = path.resolve(objsDir, "foos");
    fs.mkdirSync(subdir);
    fs.mkdirSync(path.resolve(subdir, "RedHerring"));
    fs.writeFileSync(path.resolve(subdir, "RedHerring/config.jason"),
        "Not really JSON");
    fs.mkdirSync(path.resolve(subdir, "Foo1"));
    fs.writeFileSync(path.resolve(subdir, "Foo1/config.json"),
        JSON.stringify({
            name: "Foo1",
            desc: "Foo1",
            foo: "Bar"
        }));

    _json.loadAllConfigs(objsDir, function(result, err) {
        if (err) {
            return done(err);
        }
        assert.deepEqual(result, {
            name: "ROOT_NAME",
            desc: "ROOT DESC",
            foos: {
                Foo1: {
                    name: "Foo1",
                    desc: "Foo1",
                    foo: "Bar"
                }
            }
        });
        done();
    });
});

