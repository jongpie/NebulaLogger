import { createElement } from '@lwc/engine-dom';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import RelatedLogEntries from 'c/relatedLogEntries';
import getQueryResult from '@salesforce/apex/RelatedLogEntriesController.getQueryResult';
import getAvailableTags from '@salesforce/apex/RelatedLogEntriesController.getAvailableTags';
import getCurrentUsername from '@salesforce/apex/RelatedLogEntriesController.getCurrentUsername';

const MOCK_RECORD_ID = '0015400000gY3OuAAK';
const MOCK_QUERY_RESULT = require('./data/getQueryResult.json');
const MOCK_AVAILABLE_TAGS = ['Tag1', 'Tag2', 'Tag3'];
const MOCK_USERNAME = 'test@example.com';

jest.mock(
  '@salesforce/apex/RelatedLogEntriesController.getQueryResult',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  '@salesforce/apex/RelatedLogEntriesController.getAvailableTags',
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  '@salesforce/apex/RelatedLogEntriesController.getCurrentUsername',
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

describe('Related Log Entries lwc tests', () => {
  beforeEach(() => {
    // Mock localStorage
    const localStorageMock = {
      getItem: jest.fn(),
      setItem: jest.fn(),
      clear: jest.fn()
    };
    global.localStorage = localStorageMock;

    // Mock Apex methods
    getAvailableTags.mockResolvedValue(MOCK_AVAILABLE_TAGS);
    getCurrentUsername.mockResolvedValue(MOCK_USERNAME);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('sets query result', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    getQueryResult.emit({ ...MOCK_QUERY_RESULT });

    await Promise.resolve();
    expect(relatedLogEntriesElement.queryResult).toBeTruthy();
    expect(relatedLogEntriesElement.queryResult.records[0].Id).toEqual(MOCK_QUERY_RESULT.records[0].Id);
    // expect(relatedLogEntriesElement.fieldSetName).not.toBe(undefined);
  });

  it('loads filters from localStorage on initialization', async () => {
    const mockFilters = {
      loggingLevels: ['ERROR', 'WARN'],
      timestampStart: '2024-01-01T00:00:00Z',
      timestampEnd: '2024-12-31T23:59:59Z',
      loggedByUsername: 'test@example.com',
      originSourceMetadataTypes: ['ApexClass'],
      tags: ['Tag1']
    };
    global.localStorage.getItem.mockReturnValue(JSON.stringify(mockFilters));

    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();
    expect(relatedLogEntriesElement.filters).toEqual(mockFilters);
  });

  it('saves filters to localStorage when filter changes', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();

    relatedLogEntriesElement.filters = {
      loggingLevels: ['ERROR'],
      timestampStart: null,
      timestampEnd: null,
      loggedByUsername: '',
      originSourceMetadataTypes: [],
      tags: []
    };
    relatedLogEntriesElement.saveFiltersToStorage();

    expect(global.localStorage.setItem).toHaveBeenCalled();
  });

  it('loads available tags on initialization', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();
    expect(getAvailableTags).toHaveBeenCalledWith({ recordId: MOCK_RECORD_ID });
    expect(relatedLogEntriesElement.availableTags).toEqual(MOCK_AVAILABLE_TAGS);
  });

  it('calculates active filter count correctly', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    relatedLogEntriesElement.filters = {
      loggingLevels: ['ERROR', 'WARN'],
      timestampStart: '2024-01-01T00:00:00Z',
      timestampEnd: null,
      loggedByUsername: 'test@example.com',
      originSourceMetadataTypes: [],
      tags: ['Tag1', 'Tag2']
    };
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();
    // Should count: loggingLevels (1), timestampStart (1), loggedByUsername (1), tags (1) = 4
    expect(relatedLogEntriesElement.activeFilterCount).toBe(4);
  });

  it('toggles filter visibility', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();
    expect(relatedLogEntriesElement.showFilters).toBe(false);

    relatedLogEntriesElement.handleToggleFilters();
    expect(relatedLogEntriesElement.showFilters).toBe(true);

    relatedLogEntriesElement.handleToggleFilters();
    expect(relatedLogEntriesElement.showFilters).toBe(false);
  });

  it('clears all filters', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    relatedLogEntriesElement.filters = {
      loggingLevels: ['ERROR'],
      timestampStart: '2024-01-01T00:00:00Z',
      timestampEnd: '2024-12-31T23:59:59Z',
      loggedByUsername: 'test@example.com',
      originSourceMetadataTypes: ['ApexClass'],
      tags: ['Tag1'],
      currentUserOnly: true
    };
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();

    relatedLogEntriesElement.handleClearFilters();

    expect(relatedLogEntriesElement.filters).toEqual({
      loggingLevels: [],
      timestampStart: null,
      timestampEnd: null,
      loggedByUsername: '',
      originSourceMetadataTypes: [],
      tags: [],
      currentUserOnly: false
    });
  });

  it('enables current user only filter', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();

    // Simulate current username being loaded
    relatedLogEntriesElement.currentUsername = MOCK_USERNAME;

    // Simulate checkbox change
    relatedLogEntriesElement.handleCurrentUserOnlyChange({ detail: { checked: true } });

    expect(relatedLogEntriesElement.filters.currentUserOnly).toBe(true);
    expect(relatedLogEntriesElement.filters.loggedByUsername).toBe(MOCK_USERNAME);
  });

  it('disables current user only filter', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    relatedLogEntriesElement.filters.currentUserOnly = true;
    relatedLogEntriesElement.filters.loggedByUsername = MOCK_USERNAME;
    relatedLogEntriesElement.currentUsername = MOCK_USERNAME;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();

    // Simulate checkbox change
    relatedLogEntriesElement.handleCurrentUserOnlyChange({ detail: { checked: false } });

    expect(relatedLogEntriesElement.filters.currentUserOnly).toBe(false);
    expect(relatedLogEntriesElement.filters.loggedByUsername).toBe('');
  });

  it('loads current username on initialization', async () => {
    const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
    relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
    document.body.appendChild(relatedLogEntriesElement);

    await Promise.resolve();
    expect(getCurrentUsername).toHaveBeenCalled();
    expect(relatedLogEntriesElement.currentUsername).toBe(MOCK_USERNAME);
  });
});
