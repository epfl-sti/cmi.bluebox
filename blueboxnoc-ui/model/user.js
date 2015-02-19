var USER = module.exports;

/* TODO: de-bogosify */
USER.all = function(done) {
    done([
    //{name:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group: ["Foo", "Bar", "Baz"], desc:"detail of my first users"},
    // @todo check map function to get group in an array (https://github.com/marmelab/ng-admin/)
    {name:"user1", sciper:"100100", email:"foo.bar@epfl.ch", group:"aBlueBoxNoc_admins", desc:"detail of my first users"},
    {name:"user2", sciper:"200200", email:"james.kilroy@epfl.ch", group:"bBlueBoxNoc_admins", desc:"detail of my second users"},
    {name:"user3", sciper:"300300", email:"andre.roussimoff@epfl.ch", group:"cBlueBoxNoc_vncers", desc:"detail of my third users"}
]);
};

USER.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("USERS names can only contain letters, underscores and digits");
    };
};

