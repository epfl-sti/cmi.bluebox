var USER = module.exports = function() {

};

USER.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("USERS names can only contain letters, underscores and digits");
    };
};

USER.sort = function (array, sortField, sortDir) {
    sortField = typeof sortField !== 'undefined' ? sortField : 'title';
    if (sortDir === 'ASC') {
        return array.sort(function (A, B) {
            return A[sortField] > B[sortField];
        });
    } else {
        return array.sort(function (A, B) {
            return A[sortField] < B[sortField];
        });
    }
};
