(function() {
  var isExpanded = /\bexpanded\b/;

  function openSubmenu(e) {
    var el = e.srcElement;
    if (isExpanded.test(el.className)) {
      el.className = el.className.replace(isExpanded, '');
    } else {
      el.className += ' expanded';
    }
    e.stopPropagation();
  }

  window.Bookbinder = {
    startSidenav: function(rootEl, currentPath) {
      var submenus = rootEl.querySelectorAll('.has_submenu');

      for (var i = 0; i < submenus.length; i++) {
        submenus[i].onclick = openSubmenu;
      }

      if (currentPath) {
        var currentLink = rootEl.querySelector('a[href="' + currentPath + '"]');
        if (currentLink) {
          currentLink.className += ' active';

          var hasSubmenu = /\bhas_submenu\b/;
          var subnavLocation = currentLink.parentNode;

          while(subnavLocation.parentNode !== rootEl) {
            subnavLocation = subnavLocation.parentNode;
            if (hasSubmenu.test(subnavLocation.className)) {
              subnavLocation.className += ' expanded';
            }
          }

          rootEl.scrollTop = currentLink.offsetTop - rootEl.offsetTop;
        }
      }
    },
    boot: function() {
      Bookbinder.startSidenav(document.querySelector('#sub-nav'), document.location.pathname);
    }
  };
})();
