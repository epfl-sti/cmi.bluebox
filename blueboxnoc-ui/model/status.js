var STATUS = module.exports;

/* TODO: de-bogosify */
STATUS.all = function() {
        return  [
            {name:"INIT", desc:""},
            {name:"DOWNLOADED", desc:""},
            {name:"NEEDS_UPDATE", desc:""},
            {name:"FAIL", desc:""},
            {name:"ACTIVE", desc:""}
        ];
};

