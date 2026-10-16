const crypto = require('crypto');

const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16;

/**
 * Obtiene la clave de cifrado desde las variables de entorno.
 * La clave debe tener exactamente 32 caracteres (256 bits).
 */
function getEncryptionKey() {
  const key = process.env.ENCRYPTION_KEY;

  if (!key) {
    throw new Error('ENCRYPTION_KEY no está definida en las variables de entorno.');
  }

  // Asegurar que la clave tenga exactamente 32 bytes
  return crypto.createHash('sha256').update(key).digest();
}

/**
 * Cifra un texto plano con AES-256-CBC.
 * @param {string} text - Texto a cifrar.
 * @returns {string} - Texto cifrado en formato iv:encrypted (hex).
 */
function encrypt(text) {
  if (!text || typeof text !== 'string') return text;

  const key = getEncryptionKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  // Formato: iv:encrypted (ambos en hex)
  return `${iv.toString('hex')}:${encrypted}`;
}

/**
 * Descifra un texto cifrado con AES-256-CBC.
 * @param {string} encryptedText - Texto cifrado en formato iv:encrypted (hex).
 * @returns {string} - Texto descifrado.
 */
function decrypt(encryptedText) {
  if (!encryptedText || typeof encryptedText !== 'string' || !encryptedText.includes(':')) {
    return encryptedText;
  }

  const key = getEncryptionKey();
  const parts = encryptedText.split(':');
  const iv = Buffer.from(parts[0], 'hex');
  const encrypted = parts[1];

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}

/**
 * Cifra los campos sensibles de un documento antes de guardar.
 * @param {Object} doc - Documento con campos nombre y descripcion.
 * @returns {Object} - Documento con campos cifrados.
 */
function encryptDocument(doc) {
  const encrypted = { ...doc };

  if (encrypted.nombre) {
    encrypted.nombre = encrypt(encrypted.nombre);
  }
  if (encrypted.descripcion) {
    encrypted.descripcion = encrypt(encrypted.descripcion);
  }

  return encrypted;
}

/**
 * Descifra los campos sensibles de un documento después de leer.
 * @param {Object} doc - Documento con campos cifrados.
 * @returns {Object} - Documento con campos descifrados.
 */
function decryptDocument(doc) {
  if (!doc) return doc;

  const decrypted = doc.toObject ? doc.toObject() : { ...doc };

  if (decrypted.nombre) {
    decrypted.nombre = decrypt(decrypted.nombre);
  }
  if (decrypted.descripcion) {
    decrypted.descripcion = decrypt(decrypted.descripcion);
  }

  return decrypted;
}

module.exports = { encrypt, decrypt, encryptDocument, decryptDocument };
