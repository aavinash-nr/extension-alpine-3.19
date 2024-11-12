import newrelic.agent
from newrelic_lambda.lambda_handler import lambda_handler

newrelic.agent.initialize()
@lambda_handler()
def handler(event, context):
    print('Hello, world!')
    return {'foo': 'bar'}