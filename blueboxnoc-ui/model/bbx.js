var BBX = module.exports = function() {

};

BBX.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("BBX names can only contain letters, underscores and digits");
    };
};
