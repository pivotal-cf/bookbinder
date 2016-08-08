function createDom(tagName, attributes, children) {
  var el = document.createElement(tagName);

  for (var i = 2; i < arguments.length; i++) {
    var child = arguments[i];

    if (typeof child === 'string') {
      el.appendChild(document.createTextNode(child));
    } else {
      if (child) {
        el.appendChild(child);
      }
    }
  }

  for (var attr in attributes) {
    if (attr == 'className') {
      el[attr] = attributes[attr];
    } else {
      el.setAttribute(attr, attributes[attr]);
    }
  }

  return el;
}

function clickEvent(options) {
  options = options || {};
  options.mouseButton = options.mouseButton || 0; // left
  options.ctrlKey = options.ctrlKey || false;
  options.shiftKey = options.shiftKey || false;
  options.altKey = options.altKey || false;
  options.metaKey = options.metaKey || false;

  var event = document.createEvent('MouseEvent');
  event.initMouseEvent(
    'click',
    true, // bubble
    true, // cancelable
    window,
    null,
    0, 0, 0, 0, // coordinates
    options.ctrlKey,
    options.altKey,
    options.shiftKey,
    options.metaKey,
    options.mouseButton,
    null
  );

  return event;
}

function clickEl(el) {
  el.dispatchEvent(clickEvent());
}
