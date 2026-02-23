import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

import loggerStaticResources from '@salesforce/resourceUrl/LoggerResources';

// Shared across all instances
let libsPromise;
let md; // shared markdown-it instance

export default class LoggerMarkdownViewer extends LightningElement {
  @api content = '';

  _renderKey;
  _hasRendered = false;

  get hasText() {
    return (this.content || '').trim().length > 0;
  }

  get showSkeleton() {
    return this.hasText && !this._hasRendered;
  }

  get showContent() {
    return this.hasText && this._hasRendered;
  }

  get wrapperClass() {
    return `wrap ${this._hasRendered ? 'is-loaded' : 'is-loading'}`;
  }

  renderedCallback() {
    if (!this.hasText) {
      return;
    }

    if (!libsPromise) {
      libsPromise = Promise.all([
        loadScript(this, loggerStaticResources + '/markdown-it.min.js'),
        loadStyle(this, loggerStaticResources + '/prism.css'),
        loadScript(this, loggerStaticResources + '/prism.js')
      ]).then(() => {
        // Create once
        md = window.markdownit({ html: false, linkify: true, breaks: true });

        // For some elements, we need to add SLDS classes so they look consistent with the rest of the page

        // Header elements
        const headerLevelClassMap = {
          1: 'slds-text-heading_large',
          2: 'slds-text-heading_medium',
          3: 'slds-text-heading_small'
        };
        md.renderer.rules.heading_open = (tokens, idx, options, _env, self) => {
          const headerLevel = Number(tokens[idx].tag.replace('h', '')); // 1..6
          const headerLevelClass = headerLevelClassMap[headerLevel] ?? 'slds-text-title_bold';
          tokens[idx].attrJoin('class', headerLevelClass + ' slds-m-top_x-large');
          return self.renderToken(tokens, idx, options);
        };

        // Tables & related elements
        md.renderer.rules.table_open = () => '<table class="slds-table slds-table_fixed-layout slds-table_bordered slds-no-row-hover slds-table_cell-buffer">';
        md.renderer.rules.th_open = () => '<th scope="col"><div class="slds-truncate">';
        md.renderer.rules.th_close = () => '</div></th>';
        md.renderer.rules.td_open = () => '<td><div class="slds-truncate">';
        md.renderer.rules.td_close = () => '</div></td>';
      });
    }

    libsPromise.then(() => this.renderMarkdown());
  }

  renderMarkdown() {
    console.log('>>> md', md);
    if (!md) {
      return;
    }

    const text = this.content || '';
    console.log('>>> text', text);
    if (this._renderKey === text) {
      return;
    }

    this._renderKey = text;
    const html = md.render(text);
    console.log('>>> html', html);

    const container = this.template.querySelector('.markdown-viewer');
    console.log('>>> container found', container);
    if (!container) {
      return;
    }

    container.innerHTML = html;

    window.Prism?.highlightAllUnder(container);

    this._hasRendered = true;
  }
}
