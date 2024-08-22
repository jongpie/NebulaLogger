import { createElement } from 'lwc';
import LoggerCodeViewer from 'c/loggerCodeViewer';

jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise((resolve, _) => {
          global.Prism = require('../../../staticresources/LoggerResources/prism.js');
          resolve();
        });
      },
      loadStyle() {
        // No-op for now
        return Promise.resolve();
      }
    };
  },
  { virtual: true }
);

describe('c-logger-code-viewer', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('displays Prism code viewer with provided attributes', async () => {
    const element = createElement('c-logger-code-viewer', {
      is: LoggerCodeViewer
    });
    element.language = 'cobol';
    element.startingLineNumber = '10';
    element.targetLineNumber = '18';
    let mockCode = '';
    for (let i = 0; i < element.targetLineNumber + 5; i++) {
      mockCode += 'some line of "code", line number is ' + (i + 1) + '\n';
    }
    element.code = mockCode;

    document.body.appendChild(element);

    await Promise.resolve('rerender after loading Prism script and style from static resource');
    await Promise.resolve("rerender after generating the code element's innerHTML and running Prism.highlightAll()");
    const prismCodeViewer = element.shadowRoot.querySelector('div.prism-viewer');
    expect(prismCodeViewer.classList.contains('line-numbers')).toBeTruthy();
    const prismCodeViewerPre = element.shadowRoot.querySelector('div.prism-viewer pre');
    expect(prismCodeViewerPre).toBeTruthy();
    expect(prismCodeViewerPre.dataset.start).toBe(element.startingLineNumber);
    expect(prismCodeViewerPre.dataset.line).toBe(element.targetLineNumber);
    expect(prismCodeViewerPre.dataset.lineOffset).toBe(element.targetLineNumber);
    const prismCodeViewerCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
    expect(prismCodeViewerCode).toBeTruthy();
    expect(prismCodeViewerCode.classList.contains('language-' + element.language)).toBeTruthy();
    expect(prismCodeViewerCode.innerHTML).toContain(mockCode);
  });
});
