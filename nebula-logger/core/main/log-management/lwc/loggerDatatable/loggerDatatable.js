/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';

/**
 * Presentational LWC that mimics the look and feel of a standard Salesforce related list:
 * card with page header (icon, title + count), settings/refresh/New actions, status line,
 * and a lightning-datatable inside a bordered list view container.
 */
export default class LoggerDatatable extends LightningElement {
  /** List title (e.g. "Log Entries") */
  @api title = '';

  /** SLDS icon name for the list (e.g. "standard:log", "custom:custom83") */
  @api iconName = '';

  /** Key field for each row (used by lightning-datatable) */
  @api keyField = 'id';

  /** Table data (array of objects) */
  @api data = [];

  /** Column definitions for lightning-datatable */
  @api columns = [];

  /** Show row number column (default false to match standard related list) */
  @api showRowNumberColumn = false;

  /** Hide checkbox column (default false for simple related list look) */
  @api hideCheckboxColumn = false;

  /** Show settings (gear) menu in header */
  @api showSettingsMenu = false;

  /** Show refresh button in header */
  @api showRefreshButton = false;

  /** Show "New" button in header */
  @api showNewButton = false;

  /** Optional status suffix after item count, e.g. "Updated 5 minutes ago" */
  @api statusSuffix = '';

  /** Show loading spinner and hide table */
  @api isLoading = false;

  /** Current sort field (passed to lightning-datatable) */
  @api sortedBy;

  /** Current sort direction: 'asc' | 'desc' */
  @api sortedDirection = 'asc';

  /** Default sort direction for unsorted columns */
  @api defaultSortDirection = 'asc';

  get ariaLabel() {
    return this.title || 'Related list';
  }

  get itemCount() {
    return Array.isArray(this.data) ? this.data.length : 0;
  }

  get titleWithCount() {
    return `(${this.itemCount})`;
  }

  handleSort(event) {
    this.dispatchEvent(
      new CustomEvent('sort', {
        detail: {
          fieldName: event.detail.fieldName,
          sortDirection: event.detail.sortDirection
        },
        bubbles: true,
        composed: true
      })
    );
  }

  handleRefresh() {
    this.dispatchEvent(
      new CustomEvent('refresh', {
        bubbles: true,
        composed: true
      })
    );
  }

  handleNew() {
    this.dispatchEvent(
      new CustomEvent('new', {
        bubbles: true,
        composed: true
      })
    );
  }

  handleSettingsSelect(event) {
    this.dispatchEvent(
      new CustomEvent('settingsselect', {
        detail: { value: event.detail.value },
        bubbles: true,
        composed: true
      })
    );
  }
}
