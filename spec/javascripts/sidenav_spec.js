describe('sidenav', function() {
  it('expands and collapses subnavs', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', { className: 'has_submenu li_one' }),
        createDom('li', { className: 'has_submenu li_two' })
      ));

    Bookbinder.startSidenav(root);
    var li = root.querySelector('.li_two');
    clickEl(li);

    expect(li.className).toContain('expanded');

    clickEl(li);

    expect(li.className).not.toContain('expanded');
  });

  it('does not try to expand when there is no subnav', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', {})));

    Bookbinder.startSidenav(root);
    var li = root.querySelector('li');
    clickEl(li);

    expect(li.className).not.toContain('expanded');
  });

  it('expands and collapses nested subnavs', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', { className: 'has_submenu li_one' },
          createDom('ul', {},
            createDom('li', {className: 'has_submenu li_child'}))),
        createDom('li', { className: 'has_submenu li_two' })
      ));

    Bookbinder.startSidenav(root);
    var li = root.querySelector('.li_child');
    clickEl(li);

    expect(li.className).toContain('expanded');

    clickEl(li);

    expect(li.className).not.toContain('expanded');
  });

  it('highlights the active page', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', {},
          createDom('a', { href: '/foo/bar/baz.html'})),
        createDom('li', {},
          createDom('a', { href: '/foo/bir/biz.html'})),
        createDom('li', {},
          createDom('a', { href: '/fob/bar/baz.html'})),
        createDom('li', {},
          createDom('a', { href: '/bar/baz.html'}))
      ));

    Bookbinder.startSidenav(root, '/fob/bar/baz.html');

    expect(root.querySelectorAll('a')[2].className).toContain('active');
  });

  it('ignores the path if it is not in the subnav', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', {},
          createDom('a', { href: '/foo/bar/baz.html'})),
        createDom('li', {},
          createDom('a', { href: '/foo/bir/biz.html'}))
      ));

    Bookbinder.startSidenav(root, '/fob/bar/baz.html');

    expect(root.querySelector('a.active')).toBeNull();
  });

  it('expands the parent element when the current path is nested', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', {className: 'has_submenu li_collapsed'}),
        createDom('li', {className: 'has_submenu li_grandparent'},
          createDom('a', {href: '/foo/bar/baz.html'}),
          createDom('ul', {},
            createDom('li', {className: 'has_submenu li_parent'},
              createDom('a', {href: '/bar/baz.html'}),
              createDom('ul', {},
                createDom('li', {},
                  createDom('a', {href: '/bar/foo/baz.html'}))
              ))))));


    Bookbinder.startSidenav(root, '/bar/foo/baz.html');
    expect(root.querySelector('.li_grandparent').className).toContain('expanded');
    expect(root.querySelector('.li_parent').className).toContain('expanded');

    expect(root.querySelector('.li_collapsed').className).not.toContain('expanded');
  });

  it('scrolls the sidenav to the active link', function() {
    var root = createDom('div', {},
      createDom('ul', {},
        createDom('li', {className: 'has_submenu li_collapsed'}),
        createDom('li', {className: 'has_submenu li_grandparent'},
          createDom('a', {href: '/foo/bar/baz.html'}),
          createDom('ul', {},
            createDom('li', {className: 'has_submenu li_parent'},
              createDom('a', {href: '/bar/baz.html'}),
              createDom('ul', {},
                createDom('li', {}),
                createDom('li', {}),
                createDom('li', {}),
                createDom('li', {}),
                createDom('li', {},
                  createDom('a', {href: '/bar/foo/baz.html'}))
              ))))));

    Bookbinder.startSidenav(root, '/bar/foo/baz.html');
  });
});
