const { authFailure, sessionRevision } = require('../../lib/auth');
const { pushConfigured, validateSubscription, subscriptionId, subscriptions } = require('../../lib/push');
const { reply } = require('../../lib/http');

exports.handler = async (event) => {
  const denied = authFailure(event);
  if (denied) return denied;
  if (!['PUT', 'DELETE'].includes(event.httpMethod)) return reply(405, { error: 'Use PUT o DELETE.' });
  if (!pushConfigured()) return reply(503, { error: 'Configura las claves VAPID en Netlify.' });
  let body;
  try { body = JSON.parse(event.body); } catch { return reply(400, { error: 'JSON inválido.' }); }
  if (!validateSubscription(body?.subscription)) return reply(400, { error: 'Suscripción inválida.' });
  try {
    const collection = await subscriptions();
    await collection.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });
    const id = subscriptionId(body.subscription.endpoint);
    if (event.httpMethod === 'DELETE') {
      await collection.deleteOne({ _id: id });
    } else {
      await collection.updateOne({ _id: id }, { $set: {
        endpoint: body.subscription.endpoint,
        keys: { p256dh: body.subscription.keys.p256dh, auth: body.subscription.keys.auth },
        updatedAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        revision: sessionRevision(),
      } }, { upsert: true });
    }
    return reply(200, { success: true });
  } catch (error) {
    console.error('[push-subscription]', error.message);
    return reply(503, { error: 'No se pudo registrar el dispositivo.' });
  }
};
