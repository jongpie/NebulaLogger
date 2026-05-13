/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

// Shared preferences module for loggerCodeViewer and its consumers.
// The module is namespace-agnostic by design: storage keys use the *unprefixed* field API name so
// that user preferences survive deployments with different namespaces (unlocked vs. managed vs. ISV-rebadged).

const STORAGE_KEY_PREFIX = 'nebula-logger';

export const STORAGE_KEYS = {
  theme: `${STORAGE_KEY_PREFIX}:theme`,
  remember: `${STORAGE_KEY_PREFIX}:remember`,
  languageFor: fieldApiName => `${STORAGE_KEY_PREFIX}:lang:${fieldApiName}`
};

const AVAILABLE_THEMES = [
  { label: 'Tomorrow (Dark)', value: 'prism-tomorrow' },
  { label: 'Default (Light)', value: 'prism' },
  { label: 'Coy (Light)', value: 'prism-coy' },
  { label: 'Okaidia (Dark)', value: 'prism-okaidia' },
  { label: 'Solarized Light', value: 'prism-solarizedlight' },
  { label: 'Twilight (Dark)', value: 'prism-twilight' }
];

export const DEFAULT_THEME = AVAILABLE_THEMES[0].value;

const themeSubscribers = new Set();

// In-memory fallback used when localStorage is unavailable or throws (e.g., some Lightning Out
// or restricted Experience Cloud contexts). Keys mirror the localStorage layout.
const memoryStore = new Map();

function safeStorageGet(key) {
  try {
    const value = localStorage.getItem(key);
    return value === null && memoryStore.has(key) ? memoryStore.get(key) : value;
  } catch (e) {
    return memoryStore.has(key) ? memoryStore.get(key) : null;
  }
}

function safeStorageSet(key, value) {
  memoryStore.set(key, value);
  try {
    localStorage.setItem(key, value);
  } catch (e) {
    // Swallow — memoryStore already has the value.
  }
}

function safeStorageRemove(key) {
  memoryStore.delete(key);
  try {
    localStorage.removeItem(key);
  } catch (e) {
    // Swallow.
  }
}

export function getAvailableThemes() {
  // Return a defensive copy so callers can't mutate the canonical list.
  return AVAILABLE_THEMES.map(theme => ({ ...theme }));
}

function isValidTheme(theme) {
  return AVAILABLE_THEMES.some(entry => entry.value === theme);
}

export function getTheme() {
  const stored = safeStorageGet(STORAGE_KEYS.theme);
  return isValidTheme(stored) ? stored : DEFAULT_THEME;
}

export function setTheme(theme) {
  if (!isValidTheme(theme)) {
    return;
  }
  const previous = getTheme();
  if (previous === theme) {
    return;
  }
  safeStorageSet(STORAGE_KEYS.theme, theme);
  notifyThemeSubscribers(theme);
}

export function subscribeToTheme(callback) {
  if (typeof callback === 'function') {
    themeSubscribers.add(callback);
  }
}

export function unsubscribeFromTheme(callback) {
  themeSubscribers.delete(callback);
}

function notifyThemeSubscribers(theme) {
  for (const subscriber of themeSubscribers) {
    try {
      subscriber(theme);
    } catch (error) {
      console.error('loggerCodePreferences theme subscriber threw', error);
    }
  }
}

export function getLanguageForField(fieldApiName) {
  if (!fieldApiName) {
    return null;
  }
  return safeStorageGet(STORAGE_KEYS.languageFor(fieldApiName));
}

export function setLanguageForField(fieldApiName, language) {
  if (!fieldApiName) {
    return;
  }
  const key = STORAGE_KEYS.languageFor(fieldApiName);
  if (language === null || language === undefined || language === '') {
    safeStorageRemove(key);
    return;
  }
  safeStorageSet(key, language);
}

export function getRememberPreference() {
  const stored = safeStorageGet(STORAGE_KEYS.remember);
  // Default to true when nothing is persisted.
  return stored === null ? true : stored !== 'false';
}

export function setRememberPreference(remember) {
  safeStorageSet(STORAGE_KEYS.remember, String(Boolean(remember)));
}
