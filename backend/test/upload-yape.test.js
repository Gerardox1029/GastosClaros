const { generateContentWithRetry } = require('../lib/gemini');

describe('generateContentWithRetry', () => {
  afterEach(() => {
    jest.useRealTimers();
  });

  test('retries temporary Gemini 503 errors', async () => {
    jest.useFakeTimers();
    const model = {
      generateContent: jest
        .fn()
        .mockRejectedValueOnce(Object.assign(new Error('Service unavailable'), {
          status: 503,
        }))
        .mockResolvedValue('extracted'),
    };

    const result = generateContentWithRetry(model, []);
    await jest.advanceTimersByTimeAsync(1000);

    await expect(result).resolves.toBe('extracted');
    expect(model.generateContent).toHaveBeenCalledTimes(2);
  });

  test('does not retry permanent Gemini errors', async () => {
    const error = Object.assign(new Error('Not found'), { status: 404 });
    const model = {
      generateContent: jest.fn().mockRejectedValue(error),
    };

    await expect(generateContentWithRetry(model, [])).rejects.toBe(error);
    expect(model.generateContent).toHaveBeenCalledTimes(1);
  });
});
