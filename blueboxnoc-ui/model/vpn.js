var json = require("./_json");

var VPN = module.exports;

VPN.primaryKey = {
    name: "name",
    validate: function (value) {
        if (! value.match(/^[A-Za-z_0-9]+$/)) {
            throw new Error("VPN names can only contain letters, underscores and digits");
        }
    }
};

VPN.perlControllerPackage = "EPFLSTI::BlueBox::VPN";

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
    json.asyncProcessData(done, function(jsonTree) {
        var returned = [];
        Object.keys(jsonTree.vpns).forEach(function (k) {
            var vpnDesc = jsonTree.vpns[k];
            returned.push(vpnDesc);
            vpnDesc.bbxs = [];
            Object.keys(jsonTree.bboxes).forEach(function (j) {
                var bboxDesc = jsonTree.bboxes[j];
                if (bboxDesc.vpn == k) {
                    vpnDesc.bbxs.push(bboxDesc.name);
                }
            });
            vpnDesc.vncs = [];
            Object.keys(jsonTree.vncs).forEach(function (j) {
                var vncDesc = jsonTree.vncs[j];
                if (vncDesc.vpn == k) {
                    vpnDesc.vncs.push(vncDesc.id);
                }
            });
        });
        return returned;
    });
};

