jest.mock('mongoose', () => ({
  connect: jest.fn(),
}));

const mongoose = require('mongoose');
const { connectToDatabase } = require('../lib/db');

describe('connectToDatabase', () => {
  const originalMongoUri = process.env.MONGO_URI;

  beforeAll(() => {
    process.env.MONGO_URI = 'mongodb://localhost:27017/gastosclaros-test';
  });

  afterAll(() => {
    if (originalMongoUri === undefined) {
      delete process.env.MONGO_URI;
    } else {
      process.env.MONGO_URI = originalMongoUri;
    }
  });

  test('shares an in-flight connection between concurrent requests', async () => {
    let resolveConnection;
    mongoose.connect.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveConnection = resolve;
        }),
    );

    const firstRequest = connectToDatabase();
    const secondRequest = connectToDatabase();

    expect(mongoose.connect).toHaveBeenCalledTimes(1);

    const connection = { readyState: 1 };
    resolveConnection({ connection });

    await expect(Promise.all([firstRequest, secondRequest])).resolves.toEqual([
      connection,
      connection,
    ]);
  });
});
