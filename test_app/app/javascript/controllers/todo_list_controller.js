import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "itemsContainer", "counter", "emptyState", "addForm"]
  static values = { items: Array }

  connect() {
    if (this.itemsValue.length === 0) {
      this.itemsValue = []
    }
    this.render()
  }

  showAddForm() {
    this.addFormTarget.classList.remove("hidden")
    this.inputTarget.focus()
  }

  hideAddForm() {
    this.addFormTarget.classList.add("hidden")
    this.inputTarget.value = ""
  }

  addItem(event) {
    event.preventDefault()
    
    const text = this.inputTarget.value.trim()
    if (text === "") return

    const newItem = {
      id: Date.now(),
      text: text,
      completed: false
    }

    this.itemsValue = [...this.itemsValue, newItem]
    this.inputTarget.value = ""
    this.hideAddForm()
    this.render()
  }

  toggleItem(event) {
    const id = parseInt(event.currentTarget.dataset.itemId)
    this.itemsValue = this.itemsValue.map(item => 
      item.id === id ? { ...item, completed: !item.completed } : item
    )
    this.render()
  }

  deleteItem(event) {
    const id = parseInt(event.currentTarget.dataset.itemId)
    this.itemsValue = this.itemsValue.filter(item => item.id !== id)
    this.render()
  }

  render() {
    // Update counter
    const activeCount = this.itemsValue.filter(item => !item.completed).length
    const totalCount = this.itemsValue.length
    this.counterTarget.textContent = `${activeCount} of ${totalCount} active`

    // Update empty state
    if (this.itemsValue.length === 0) {
      this.emptyStateTarget.classList.remove("hidden")
      this.itemsContainerTarget.innerHTML = ""
      return
    } else {
      this.emptyStateTarget.classList.add("hidden")
    }

    // Render items
    this.itemsContainerTarget.innerHTML = this.itemsValue.map(item => `
      <div class="flex items-center gap-3 px-6 py-3 border-b border-gray-200 hover:bg-gray-50 transition group">
        <input 
          type="checkbox" 
          ${item.completed ? 'checked' : ''}
          data-action="change->todo-list#toggleItem"
          data-item-id="${item.id}"
          class="w-5 h-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
        >
        <span class="flex-1 ${item.completed ? 'line-through text-gray-500' : 'text-gray-900'}">
          ${this.escapeHtml(item.text)}
        </span>
        <button
          data-action="click->todo-list#deleteItem"
          data-item-id="${item.id}"
          class="text-red-500 opacity-0 group-hover:opacity-100 transition hover:text-red-700"
        >
          ✕
        </button>
      </div>
    `).join('')
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}