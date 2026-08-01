import { LightningElement } from 'lwc';

export default class LightningExampleInputSearch extends LightningElement {
    queryTerm = '';
    items = [
        { id: 1, name: 'Apple' },
        { id: 2, name: 'Banana' },
        { id: 3, name: 'Cherry' },
    ];
    filteredItems = this.items;

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
            this.filteredItems = this.items.filter(item =>
                item.name.toLowerCase().includes(this.queryTerm.toLowerCase())
            );
        }
    }
}