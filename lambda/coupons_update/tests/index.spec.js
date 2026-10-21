const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const send = jest.spyOn(DynamoDBDocumentClient.prototype, 'send');
const { handler } = require('../index');
const sample = require('../../../samples/t2_coupons_get_by_id_response.json');
const event = body => ({ httpMethod: 'PUT', pathParameters: { id: sample.coupon_id }, body });

beforeEach(() => { send.mockReset(); });
afterAll(() => { send.mockRestore(); });

test('updates the requested fields and returns the saved coupon from DynamoDB', async () => {
  const saved = { ...sample, title: 'Updated title', coupon_code: 'NEWCODE' };
  send.mockResolvedValue({ Attributes: saved });
  const response = await handler(event(JSON.stringify({ title: saved.title, coupon_code: saved.coupon_code })));
  expect(response.statusCode).toBe(200);
  expect(response.headers['Content-Type']).toBe('application/json');
  expect(JSON.parse(response.body)).toEqual(saved);
  const command = send.mock.calls[0][0];
  expect(command).toBeInstanceOf(UpdateCommand);
  expect(command.input).toEqual({
    TableName: 'coupons', Key: { coupon_id: sample.coupon_id },
    UpdateExpression: 'SET #f0 = :v0, #f1 = :v1',
    ExpressionAttributeNames: { '#pk': 'coupon_id', '#f0': 'title', '#f1': 'coupon_code' },
    ExpressionAttributeValues: { ':v0': 'Updated title', ':v1': 'NEWCODE' },
    ConditionExpression: 'attribute_exists(#pk)', ReturnValues: 'ALL_NEW'
  });
});

test.each(['{broken', '', 'null', '[]', '{}', '123', '{"unexpected":"value"}',
  '{"title":null}', '{"title":45}', '{"title":" "}', '{"coupon_id":"different","title":"New"}'])(
  'rejects invalid update input without a database write: %s', async body => {
    expect((await handler(event(body))).statusCode).toBe(400);
    expect(send).not.toHaveBeenCalled();
  });

test('rejects a missing path id without a database write', async () => {
  expect((await handler({ body: '{"title":"New"}' })).statusCode).toBe(400);
  expect(send).not.toHaveBeenCalled();
});

test('accepts the matching coupon_id in a complete coupon object', async () => {
  send.mockResolvedValue({ Attributes: sample });
  expect((await handler(event(JSON.stringify(sample)))).statusCode).toBe(200);
  expect(Object.values(send.mock.calls[0][0].input.ExpressionAttributeNames)
    .filter(name => name === 'coupon_id')).toHaveLength(1);
});

test('supports a base64 encoded API Gateway JSON body', async () => {
  send.mockResolvedValue({ Attributes: sample });
  const input = event(Buffer.from('{"title":"New"}').toString('base64'));
  input.isBase64Encoded = true;
  expect((await handler(input)).statusCode).toBe(200);
});

test('returns 404 when the conditional update finds no existing coupon', async () => {
  send.mockRejectedValue({ name: 'ConditionalCheckFailedException' });
  expect((await handler(event('{"title":"New"}'))).statusCode).toBe(404);
});

test('returns 500 when the external database write fails', async () => {
  const log = jest.spyOn(console, 'error').mockImplementation(() => {});
  send.mockRejectedValue(new Error('private service details'));
  const response = await handler(event('{"title":"New"}'));
  expect(response.statusCode).toBe(500);
  expect(response.body).not.toContain('private service details');
  log.mockRestore();
});
