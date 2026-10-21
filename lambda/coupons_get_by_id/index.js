const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand } = require('@aws-sdk/lib-dynamodb');

const client = DynamoDBDocumentClient.from(new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-1',
  ...(process.env.DYNAMODB_ENDPOINT && { endpoint: process.env.DYNAMODB_ENDPOINT })
}));

const respond = (statusCode, body) => ({
  statusCode, headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(body)
});

exports.handler = async function(event) {
  const id = event?.pathParameters?.id;
  if (typeof id !== 'string' || !id.trim()) {
    return respond(400, { message: 'Coupon id is required' });
  }

  try {
    const result = await client.send(new GetCommand({
      TableName: process.env.COUPONS_TABLE || 'coupons',
      Key: { coupon_id: id },
      ConsistentRead: false
    }));
    return result.Item ? respond(200, result.Item) :
      respond(404, { message: 'Coupon not found' });
  } catch (error) {
    console.error('Coupon lookup failed:', error.name);
    return respond(500, { message: 'Unable to retrieve coupon' });
  }
};
