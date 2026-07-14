const { ensurePostRequest } = require('../_lib');

module.exports = async function handler(req, res) {
  if (!ensurePostRequest(req, res)) return;
  const { aiAnalyticsHandler } = await import('../../server/lib/handlers.js');
  return aiAnalyticsHandler(req, res);
};
