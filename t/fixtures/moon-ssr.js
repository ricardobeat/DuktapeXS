'use strict';

var VOID_ELEMENTS = ['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr'];

var renderNode = function renderNode(node) {
  var html = "";
  if (node.type === "#text") {
    // Text
    html += node.val;
  } else if (node.meta.component !== undefined) {
    // Component
    var componentInstance = new node.meta.component.CTor();
    html += renderNode(componentInstance.render());
  } else {
    // Normal HTML
    html += '<' + node.type + ' ';
    var attrs = node.props.attrs;

    for (var prop in attrs) {
      html += prop + '=' + JSON.stringify(attrs[prop]) + ' ';
    }

    html = html.slice(0, -1);
    html += ">";

    for (var i = 0; i < node.children.length; i++) {
      html += renderNode(node.children[i]);
    }

    if (VOID_ELEMENTS.indexOf(node.type) === -1) {
      html += '</' + node.type + '>';
    } else {
      html = html.slice(0, -1) + "/>";
    }
  }

  return html;
};

var renderToString = function renderToString(instance) {
  var options = instance.$options;
  var render = options.render;

  if (render === undefined) {
    instance.$render = Moon.compile(options.template);
  }

  return renderNode(instance.render());
};

module.exports = {
  renderToString: renderToString
};
