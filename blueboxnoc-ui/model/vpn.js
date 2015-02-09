var VPN = module.exports = function() {

};

VPN.validName = function (value) {
    return value.match(/^[A-Za-z_0-9]+$/);
};
