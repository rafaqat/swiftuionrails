import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "backdrop", "input", "results", "item", "empty"]

  connect() {
    this.selectedIndex = -1
  }

  toggle(event) {
    if (event) event.preventDefault()
    
    if (this.containerTarget.classList.contains("opacity-0")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.containerTarget.classList.remove("opacity-0", "pointer-events-none", "scale-95")
    this.backdropTarget.classList.remove("opacity-0", "pointer-events-none")
    this.inputTarget.focus()
    this.selectedIndex = 0
    this.highlightSelected()
  }

  close() {
    this.containerTarget.classList.add("opacity-0", "pointer-events-none", "scale-95")
    this.backdropTarget.classList.add("opacity-0", "pointer-events-none")
    this.inputTarget.value = ""
    this.search() // Reset results
  }

  search() {
    const query = this.inputTarget.value.toLowerCase()
    let hasResults = false
    
    this.itemTargets.forEach(item => {
      const keywords = item.dataset.keywords
      const group = item.closest('.group-container')
      
      if (keywords.includes(query)) {
        item.style.display = "flex"
        hasResults = true
        // Ensure group is visible if it has visible items
        if (group) group.style.display = "block"
      } else {
        item.style.display = "none"
      }
    })
    
    // Hide empty groups
    document.querySelectorAll('.group-container').forEach(group => {
      const visibleItems = group.querySelectorAll('[data-command-palette-target="item"][style="display: flex;"]').length
      if (visibleItems === 0 && query.length > 0) {
        group.style.display = "none"
      }
    })

    if (hasResults || query.length === 0) {
      this.emptyTarget.classList.add("hidden")
    } else {
      this.emptyTarget.classList.remove("hidden")
    }
    
    this.selectedIndex = 0
    this.highlightSelected()
  }

  next(event) {
    event.preventDefault()
    const visibleItems = this.getVisibleItems()
    if (this.selectedIndex < visibleItems.length - 1) {
      this.selectedIndex++
      this.highlightSelected()
      this.scrollToSelected()
    }
  }

  prev(event) {
    event.preventDefault()
    if (this.selectedIndex > 0) {
      this.selectedIndex--
      this.highlightSelected()
      this.scrollToSelected()
    }
  }

  execute(event) {
    if (event && event.type === 'keydown') event.preventDefault()
    
    const visibleItems = this.getVisibleItems()
    const selectedItem = visibleItems[this.selectedIndex]
    
    if (selectedItem) {
      const payload = selectedItem.dataset.payload
      this.handleAction(payload)
      this.close()
    }
  }

  // --- Private Helpers ---

  getVisibleItems() {
    return this.itemTargets.filter(item => item.style.display !== "none")
  }

  highlightSelected() {
    const visibleItems = this.getVisibleItems()
    visibleItems.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("bg-gray-100", "text-gray-900")
        item.querySelector("svg")?.classList.remove("text-gray-500")
        item.querySelector("svg")?.classList.add("text-gray-900")
      } else {
        item.classList.remove("bg-gray-100", "text-gray-900")
        item.querySelector("svg")?.classList.add("text-gray-500")
        item.querySelector("svg")?.classList.remove("text-gray-900")
      }
    })
  }
  
  scrollToSelected() {
    const visibleItems = this.getVisibleItems()
    const selectedItem = visibleItems[this.selectedIndex]
    if (selectedItem) {
      selectedItem.scrollIntoView({ block: "nearest" })
    }
  }

  handleAction(payload) {
    if (!payload) return

    if (payload.startsWith("visit:")) {
      const url = payload.replace("visit:", "")
      window.location.href = url
    } else if (payload.startsWith("action:")) {
      console.log("Dispatching global action:", payload)
      // Implementation for custom events or Turbo visits
      alert(`Action triggered: ${payload}`)
    } else if (payload === "theme:toggle") {
      // Demo action
      document.body.classList.toggle("dark")
      alert("Toggled theme (Demo)")
    }
  }
}
