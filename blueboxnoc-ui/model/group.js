
var GROUP = module.exports = function() {
};

GROUP.sort = function (array, sortField, sortDir) {
    sortField = typeof sortField !== 'undefined' ? sortField : 'groupname';
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
