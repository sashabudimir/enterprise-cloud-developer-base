const { handler } = require('../index.js');
const expectedCoupons = { message: "Coupons API is working successfully" };

describe('Coupon list', () => {

  test('Returns the required success message for an API Gateway GET event', async () => {
    const event = {
      resource: '/coupons_poc', path: '/coupons_poc', httpMethod: 'GET',
      headers: {}, queryStringParameters: null, body: null,
      requestContext: { stage: 'local' }, isBase64Encoded: false
    };
    const response = await handler(event, {});
    expect(response.statusCode).toBe(200);
    expect(response.headers['Content-Type']).toBe('application/json');
    expect(typeof response.body).toBe('string');
    expect(JSON.parse(response.body)).toStrictEqual(expectedCoupons);
  });

  test('Returns a fresh serialized response on every invocation', async () => {
    const first = JSON.parse((await handler({}, {})).body);
    first.message = 'modified by client';
    expect(JSON.parse((await handler({}, {})).body)).toStrictEqual(expectedCoupons);
  });
});
