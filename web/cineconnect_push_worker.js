self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('push', event => {
  event.waitUntil((async () => {
    let data;
    try { data = event.data.json(); } catch (_) { return; }
    await self.registration.showNotification(data.title || 'CineConnect', {
      body: data.body || '', icon: '/icons/Icon-192.png', tag: data.tag,
      data: {url: '/#/notifications'}
    });
    if (data.receipt) {
      await fetch('/api/v1/push/receipts/' + encodeURIComponent(data.receipt), {method: 'POST'}).catch(() => {});
    }
  })());
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(self.clients.openWindow('/#/notifications'));
});
