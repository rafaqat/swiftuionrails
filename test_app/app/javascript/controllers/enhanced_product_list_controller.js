import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    sortable: Boolean, 
    filterable: Boolean,
    products: Array 
  }
  
  static targets = ["grid", "productCard", "emptyState"]
  
  connect() {
    this.originalProducts = [...this.productsValue]
    this.currentSort = "name"
    this.currentDirection = "asc"
    this.currentFilter = "all"
    
    // Initialize animations
    this.initializeAnimations()
    
    console.log("Enhanced Product List connected", {
      products: this.productsValue.length,
      sortable: this.sortableValue,
      filterable: this.filterableValue
    })
  }
  
  // Animation Methods
  initializeAnimations() {
    // Trigger staggered fade-in animation for product cards
    this.productCardTargets.forEach((card, index) => {
      setTimeout(() => {
        card.classList.remove("opacity-0", "translate-y-4")
        card.classList.add("opacity-100", "translate-y-0")
      }, index * 100)
    })
  }
  
  animateCardsIn() {
    this.productCardTargets.forEach((card, index) => {
      card.classList.add("opacity-0", "translate-y-4")
      setTimeout(() => {
        card.classList.remove("opacity-0", "translate-y-4")
        card.classList.add("opacity-100", "translate-y-0")
      }, index * 50)
    })
  }
  
  // Sorting Methods
  sort(event) {
    if (!this.sortableValue) return
    
    const sortBy = event.target.value
    this.currentSort = sortBy
    this.applySortAndFilter()
  }
  
  toggleDirection(event) {
    if (!this.sortableValue) return
    
    this.currentDirection = this.currentDirection === "asc" ? "desc" : "asc"
    
    // Update button visual feedback
    const button = event.target.closest("button")
    const svg = button.querySelector("svg")
    if (this.currentDirection === "desc") {
      svg.style.transform = "rotate(180deg)"
    } else {
      svg.style.transform = "rotate(0deg)"
    }
    
    this.applySortAndFilter()
  }
  
  // Filtering Methods
  filterByColor(event) {
    if (!this.filterableValue) return
    
    const color = event.target.dataset.color
    this.currentFilter = color
    
    // Update active filter button
    const filterButtons = event.target.parentElement.querySelectorAll("button")
    filterButtons.forEach(btn => {
      btn.classList.remove("bg-blue-100", "text-blue-800", "border-blue-300")
      btn.classList.add("border-gray-300", "hover:bg-gray-50")
    })
    
    event.target.classList.remove("border-gray-300", "hover:bg-gray-50")
    event.target.classList.add("bg-blue-100", "text-blue-800", "border-blue-300")
    
    this.applySortAndFilter()
  }
  
  // Core Logic
  applySortAndFilter() {
    let filteredProducts = [...this.originalProducts]
    
    // Apply filter
    if (this.currentFilter !== "all") {
      filteredProducts = filteredProducts.filter(product => 
        this.getProductColor(product) === this.currentFilter
      )
    }
    
    // Apply sort
    filteredProducts.sort((a, b) => {
      let aValue = this.getProductValue(a, this.currentSort)
      let bValue = this.getProductValue(b, this.currentSort)
      
      // Handle numeric values
      if (this.currentSort === "price") {
        aValue = parseFloat(aValue) || 0
        bValue = parseFloat(bValue) || 0
      } else {
        // Handle string values
        aValue = String(aValue).toLowerCase()
        bValue = String(bValue).toLowerCase()
      }
      
      let comparison = 0
      if (aValue < bValue) comparison = -1
      if (aValue > bValue) comparison = 1
      
      return this.currentDirection === "desc" ? -comparison : comparison
    })
    
    // Update display
    this.updateProductDisplay(filteredProducts)
    
    // Show/hide empty state
    if (filteredProducts.length === 0) {
      this.showEmptyState()
    } else {
      this.hideEmptyState()
    }
  }
  
  updateProductDisplay(products) {
    // Fade out current cards
    this.productCardTargets.forEach(card => {
      card.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
      card.style.opacity = "0"
      card.style.transform = "translateY(20px)"
    })
    
    setTimeout(() => {
      // Update the products data
      this.productsValue = products
      
      // Re-render would happen here in a real implementation
      // For now, we'll just show/hide existing cards based on data-product-id
      this.productCardTargets.forEach(card => {
        const productId = card.dataset.productId
        const isVisible = products.some(p => String(this.getProductId(p)) === String(productId))
        
        if (isVisible) {
          card.style.display = "block"
          setTimeout(() => {
            card.style.opacity = "1"
            card.style.transform = "translateY(0)"
          }, 50)
        } else {
          card.style.display = "none"
        }
      })
      
      // Trigger staggered animation for visible cards
      const visibleCards = this.productCardTargets.filter(card => 
        card.style.display !== "none"
      )
      
      visibleCards.forEach((card, index) => {
        setTimeout(() => {
          card.style.opacity = "1"
          card.style.transform = "translateY(0)"
        }, index * 50)
      })
    }, 300)
  }
  
  showEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.remove("hidden")
      this.emptyStateTarget.classList.add("animate-fade-in")
    }
  }
  
  hideEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add("hidden")
      this.emptyStateTarget.classList.remove("animate-fade-in")
    }
  }
  
  // Quick Actions
  quickView(event) {
    const productId = event.target.closest("button").dataset.productId
    console.log("Quick view for product:", productId)
    
    // Add visual feedback
    this.addButtonFeedback(event.target.closest("button"))
    
    // Dispatch custom event for parent components to handle
    this.dispatch("quickView", { detail: { productId } })
  }
  
  addToCart(event) {
    const productId = event.target.closest("button").dataset.productId
    console.log("Add to cart for product:", productId)
    
    // Add visual feedback
    this.addButtonFeedback(event.target.closest("button"))
    
    // Dispatch custom event
    this.dispatch("addToCart", { detail: { productId } })
  }
  
  addButtonFeedback(button) {
    button.classList.add("scale-90")
    setTimeout(() => {
      button.classList.remove("scale-90")
      button.classList.add("scale-110")
      setTimeout(() => {
        button.classList.remove("scale-110")
      }, 150)
    }, 100)
  }
  
  // Utility Methods
  getProductValue(product, field) {
    switch (field) {
      case "name":
        return product.name || product.title || ""
      case "price":
        return product.price || 0
      case "color":
        return product.color || product.variant || ""
      default:
        return product[field] || ""
    }
  }
  
  getProductColor(product) {
    return product.color || product.variant || ""
  }
  
  getProductId(product) {
    return product.id || ""
  }
  
  // Search functionality (bonus)
  search(event) {
    const query = event.target.value.toLowerCase().trim()
    
    let filteredProducts = this.originalProducts.filter(product => {
      const name = this.getProductValue(product, "name").toLowerCase()
      const color = this.getProductColor(product).toLowerCase()
      return name.includes(query) || color.includes(query)
    })
    
    this.updateProductDisplay(filteredProducts)
  }
}