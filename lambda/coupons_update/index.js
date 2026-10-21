const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, UpdateCommand } = require('@aws-sdk/lib-dynamodb');

const client = DynamoDBDocumentClient.from(new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-1',
  ...(process.env.DYNAMODB_ENDPOINT && { endpoint: process.env.DYNAMODB_ENDPOINT })
}));
const fields = new Set([
  'title', 'description', 'coupon_code', 'campaign_id', 'provider_id',
  'provider_name', 'start_date', 'end_date'
]);
const respond = (statusCode, body) => ({
  statusCode, headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body)
});

exports.handler = async function(event) {
  const id = event?.pathParameters?.id;
  if (typeof id !== 'string' || !id.trim()) {
    return respond(400, { message: 'Coupon id is required' });
  }
  let body;
  try {
    const raw = event.isBase64Encoded ?
      Buffer.from(event.body, 'base64').toString('utf8') : event.body;
    body = JSON.parse(raw);
  } catch (_) {
    return respond(400, { message: 'Request body must be valid JSON' });
  }
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return respond(400, { message: 'Request body must be a JSON object' });
  }
  if (Object.hasOwn(body, 'coupon_id') && body.coupon_id !== id) {
    return respond(400, { message: 'Coupon id cannot be changed' });
  }
  const updates = Object.entries(body).filter(([key]) => key !== 'coupon_id');
  if (!updates.length || updates.some(([key, value]) =>
    !fields.has(key) || typeof value !== 'string' || !value.trim())) {
    return respond(400, { message: 'Provide supported coupon fields with nonempty string values' });
  }

  const names = { '#pk': 'coupon_id' };
  const values = {};
  const assignments = updates.map(([key, value], i) => {
    names[`#f${i}`] = key;
    values[`:v${i}`] = value;
    return `#f${i} = :v${i}`;
  });
  try {
    const result = await client.send(new UpdateCommand({
      TableName: process.env.COUPONS_TABLE || 'coupons',
      Key: { coupon_id: id },
      UpdateExpression: `SET ${assignments.join(', ')}`,
      ExpressionAttributeNames: names,
      ExpressionAttributeValues: values,
      // Update existing coupons only; do not silently create incomplete items.
      ConditionExpression: 'attribute_exists(#pk)',
      ReturnValues: 'ALL_NEW'
    }));
    return respond(200, result.Attributes);
  } catch (error) {
    if (error.name === 'ConditionalCheckFailedException') {
      return respond(404, { message: 'Coupon not found' });
    }
    console.error('Coupon update failed:', error.name);
    return respond(500, { message: 'Unable to update coupon' });
  }
};
