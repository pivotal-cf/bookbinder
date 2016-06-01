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

function clickEl(el) {
  var event = document.createEvent('MouseEvent');
  event.initMouseEvent(
    'click',
    true, // bubble
    true, // cancelable
    window,
    null,
    0, 0, 0, 0, // coordinates
    false, false, false, false, // modifier keys
    0, // left
    null
  );

  el.dispatchEvent(event);
}
