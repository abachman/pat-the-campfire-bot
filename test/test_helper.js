(function() {
  var UnitTest;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  UnitTest = (function() {
    function UnitTest() {}
    UnitTest.prototype.run = function() {
      return _.each(_.functions(this), __bind(function(func) {
        if (/^test_/.test(func)) {
          console.log("running " + func);
          try {
            return this[func]();
          } catch (e) {
            return console.error("MAJOR MALFUNCTION!");
          }
        }
      }, this));
    };
    UnitTest.prototype.assert = function(truth) {
      var err;
      if (truth) {
        return console.log('.');
      } else {
        err = new Error();
        console.log('expected value to be true');
        return console.log(err.stack);
      }
    };
    return UnitTest;
  })();
  module.exports = {
    UnitTest: UnitTest
  };
}).call(this);
