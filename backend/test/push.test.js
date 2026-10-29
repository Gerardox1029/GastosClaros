const { validateSubscription } = require('../lib/push');

test('accepts browser push endpoints and rejects arbitrary servers', () => {
  const keys = { p256dh: 'key', auth: 'auth' };
  expect(validateSubscription({ endpoint: 'https://fcm.googleapis.com/fcm/send/example', keys })).toBe(true);
  expect(validateSubscription({ endpoint: 'https://web.push.apple.com/Q123', keys })).toBe(true);
  expect(validateSubscription({ endpoint: 'https://example.com/collect', keys })).toBe(false);
  expect(validateSubscription({ endpoint: 'http://fcm.googleapis.com/fcm/send/example', keys })).toBe(false);
});
