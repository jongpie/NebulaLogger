import { getLogger } from 'c/logger';

export function logMessage(message) {
  const customStackTraceError = new Error();
  customStackTraceError.stack = customStackTraceError.stack
    .split('\n')
    .filter(line => !line.includes('loggerWrapper.js'))
    .join('\n');


  const logger = getLogger();
  logger.info(message).parseStackTrace(customStackTraceError);
  logger.saveLog();
}
