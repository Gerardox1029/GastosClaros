const sharp = require('sharp');
const { createWorker } = require('tesseract.js');
const { parseYapeText } = require('./yape-parser');

let cvPromise;
function openCv() {
  if (!cvPromise) cvPromise = Promise.resolve(require('@techstark/opencv-js'));
  return cvPromise;
}

async function preprocess(base64) {
  if (typeof base64 !== 'string') throw new Error('Imagen inválida.');
  const clean = base64.replace(/^data:image\/(?:png|jpeg|jpg|webp);base64,/, '');
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(clean) || clean.length > 7000000) throw new Error('Imagen inválida o demasiado grande.');
  const buffer = Buffer.from(clean, 'base64');
  const { data, info } = await sharp(buffer, { limitInputPixels: 16000000 })
    .rotate().resize({ width: 1600, height: 3000, fit: 'inside', withoutEnlargement: false }).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const cv = await openCv();
  const source = cv.matFromArray(info.height, info.width, cv.CV_8UC4, data);
  const gray = new cv.Mat();
  const binary = new cv.Mat();
  try {
    cv.cvtColor(source, gray, cv.COLOR_RGBA2GRAY);
    cv.GaussianBlur(gray, binary, new cv.Size(3, 3), 0);
    cv.threshold(binary, binary, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
    return await sharp(Buffer.from(binary.data), { raw: { width: binary.cols, height: binary.rows, channels: 1 } }).png().toBuffer();
  } finally { source.delete(); gray.delete(); binary.delete(); }
}

async function createReceiptReader() {
  const worker = await createWorker('spa', 1, {
    langPath: require('@tesseract.js-data/spa').langPath,
    cachePath: '/tmp',
    workerPath: require.resolve('tesseract.js/src/worker-script/node/index.js'),
  });
  await worker.setParameters({ tessedit_pageseg_mode: '6', user_defined_dpi: '150' });
  return {
    async read(image) {
      const processed = await preprocess(image);
      const { data } = await worker.recognize(processed);
      return parseYapeText(data.text);
    },
    close: () => worker.terminate(),
  };
}
module.exports = { createReceiptReader, preprocess };
