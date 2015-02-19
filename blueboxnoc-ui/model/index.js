module.exports.VPN = require("./vpn");
module.exports.BBox = require("./bbx");
module.exports.User = require("./user");
module.exports.Group = require("./group");
module.exports.VNCTarget = require("./vnc");
module.exports.Status = require("./status");

module.exports.sort = function (array, sortField, sortDir) {
    sortField = typeof sortField !== 'undefined' ? sortField : 'name';
    if (sortDir === 'ASC') {
        return array.sort(function (A, B) {
            return A[sortField] > B[sortField];
        });
    } else {
        return array.sort(function (A, B) {
            return A[sortField] < B[sortField];
        });
    }
};
