module.exports.VPN = require("./vpn");
module.exports.BBox = require("./bbx");
module.exports.User = require("./user");
module.exports.Group = require("./group");
module.exports.VNCTarget = require("./vnc");
module.exports.Status = require("./status");


/**
 * Cut the results' array for pagination
 * @param array The results' array
 * @param page The current page (from query string _page param)
 * @param perPage Number of results per page (from query string _perPage param, set in view)
 * @return sliced array
 */
module.exports.paginate = function (array, page, perPage) {
    offset = (page -1) * perPage ;
    //console.log(" - Pagination: length="+array.length+" page="+page+" perPage="+perPage+" offset="+offset);
    return(array.slice(offset, offset+Number(perPage)));
};

/**
 * Sort the results
 * @param array The results' array
 * @param sortField The field to sort with (from query string _sortField param)
 * @param sortDir ASC or DESC (from query string _sortDir param)
 * @return sorted array
 */
module.exports.sort = function (array, sortField, sortDir) {
    sortField = typeof sortField !== 'undefined' ? sortField : 'name';
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
