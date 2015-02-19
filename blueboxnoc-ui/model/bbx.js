var json = require("./_json");

var BBX = module.exports;

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
    json.asyncProcessVPNs(done, function(jsonTree) {
        var returned = [];
        Object.keys(jsonTree).forEach(function (k) {
            var vpnDesc = jsonTree[k];
            Object.keys(vpnDesc.bboxes).forEach(function (k) {
                var bboxDesc = vpnDesc.bboxes[k];
                returned.push(bboxDesc);
                bboxDesc.vpn = vpnDesc.name;
            });
        });
        return returned;
    });
};

BBX.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("BBX names can only contain letters, underscores and digits");
    };
};

