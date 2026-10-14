const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

test('legacy Flutter cache cleanup preserves browser push registration', async () => {
  const html = fs.readFileSync('web/index.html', 'utf8');
  const body = html.match(/const clearLegacyWebCache = async \(\) => \{([\s\S]*?)\n    \};/)[1];
  const removed = [], cleared = [];
  const registration = (file) => ({active: {scriptURL: `https://cine.example/${file}`}, unregister: async () => removed.push(file)});
  const context = {
    URL, console,
    navigator: {serviceWorker: {controller: null, getRegistrations: async () => [registration('flutter_service_worker.js'), registration('cineconnect_push_worker.js')]}},
    window: {caches: true},
    caches: {keys: async () => ['flutter-app-cache', 'other-app-cache'], delete: async (name) => cleared.push(name)},
  };
  vm.createContext(context);
  await vm.runInContext(`(async () => {${body}})()`, context);
  assert.deepEqual(removed, ['flutter_service_worker.js']);
  assert.deepEqual(cleared, ['flutter-app-cache']);
});
