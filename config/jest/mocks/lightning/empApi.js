// An object to store callbacks
const _channels = {};

export const isEmpEnabled = jest.fn().mockResolvedValue(true);

// A Jest-specific function for mock publishing LogEntryEvent__e platform event
export const jestMockPublish = jest.fn((channel, message) => {
  if (_channels[channel] && _channels[channel].onMessageCallback instanceof Function) {
    _channels[channel].onMessageCallback(message);
  }
  Promise.resolve(true);
});

// On subscribe, store the callback function and resolve the promise
export const subscribe = jest.fn((channel, replayId, onMessageCallback) => {
  _channels[channel] = { onMessageCallback };
  return Promise.resolve({
    id: '_' + Date.now(),
    channel: channel,
    replayId: replayId
  });
});

export const unsubscribe = jest.fn().mockResolvedValue({});
export const onError = jest.fn().mockResolvedValue(jest.fn());
export const setDebugFlag = jest.fn().mockResolvedValue();
