
var GROUP = module.exports = function() {
};

// Groups data
// Should be linked to groups on http://groups.epfl.ch and used for authentication purpose.
/* TODO: de-bogosify */
GROUP.all = function() {
    return [
        {name:"BlueBoxNOC_Admins", id:"73347", group_email:"BlueBoxNOC_Admins@groupes.epfl.ch", desc:"Admin group of BlueBoxNOC"},
        {name:"BlueBoxNOC_VNCers", id:"73348", group_email:"BlueBoxNOC_VNCers@groupes.epfl.ch", desc:"VNCers group of BlueBOxNOC"}
    ];
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
