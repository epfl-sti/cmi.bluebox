var json = require("./_json");

var VNC = module.exports;

VNC.primaryKey = {
    name: "id"
};

VNC.perlControllerPackage = "EPFLSTI::BlueBox::VNCTarget";

/**
 * Return all Blue Boxes asynchronously.
 *
 * @param done Called either as done(null, error) or like this:
 *   done([
 *   {name:"vnc1", ip:"192.168.10.10", port:"5900", vpn:"Foo", desc:"detail of my first vnc"},
 *       // ...
 *   ]);
 */
VNC.all = function(done) {
    json.asyncProcessData(done, function(jsonTree) {
        var returned = [];
        Object.keys(jsonTree.vncs).forEach(function (k) {
            var vncDesc = jsonTree.vncs[k];
            returned.push(vncDesc);
        });
        return returned;
    });
};

VNC.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("VNC names can only contain letters, underscores and digits");
    };
};

VNC.isValidIpv4Addr = function (ip) {
    return /^(?=\d+\.\d+\.\d+\.\d+$)(?:(?:25[0-9]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.?){4}$/.test(ip);
};

VNC.isValidPort = function (port) {
    return /^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9][0-9]|6[0-4][0-9][0-9][0-9]|\d{2,4}|[1-9])$/.test(port);
};
