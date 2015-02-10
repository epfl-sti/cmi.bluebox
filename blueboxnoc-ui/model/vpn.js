var VPN = module.exports = function() {

};

VPN.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("VPN names can only contain letters, underscores and digits");
    };
};
