var VNC = module.exports;

/* TODO: de-bogosify */
VNC.all = function() {
    return [
    {name:"vnc1", ip:"192.168.10.10", port:"5900", vpn:"Foo", desc:"detail of my first vnc", token:"jiy1Wiebo7fa6Taaweesh4nae"},
    {name:"vnc2", ip:"192.168.20.20", port:"5900", vpn:"Bar", desc:"detail of my second vnc", token:"queexahnohyahch3AhceiwooR"},
    {name:"vnc3", ip:"192.168.30.30", port:"5900", vpn:"Bax", desc:"detail of my third vnc", token:"Ahd7heeshoni8phanohB2Siey"},
    {name:"vnc4", ip:"192.168.40.40", port:"5901", vpn:"Bay", desc:"detail of my fourth vnc", token:"saeMohkaec7ax1aichohdoo6u"},
    {name:"vnc5", ip:"192.168.50.50", port:"5901", vpn:"Baz", desc:"detail of my fifth vnc", token:"ooJee6ohwaevooQuoSu3chahk"}
];
}

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
