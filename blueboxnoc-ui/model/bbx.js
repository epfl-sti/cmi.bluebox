var BBX = module.exports;

/* TODO: de-bogosify */
BBX.all = function() {
    return [
    {name:"bboo", vpn:"Foo", desc:"Booboo", status:"INIT"},
    {name:"bboo2", vpn:"Bar", desc:"Booboo2", status:"INIT"},
    {name:"bbar", vpn:"Foo", desc:"Boobar2", status:"DOWNLOADED"},
    {name:"bbax", vpn:"Bax", desc:"Boobax", status:"NEEDS_UPDATE"},
    {name:"bbay", vpn:"Bay", desc:"Boobay", status:"FAIL"},
    {name:"bbaz", vpn:"Baz", desc:"Boobaz", status:"ACTIVE"}
];
}

BBX.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("BBX names can only contain letters, underscores and digits");
    };
};

