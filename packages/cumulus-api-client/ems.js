'use strict';

const { lambda } = require('@cumulus/aws-client/services');
const { invokeApi } = require('./cumulusApiClient');


/**
 * Fetch deployment's `ems_*` environment variables.
 *
 * @param {string} lambdaName - deployment prefix
 * @returns {Promise<Object>} map of ems_* lambda envs
 */
async function getLambdaEmsSettings(lambdaName) {
  const config = await lambda().getFunctionConfiguration({ FunctionName: lambdaName }).promise();
  const envs = config.Environment.Variables;
  return Object.keys(envs).reduce((map, key) => {
    if (!key.startsWith('ems_')) return map;
    const shortKey = key.slice('ems_'.length);
    return { ...map, [shortKey]: envs[key] };
  }, {});
}

/**
 * Post a request to the ems API
 * POST /ems
 *
 * @param {Object} params            - params
 * @param {string} params.prefix     - the prefix configured for the stack
 * @param {Object} params.request    - request body to post
 * @param {Function} params.callback - async function to invoke the api lambda
 *                                   that takes a prefix / user payload.  Defaults
 *                                   to cumulusApiClient.invokeApifunction to invoke the api lambda
 * @returns {Promise<Object>}        - promise that resolves to the output of the API lambda
 */
async function createEmsReports({ prefix, request, callback = invokeApi }) {
  return callback({
    prefix: prefix,
    payload: {
      httpMethod: 'POST',
      resource: '/{proxy+}',
      headers: {
        'Content-Type': 'application/json'
      },
      path: '/ems',
      body: JSON.stringify(request)
    }
  });
}

module.exports = {
  createEmsReports,
  getLambdaEmsSettings
};
