import { LightningElement } from 'lwc';

export default class TaskManager extends LightningElement {  
    selectedFilter = ''; // Store the selected filter
    // Handle filter change event from TaskFilter component
    handleFilterChange(event) {
        this.selectedFilter = event.detail;
    }  
}