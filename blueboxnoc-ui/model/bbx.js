var BBX = module.exports = function() {

};

BBX.validName = function (value) {
    if (! value.match(/^[A-Za-z_0-9]+$/)) {
        throw new Error("BBX names can only contain letters, underscores and digits");
    };
};

BBX.sort = function (array, sortField, sortDir) {
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