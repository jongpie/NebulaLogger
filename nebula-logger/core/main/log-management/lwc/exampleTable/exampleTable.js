import { LightningElement, track } from 'lwc';

export default class ExampleTable extends LightningElement {
  @track searchTerm = '';
  @track tableData = [];
  objectLabel = 'Contacts';
  objectIcon = 'standard:contact';
  @track lastRefreshedAt = null;

  columns = [
    { label: 'Name', fieldName: 'name', type: 'text' },
    { label: 'Phone', fieldName: 'phone', type: 'phone' },
    { label: 'Email', fieldName: 'email', type: 'email' }
  ];

  _allData = [];

  connectedCallback() {
    this._allData = [
      { id: '1', name: 'Alice Smith', phone: '555-1000', email: 'alice@example.com' },
      { id: '2', name: 'Bob Jones', phone: '555-1001', email: 'bob@example.com' },
      { id: '3', name: 'Carol White', phone: '555-1002', email: 'carol@example.com' }
    ];
    this.tableData = [...this._allData];
    this.refreshLastRefreshed();
  }

  get headerTitle() {
    const count = this.tableData.length;
    return `${this.objectLabel} (${count})`;
  }

  get lastRefreshedText() {
    if (!this.lastRefreshedAt) return 'Last refreshed: —';
    const d = this.lastRefreshedAt;
    const time = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const date = d.toLocaleDateString();
    return `Last refreshed: ${date} ${time}`;
  }

  handleSearchChange(event) {
    this.searchTerm = event.target.value || '';
    this.filterData();
  }

  filterData() {
    const term = (this.searchTerm || '').toLowerCase().trim();
    if (!term) {
      this.tableData = [...this._allData];
      return;
    }
    this.tableData = this._allData.filter(
      (row) =>
        (row.name && row.name.toLowerCase().includes(term)) ||
        (row.phone && row.phone.includes(term)) ||
        (row.email && row.email.toLowerCase().includes(term))
    );
  }

  refreshLastRefreshed() {
    this.lastRefreshedAt = new Date();
  }

  handleNew() {
    // Dispatch or navigate to new record; placeholder for demo
    // eslint-disable-next-line no-console
    console.log('New clicked');
  }
}
