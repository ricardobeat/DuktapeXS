
var ___stack = []

setTimeout = function setTimeout (fn) {
    ___stack.push(fn)
}

__flushTimers = function __flushTimers () {
    var fn
    while (fn = ___stack.shift()) fn()
}

Object.assign = function (target) {
    return Array.prototype.slice.call(arguments, 1).reduce(function (target, obj, i) {
        for (var key in obj) {
            if (obj.hasOwnProperty(key)) {
                target[key] = obj[key]
            }
        }
        return target;
    }, target);
};
