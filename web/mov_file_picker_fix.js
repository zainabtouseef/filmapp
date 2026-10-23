// Flutter file_picker's web extension filter can include leading spaces.
// Normalize it before Safari opens the native chooser and expose QuickTime.
(() => {
  const originalClick = HTMLInputElement.prototype.click;

  HTMLInputElement.prototype.click = function (...args) {
    if (this.type === 'file' && this.accept) {
      const entries = this.accept
        .split(',')
        .map((entry) => entry.trim())
        .filter(Boolean);
      const names = new Set(entries.map((entry) => entry.toLowerCase()));
      if (names.has('.mp4') || names.has('.mov')) {
        if (!names.has('.mov')) entries.push('.mov');
        if (!names.has('video/quicktime')) entries.push('video/quicktime');
        this.accept = entries.join(',');
      }
    }
    return originalClick.apply(this, args);
  };
})();
