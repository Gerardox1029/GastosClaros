const { createHash } = require('crypto');
const webpush = require('web-push');
const { connectToDatabase } = require('./db');
const { sessionRevision } = require('./auth');

function pushConfigured() {
  return Boolean(process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY &&
    process.env.VAPID_SUBJECT);
}

function allowedEndpoint(endpoint) {
  try {
    const url = new URL(endpoint);
    const host = url.hostname;
    return url.protocol === 'https:' && !url.username && !url.password &&
      (host === 'fcm.googleapis.com' || host.endsWith('.push.services.mozilla.com') ||
       host === 'push.services.mozilla.com' || host.endsWith('.push.apple.com') ||
       host.endsWith('.notify.windows.com'));
  } catch { return false; }
}

function validateSubscription(value) {
  return value && typeof value.endpoint === 'string' && value.endpoint.length < 2048 &&
    allowedEndpoint(value.endpoint) && value.keys &&
    typeof value.keys.p256dh === 'string' && value.keys.p256dh.length < 512 &&
    typeof value.keys.auth === 'string' && value.keys.auth.length < 512;
}

function subscriptionId(endpoint) {
  return createHash('sha256').update(endpoint).digest('hex');
}

async function subscriptions() {
  const db = await connectToDatabase();
  return db.collection('gastosclaros_push_subscriptions');
}

async function sendSavedPush(type, amount, description) {
  if (!pushConfigured()) return;
  try {
    webpush.setVapidDetails(process.env.VAPID_SUBJECT,
      process.env.VAPID_PUBLIC_KEY, process.env.VAPID_PRIVATE_KEY);
    const collection = await subscriptions();
    const targets = await collection.find({
      expiresAt: { $gt: new Date() }, revision: sessionRevision(),
    }).limit(20).toArray();
    const sign = type === 'ingreso' ? '+' : '−';
    const shortDescription = String(description || '').trim().replace(/\s+/g, ' ').slice(0, 70);
    const payload = JSON.stringify({
      title: `${sign} S/ ${amount.toFixed(2)} · ${shortDescription}`,
      body: type === 'ingreso' ? 'Saldo registrado' : 'Gasto registrado',
      url: type === 'ingreso' ? '/?tab=saldo' : '/?tab=gastos',
      tag: `registro-${Date.now()}`,
    });
    await Promise.allSettled(targets.map(async (target) => {
      try {
        await webpush.sendNotification({ endpoint: target.endpoint, keys: target.keys },
          payload, { TTL: 86400, timeout: 3500 });
      } catch (error) {
        if ([404, 410].includes(error.statusCode)) await collection.deleteOne({ _id: target._id });
        else console.warn('[push] Delivery failed:', error.statusCode || error.message);
      }
    }));
  } catch (error) {
    console.warn('[push] Notification skipped:', error.message);
  }
}

module.exports = { pushConfigured, validateSubscription, subscriptionId, subscriptions, sendSavedPush };
