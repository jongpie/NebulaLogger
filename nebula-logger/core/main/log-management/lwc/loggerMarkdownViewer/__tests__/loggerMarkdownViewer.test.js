import { createElement } from '@lwc/engine-dom';
import LoggerMarkdownViewer from 'c/loggerMarkdownViewer';

jest.mock(
  'lightning/platformResourceLoader',
  () => {
    const renderToken = jest.fn((tokens, idx) => {
      const t = tokens[idx];
      return `<${t.tag}>`;
    });
    const createMarkdownItMock = () => ({
      render: jest.fn((text) => `<p>${String(text).replace(/</g, '&lt;')}</p>`),
      renderer: {
        rules: {
          heading_open: function (tokens, idx, options, env, self) {
            const level = Number(tokens[idx].tag.replace('h', ''));
            const cls =
              level === 1
                ? 'slds-text-heading_large'
                : level === 2
                  ? 'slds-text-heading_medium'
                  : level === 3
                    ? 'slds-text-heading_small'
                    : 'slds-text-title_bold';
            tokens[idx].attrJoin('class', cls);
            return renderToken(tokens, idx, options, env, self);
          }
        }
      }
    });
    return {
      loadScript(comp, url) {
        return new Promise(resolve => {
          if (url.includes('markdown-it')) {
            global.window.markdownit = function () {
              return createMarkdownItMock();
            };
          } else {
            global.window.Prism = {
              highlightAllUnder: jest.fn()
            };
          }
          resolve();
        });
      },
      loadStyle() {
        return Promise.resolve();
      }
    };
  },
  { virtual: true }
);

const flushPromises = () => new Promise(resolve => setTimeout(resolve, 0));

describe('c-logger-markdown-viewer', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('renders with empty content (no skeleton, no content)', () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = '';
    document.body.appendChild(element);

    const wrap = element.shadowRoot.querySelector('.wrap');
    expect(wrap).toBeTruthy();
    expect(wrap.classList.contains('is-loading')).toBeTruthy();
    const skeleton = element.shadowRoot.querySelector('.skeleton');
    const contentWrap = element.shadowRoot.querySelector('.contentWrap');
    expect(skeleton).toBeFalsy();
    expect(contentWrap).toBeTruthy();
  });

  it('shows skeleton when content is set and scripts not yet loaded', () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = 'Hello **world**';
    document.body.appendChild(element);

    const skeleton = element.shadowRoot.querySelector('.skeleton');
    expect(skeleton).toBeTruthy();
  });

  it('displays markdown viewer with provided content after scripts load', async () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = '# Hello world';
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const container = element.shadowRoot.querySelector('.markdown-viewer');
    expect(container).toBeTruthy();
    expect(container.innerHTML).toBeTruthy();
    expect(container.innerHTML).toContain('Hello world');
  });

  it('applies wrapper class is-loaded after render', async () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = 'Some text';
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const wrap = element.shadowRoot.querySelector('.wrap');
    expect(wrap).toBeTruthy();
    expect(wrap.classList.contains('is-loaded')).toBeTruthy();
  });

  it('does not show skeleton for empty string (hasText false)', () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = '';
    document.body.appendChild(element);
    const skeleton = element.shadowRoot.querySelector('.skeleton');
    expect(skeleton).toBeFalsy();
  });

  it('does not show skeleton for whitespace-only content (hasText false)', () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = '   \n\t  ';
    document.body.appendChild(element);
    const skeleton = element.shadowRoot.querySelector('.skeleton');
    expect(skeleton).toBeFalsy();
  });

  it('shows skeleton when content has non-whitespace (hasText true)', () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = ' x ';
    document.body.appendChild(element);
    const skeleton = element.shadowRoot.querySelector('.skeleton');
    expect(skeleton).toBeTruthy();
  });

  it('invokes Prism.highlightAllUnder after rendering markdown', async () => {
    const element = createElement('c-logger-markdown-viewer', {
      is: LoggerMarkdownViewer
    });
    element.content = '```js\nconst x = 1;\n```';
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(global.window.Prism.highlightAllUnder).toHaveBeenCalled();
    const container = element.shadowRoot.querySelector('.markdown-viewer');
    expect(global.window.Prism.highlightAllUnder).toHaveBeenCalledWith(container);
  });
});
