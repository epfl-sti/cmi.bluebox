var STATUS = module.exports;

/* TODO: de-bogosify */
STATUS.all = function(done) {
        done([
            {name:"INIT", desc:""},
            {name:"DOWNLOADED", desc:""},
            {name:"NEEDS_UPDATE", desc:""},
            {name:"FAIL", desc:""},
            {name:"ACTIVE", desc:""}
        ]);
};

