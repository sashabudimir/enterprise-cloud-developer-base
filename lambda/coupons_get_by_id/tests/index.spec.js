const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');
const send = jest.spyOn(DynamoDBDocumentClient.prototype, 'send');
const { handler } = require('../index');
const sample = require('../../../samples/t2_coupons_get_by_id_response.json');
const event = { httpMethod: 'GET', pathParameters: { id: sample.coupon_id } };

beforeEach(() => { send.mockReset(); });
afterAll(() => { send.mockRestore(); });

test('reads the requested coupon from DynamoDB and matches the supplied sample', async () => {
  send.mockResolvedValue({ Item: sample });
  const response = await handler(event);
  expect(response.statusCode).toBe(200);
  expect(response.headers['Content-Type']).toBe('application/json');
  expect(JSON.parse(response.body)).toEqual(sample);
  expect(send).toHaveBeenCalledTimes(1);
  expect(send.mock.calls[0][0]).toBeInstanceOf(GetCommand);
  expect(send.mock.calls[0][0].input).toEqual({
    TableName: 'coupons', Key: { coupon_id: sample.coupon_id }, ConsistentRead: false
  });
});

test.each([undefined, {}, { pathParameters: {} }, { pathParameters: { id: ' ' } }])(
  'returns 400 for a missing id without contacting DynamoDB: %p', async input => {
    expect((await handler(input)).statusCode).toBe(400);
    expect(send).not.toHaveBeenCalled();
  });

test('returns 404 when DynamoDB has no matching coupon', async () => {
  send.mockResolvedValue({});
  expect((await handler(event)).statusCode).toBe(404);
});

test('handles an external DynamoDB failure without exposing internal details', async () => {
  const log = jest.spyOn(console, 'error').mockImplementation(() => {});
  send.mockRejectedValue(new Error('private service details'));
  const response = await handler(event);
  expect(response.statusCode).toBe(500);
  expect(response.body).not.toContain('private service details');
  log.mockRestore();
});
