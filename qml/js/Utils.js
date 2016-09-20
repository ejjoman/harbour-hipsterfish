.pragma library

function getBestMatch(candidates, width, height, tryFindSquareImage) {
    var sorted = candidates.sort(function(a, b) { return (a.width - b.width) + (a.height - b.height) })

    var biggest;
    var best;

    var items = sorted.filter(function (item) {
        if (tryFindSquareImage)
            return item.width / item.height == 1

        return item.width / item.height != 1
    })

    var hadSquareImages = items.length > 0;

    if (!hadSquareImages)
        items = sorted;

    for(var idx in items) {
        var current = items[idx];

        if (!biggest || biggest.width < current.width || biggest.height < current.height)
            biggest = current;

        if (!best && current.width >= width && current.height >= height)
            best = current;
    }

    return best ? best : biggest;
}

function addMissingProperties(obj, properties) {
    if (typeof obj === 'object') {
        for (var p in properties) {
            if (!obj.hasOwnProperty(p))
                obj[p] = properties[p];

            if (properties[p] !== null && properties[p] !== undefined && typeof properties[p] === 'object' && Object.keys(properties[p]).length > 0)
                obj[p] = addMissingProperties(obj[p], properties[p]);
        }
    }

    return obj;
}

function abbreviateNumber(number, decPlaces) {
    // 2 decimal places => 100, 3 => 1000, etc
    decPlaces = Math.pow(10,decPlaces);

    // Enumerate number abbreviations
    var abbrev = [ "k", "M", "G", "T" ];

    // Go through the array backwards, so we do the largest first
    for (var i=abbrev.length-1; i>=0; i--) {

        // Convert array index to "1000", "1000000", etc
        var size = Math.pow(10,(i+1)*3);

        // If the number is bigger or equal do the abbreviation
        if(size <= number) {
             // Here, we multiply by decPlaces, round, and then divide by decPlaces.
             // This gives us nice rounding to a particular decimal place.
             number = Math.round(number*decPlaces/size)/decPlaces;

             // Handle special case where we round up to the next abbreviation
             if((number == 1000) && (i < abbrev.length - 1)) {
                 number = 1;
                 i++;
             }

             // Add the letter for the abbreviation
             number += abbrev[i];

             // We are done... stop
             break;
        }
    }

    return number;
}

function findParentWithProperty(item, propertyName) {
    var parentItem = item.parent
    while (parentItem) {
        if (parentItem.hasOwnProperty(propertyName)) {
            return parentItem
        }
        parentItem = parentItem.parent
    }
    return null
}

function findPageStack(item) {
    return findParentWithProperty(item, '_pageStackIndicator')
}

function findPage(item) {
    return findParentWithProperty(item, '__silica_page')
}
