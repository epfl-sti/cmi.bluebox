var BBX = module.exports;

/* TODO: de-bogosify */
BBX.all = function() {
    return [
    {name:"bboo", vpn:"Foo", desc:"Booboo", lastKnownIP:"128.178.100.100", status:"INIT"},
    {name:"bboo2", vpn:"Bar", desc:"Booboo2", lastKnownIP:"128.178.100.200", status:"INIT"},
    {name:"bbar", vpn:"Foo", desc:"Boobar2", lastKnownIP:"128.178.200.100", status:"DOWNLOADED"},
    {name:"bbax", vpn:"Bax", desc:"Boobax", lastKnownIP:"128.178.200.200", status:"NEEDS_UPDATE"},
    {name:"bbay", vpn:"Bay", desc:"Boobay", lastKnownIP:"128.178.100.101", status:"FAIL"},
    {name:"bbaz", vpn:"Baz", desc:"Boobaz", lastKnownIP:"128.178.100.102", status:"ACTIVE"}
];
}

BBX.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("BBX names can only contain letters, underscores and digits");
    };
};

