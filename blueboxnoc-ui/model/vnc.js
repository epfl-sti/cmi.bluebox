var VNC = module.exports = function() {

};

VNC.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("VNC names can only contain letters, underscores and digits");
    };
};

VNC.sort = function (array, sortField, sortDir) {
    sortField = typeof sortField !== 'undefined' ? sortField : 'title';
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

VNC.isValidIpv4Addr = function (ip) {
    return /^(?=\d+\.\d+\.\d+\.\d+$)(?:(?:25[0-9]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.?){4}$/.test(ip);
};

VNC.isValidPort = function (port) {
    return /^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9][0-9]|6[0-4][0-9][0-9][0-9]|\d{2,4}|[1-9])$/.test(port);
};