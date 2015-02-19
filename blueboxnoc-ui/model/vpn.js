var VPN = module.exports;

/* TODO: de-bogosify */
VPN.all = function(done) {
        done([
    {name:"Foo", desc:"Foofoo", bbxs:["bboo", "bbar"], vncs:["vnc1"]},
    {name:"Bar", desc:"Foobar", bbxs:["bboo2"], vncs:["vnc2"]},
    {name:"Bax", desc:"Foobaz", bbxs:["bbax"], vncs:["vnc1","vnc3"]},
    {name:"Bay", desc:"Foobay", bbxs:["bbay"], vncs:["vnc4"]},
    {name:"Baz", desc:"Foobaz", bbxs:["bbaz"], vncs:["vnc5"]}
]);
}

VPN.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("VPN names can only contain letters, underscores and digits");
    };
};

