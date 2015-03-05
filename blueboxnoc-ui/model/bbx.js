var json = require("./_json");

var BBX = module.exports;

BBX.primaryKey = {
    name: "name",
    validate: function (value) {
        if (! value.match(/^[A-Za-z_0-9]+$/)) {
            throw new Error("BBX names can only contain letters, underscores and digits");
        };
    }
};

BBX.perlControllerPackage = "EPFLSTI::BlueBox::BlueBox";

/**
 * Return all Blue Boxes asynchronously.
 *
 * @param done Called either as done(null, error) or like this:
 *   done([
 *   {name:"bboo", vpn:"Foo", desc:"Booboo", lastKnownIP:"128.178.100.100", status:"INIT"},
 *   // ...
 *   ]);
 */
BBX.all = function(done) {
    json.asyncProcessData(done, function(jsonTree) {
        var returned = [];
        Object.keys(jsonTree.bboxes).forEach(function (k) {
            var bboxDesc = jsonTree.bboxes[k];
            returned.push(bboxDesc);
        });
        return returned;
    });
};
