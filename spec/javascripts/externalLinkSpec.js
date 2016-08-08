describe('external links', function() {
  it('opens an external link in a new window when clicked', function() {
    var event = clickEvent({ mouseButton: 0 });

    expect(Bookbinder.needsNewWindow(event, 'http://other.example.com/foo', 'thing.example.com')).toBe(true);
  });

  it('opens an SSL external link in a new window when clicked', function() {
    var event = clickEvent({ mouseButton: 0 });

    expect(Bookbinder.needsNewWindow(event, 'https://other.example.com/foo', 'thing.example.com')).toBe(true);
  });

  it('does not open a new window for a link to the current domain', function() {
    var event = clickEvent({ mouseButton: 0 });

    expect(Bookbinder.needsNewWindow(event, 'https://thing.example.com/foo', 'thing.example.com')).toBe(false);
  });

  it('does not open a new window for an external link when the user uses a non-primary mouse button', function() {
    var event = clickEvent({ mouseButton: 2342834 });

    expect(Bookbinder.needsNewWindow(event, 'https://other.example.com/foo', 'thing.example.com')).toBe(false);
  });

  it('does not open a new window for an external link when the user is holding shift', function() {
    var event = clickEvent({ mouseButton: 0, shiftKey: true });

    expect(Bookbinder.needsNewWindow(event, 'https://other.example.com/foo', 'thing.example.com')).toBe(false);
  });

  it('does not open a new window for an external link when the user is holding ctrl', function() {
    var event = clickEvent({ mouseButton: 0, ctrlKey: true });

    expect(Bookbinder.needsNewWindow(event, 'https://other.example.com/foo', 'thing.example.com')).toBe(false);
  });

  it('does not open a new window for an external link when the user is holding alt', function() {
    var event = clickEvent({ mouseButton: 0, altKey: true });

    expect(Bookbinder.needsNewWindow(event, 'https://other.example.com/foo', 'thing.example.com')).toBe(false);
  });

  it('does not open a new window for an external link when the user is holding meta', function() {
    var event = clickEvent({ mouseButton: 0, metaKey: true });

    expect(Bookbinder.needsNewWindow(event, 'https://other.example.com/foo', 'thing.example.com')).toBe(false);
  });
});