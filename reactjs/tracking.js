// Simple button/action click logger
(function() {
  function logClick(e) {
    const target = e.target.closest('button, input[type="button"], input[type="submit"], [role="button"], a[role="button"], span[class="summary"], span[class="play-voice"], div[class*="react-grid-item"]');
    if (!target) return;
    console.log('[Button Clicked]', {
      tag: target.tagName.toLowerCase(),
      id: target.id || null,
      classes: target.className || null,
      text: target.innerText || target.value || null,
      timestamp: new Date().toISOString(),
      pageUrl: location.href
    });
  }

  document.addEventListener('click', logClick, true);
  console.log('Button click logger injected. All button clicks will be logged in console.');
})();
