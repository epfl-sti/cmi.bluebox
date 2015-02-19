var VPN = module.exports;

/* TODO: de-bogosify */
VPN.all = function(done) {
        done([
    {name:"Foo", desc:"Foofoo", bbxs:["bboo", "bbar"]},
    {name:"Bar", desc:"Foobar", bbxs:["bboo2"]},
    {name:"Bax", desc:"Foobaz", bbxs:["bbax"]},
    {name:"Bay", desc:"Foobay", bbxs:["bbay"]},
    {name:"Baz", desc:"Foobaz", bbxs:["bbaz"]}
]);
}

VPN.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("VPN names can only contain letters, underscores and digits");
    };
};

