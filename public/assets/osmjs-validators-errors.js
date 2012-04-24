// Generated by CoffeeScript 1.3.1
(function() {
  var JqueryValidatorErrorsControl;

  JqueryValidatorErrorsControl = (function() {

    JqueryValidatorErrorsControl.name = 'JqueryValidatorErrorsControl';

    function JqueryValidatorErrorsControl(elem, layer, options) {
      this.elem = elem;
      this.layer = layer;
      this.options = options != null ? options : {};
      this.errors = this.options.errors;
      this.update();
    }

    JqueryValidatorErrorsControl.prototype.update = function() {
      var error, _i, _len, _ref, _results;
      this.elem.html('');
      _ref = this.errors;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        error = _ref[_i];
        _results.push(this.elem.append(this.buildListItem(error)));
      }
      return _results;
    };

    JqueryValidatorErrorsControl.prototype.buildListItem = function(error) {
      var cb, childErr, li, ul, _i, _len, _ref,
        _this = this;
      ul = $('<ul />');
      _ref = error.children || [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        childErr = _ref[_i];
        ul.append(this.buildListItem(childErr));
      }
      cb = $('<input type="checkbox" />');
      cb.data('type', error.type);
      if (!(error.type && this.layer.disabledErrors.indexOf(error.type) >= 0)) {
        cb.attr('checked', 'checked');
      }
      cb.change(function() {
        var e, ee, type, _j, _len1, _ref1, _results;
        if (cb.attr('checked')) {
          ul.find('input').removeAttr('disabled');
        } else {
          ul.find('input').attr('disabled', 'true');
        }
        _ref1 = li.find('input');
        _results = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          e = _ref1[_j];
          ee = $(e);
          if (type = ee.data('type')) {
            if (!ee.attr('disabled') && ee.attr('checked')) {
              _results.push(_this.layer.enableError(type));
            } else {
              _results.push(_this.layer.disableError(type));
            }
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
      li = $('<li />');
      li.append(cb);
      li.append(error.name);
      li.append(ul);
      return li;
    };

    return JqueryValidatorErrorsControl;

  })();

  jQuery.fn.validatorErrorsControl = function(layer, options) {
    return this.each(function() {
      return new JqueryValidatorErrorsControl($(this), layer, options);
    });
  };

}).call(this);
