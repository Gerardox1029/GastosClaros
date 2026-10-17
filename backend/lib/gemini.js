async function generateContentWithRetry(model, content) {
  for (let attempt = 1; attempt <= 3; attempt++) {
    try { return await model.generateContent(content); }
    catch (error) {
      if (![429, 503].includes(Number(error.status ?? error.statusCode)) || attempt === 3) throw error;
      await new Promise((resolve) => setTimeout(resolve, attempt * 1000));
    }
  }
}
module.exports = { generateContentWithRetry };
