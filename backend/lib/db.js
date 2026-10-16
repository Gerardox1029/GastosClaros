const mongoose = require('mongoose');
require('dotenv').config();

let cachedDb = null;

/**
 * Conecta a MongoDB Atlas reutilizando la conexión en invocaciones warm.
 * Patrón de conexión cacheada para optimizar cold-start de Netlify Functions.
 */
async function connectToDatabase() {
  if (cachedDb && cachedDb.readyState === 1) {
    return cachedDb;
  }

  const uri = process.env.MONGO_URI;

  if (!uri) {
    throw new Error('MONGO_URI no está definida en las variables de entorno.');
  }

  try {
    const connection = await mongoose.connect(uri, {
      bufferCommands: false,
      maxPoolSize: 5,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    cachedDb = connection.connection;
    console.log('[MongoDB] Conexión establecida exitosamente.');
    return cachedDb;
  } catch (error) {
    console.error('[MongoDB] Error de conexión:', error.message);
    throw error;
  }
}

module.exports = { connectToDatabase };
