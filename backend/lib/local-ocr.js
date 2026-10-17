const sharp = require('sharp');
const { createWorker } = require('tesseract.js');
const { parseYapeText } = require('./yape-parser');

let cvPromise;
function openCv() {
  if (!cvPromise) cvPromise = Promise.resolve(require('@techstark/opencv-js'));
  return cvPromise;
}

async function preprocessImages(base64) {
  if (typeof base64 !== 'string') throw new Error('Imagen inválida.');
  const clean = base64.replace(/^data:image\/(?:png|jpeg|jpg|webp);base64,/, '');
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(clean) || clean.length > 7000000) {
    throw new Error('Imagen inválida o demasiado grande.');
  }
  const { data, info } = await sharp(Buffer.from(clean, 'base64'), { limitInputPixels: 16000000 })
    .rotate().resize({ width: 1400, height: 2800, fit: 'inside' })
    .ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const cv = await openCv();
  const source = cv.matFromArray(info.height, info.width, cv.CV_8UC4, data);
  const gray = new cv.Mat();
  const mask = new cv.Mat();
  const contours = new cv.MatVector();
  const hierarchy = new cv.Mat();
  let receipt;
  const binary = new cv.Mat();
  try {
    cv.cvtColor(source, gray, cv.COLOR_RGBA2GRAY);
    // Locate the bright receipt card and exclude the decorative purple banner.
    cv.threshold(gray, mask, 210, 255, cv.THRESH_BINARY);
    cv.findContours(mask, contours, hierarchy, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    let bounds;
    let largest = 0;
    for (let index = 0; index < contours.size(); index++) {
      const contour = contours.get(index);
      try {
        const area = cv.contourArea(contour);
        const rect = cv.boundingRect(contour);
        if (area > largest && area > info.width * info.height * .2 && rect.width > info.width * .6) {
          bounds = rect;
          largest = area;
        }
      } finally { contour.delete(); }
    }
    if (bounds) {
      const region = gray.roi(bounds);
      try { receipt = region.clone(); } finally { region.delete(); }
    } else { receipt = gray.clone(); }
    cv.GaussianBlur(receipt, binary, new cv.Size(3, 3), 0);
    cv.threshold(binary, binary, 0, 255, cv.THRESH_BINARY | cv.THRESH_OTSU);
    async function encode(mat) {
      return sharp(Buffer.from(mat.data), {
        raw: { width: mat.cols, height: mat.rows, channels: 1 },
      }).extend({ top: 20, bottom: 20, left: 20, right: 20, background: '#fff' }).png().toBuffer();
    }
    return { binary: await encode(binary), grayscale: await encode(receipt) };
  } finally {
    source.delete(); gray.delete(); mask.delete(); contours.delete(); hierarchy.delete();
    if (receipt) receipt.delete();
    binary.delete();
  }
}

async function createReceiptReader() {
  const worker = await createWorker('spa', 1, {
    langPath: require('@tesseract.js-data/spa').langPath,
    cachePath: '/tmp',
    workerPath: require.resolve('tesseract.js/src/worker-script/node/index.js'),
  });
  return {
    async read(image) {
      const processed = await preprocessImages(image);
      let lastError;
      // PSM 3 handles mixed font sizes; sparse text is a fallback for other layouts.
      for (const [mode, input] of [['3', processed.binary], ['11', processed.grayscale]]) {
        await worker.setParameters({ tessedit_pageseg_mode: mode, user_defined_dpi: '150' });
        const { data } = await worker.recognize(input);
        try { return parseYapeText(data.text); } catch (error) { lastError = error; }
      }
      throw lastError;
    },
    close: () => worker.terminate(),
  };
}
module.exports = { createReceiptReader, preprocess: async (image) => (await preprocessImages(image)).binary };
