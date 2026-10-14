(function () {
  async function registration() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) {
      throw new Error('Push notifications are not supported by this browser.');
    }
    const result = await navigator.serviceWorker.register('/cineconnect_push_worker.js', {
      scope: '/cineconnect-push/', updateViaCache: 'none'
    });
    if (!result.active) {
      await new Promise((resolve, reject) => {
        const worker = result.installing || result.waiting;
        if (!worker) return reject(new Error('Push worker could not start.'));
        const timer = setTimeout(() => reject(new Error('Push worker activation timed out.')), 15000);
        worker.addEventListener('statechange', () => {
          if (worker.state === 'activated') { clearTimeout(timer); resolve(); }
          if (worker.state === 'redundant') { clearTimeout(timer); reject(new Error('Push worker activation failed.')); }
        });
      });
    }
    return result;
  }
  function bytes(value) {
    const decoded = atob(value.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - value.length % 4) % 4));
    return Uint8Array.from(decoded, c => c.charCodeAt(0));
  }
  async function deviceId(endpoint) {
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(endpoint));
    return 'web-' + Array.from(new Uint8Array(digest), v => v.toString(16).padStart(2, '0')).join('');
  }
  window.cinePushSupported = () => 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  window.cinePushSubscribed = async () => {
    if (!window.cinePushSupported()) return false;
    const worker = await navigator.serviceWorker.getRegistration('/cineconnect-push/');
    return Boolean(worker && await worker.pushManager.getSubscription());
  };
  window.cinePushRegister = async (publicKey) => {
    if (!window.cinePushSupported()) throw new Error('Push is unavailable in this browser.');
    if (await Notification.requestPermission() !== 'granted') throw new Error('Notification permission was not granted.');
    const worker = await registration();
    const subscription = await worker.pushManager.getSubscription() || await worker.pushManager.subscribe({
      userVisibleOnly: true, applicationServerKey: bytes(publicKey)
    });
    return JSON.stringify({platform: 'web', device_id: await deviceId(subscription.endpoint), subscription: subscription.toJSON(), enabled: true});
  };
  window.cinePushUnregister = async () => {
    const worker = await navigator.serviceWorker.getRegistration('/cineconnect-push/');
    const subscription = worker && await worker.pushManager.getSubscription();
    if (!subscription) return JSON.stringify({});
    const id = await deviceId(subscription.endpoint);
    await subscription.unsubscribe();
    return JSON.stringify({device_id: id, enabled: false});
  };
})();
