var BBX = module.exports;

/* TODO: de-bogosify */
BBX.all = function() {
    return [
    {name:"bboo", vpn:"Foo", desc:"Booboo"},
    {name:"bboo2", vpn:"Bar", desc:"Booboo2"},
    {name:"bbar", vpn:"Foo", desc:"Boobar2"},
    {name:"bbax", vpn:"Bax", desc:"Boobax"},
    {name:"bbay", vpn:"Bay", desc:"Boobay"},
    {name:"bbaz", vpn:"Baz", desc:"Boobaz"}
];
}

BBX.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("BBX names can only contain letters, underscores and digits");
    };
};

