var json = require("./_json");

var VPN = module.exports;

VPN.primaryKey = {
    name: "name",
    validate: function (value) {
        if (! value.match(/^[A-Za-z_0-9]+$/)) {
            throw new Error("VPN names can only contain letters, underscores and digits");
        };
    }
};

/**
 * Return all VPNs asynchronously.
 *
 * @param done Called either as done(null, error) or like this:
 *   done([
 *   {name:"Foo", desc:"Foofoo", bbxs:["bboo", "bbar"], vncs:["vnc1"]},
 *   // ...
 *   ]);
 */
VPN.all = function(done) {
    json.asyncProcessVPNs(done, function(jsonTree) {
        var returned = [];
        Object.keys(jsonTree).forEach(function (k) {
            var vpnDesc = jsonTree[k];
            returned.push(vpnDesc);
            vpnDesc.bbxs = Object.keys(vpnDesc.bboxes);
            vpnDesc.vncs = Object.keys(vpnDesc.vncs);
        });
        return returned;
    });
};

