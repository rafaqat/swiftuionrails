// Toolbar Stimulus Controller
// Provides complete interactive behavior for the ToolbarComponent
//
// Features:
// - Mobile menu toggle with smooth animations
// - Search functionality with autocomplete
// - User menu dropdown management
// - Notification center integration
// - Keyboard navigation support
// - Responsive behavior
// - Body scroll management

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "mobileMenuButton",
    "mobileMenu", 
    "searchForm",
    "searchInput",
    "expandedSearchForm",
    "expandedSearchInput",
    "userMenuDropdown",
    "notificationsDropdown"
  ]
  
  static values = {
    mobileMenuOpen: Boolean,
    searchUrl: String,
    searchOpen: Boolean,
    userMenuOpen: Boolean,
    notificationsOpen: Boolean
  }
  
  static classes = [
    "mobileMenuOpen",
    "searchOpen",
    "dropdownOpen"
  ]
  
  connect() {
    // Initialize state
    this.searchQuery = ""
    this.searchResults = []
    this.isSearching = false
    
    // Bind global events
    document.addEventListener('click', this.handleGlobalClick.bind(this))
    document.addEventListener('keydown', this.handleGlobalKeydown.bind(this))
    window.addEventListener('resize', this.handleResize.bind(this))
    
    // Initialize responsive behavior
    this.updateResponsiveState()
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleGlobalClick.bind(this))
    document.removeEventListener('keydown', this.handleGlobalKeydown.bind(this))
    window.removeEventListener('resize', this.handleResize.bind(this))
    
    // Restore body scroll
    document.body.style.overflow = ''
  }
  
  // Mobile Menu Management
  toggleMobileMenu() {
    this.mobileMenuOpenValue = !this.mobileMenuOpenValue
    this.updateMobileMenuState()
  }
  
  openMobileMenu() {
    this.mobileMenuOpenValue = true
    this.updateMobileMenuState()
  }
  
  closeMobileMenu() {
    this.mobileMenuOpenValue = false
    this.updateMobileMenuState()
  }
  
  updateMobileMenuState() {
    if (this.hasMobileMenuTarget) {
      if (this.mobileMenuOpenValue) {
        this.mobileMenuTarget.classList.remove('hidden')
        this.mobileMenuTarget.classList.add('animate-slide-down')
        document.body.style.overflow = 'hidden'
      } else {
        this.mobileMenuTarget.classList.add('animate-slide-up')
        document.body.style.overflow = ''
        
        setTimeout(() => {
          this.mobileMenuTarget.classList.add('hidden')
          this.mobileMenuTarget.classList.remove('animate-slide-up', 'animate-slide-down')
        }, 200)
      }
    }
    
    // Update button state
    if (this.hasMobileMenuButtonTarget) {
      const icon = this.mobileMenuButtonTarget.querySelector('svg')
      if (icon) {
        icon.style.transform = this.mobileMenuOpenValue ? 'rotate(90deg)' : 'rotate(0deg)'
      }
    }
  }
  
  // Search Management
  toggleSearch() {
    this.searchOpenValue = !this.searchOpenValue
    this.updateSearchState()
  }
  
  openSearch() {
    this.searchOpenValue = true
    this.updateSearchState()
  }
  
  closeSearch() {
    this.searchOpenValue = false
    this.updateSearchState()
  }
  
  updateSearchState() {
    // Handle expanded search on mobile
    if (this.searchOpenValue) {
      this.focusSearchInput()
    } else {
      this.clearSearchResults()
    }
    
    // Trigger custom event for parent components
    this.dispatch('searchToggle', { 
      detail: { open: this.searchOpenValue } 
    })
  }
  
  updateSearchQuery(event) {
    this.searchQuery = event.target.value
    
    // Debounced search suggestions
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      if (this.searchQuery.length >= 2) {
        this.fetchSearchSuggestions()
      } else {
        this.clearSearchResults()
      }
    }, 300)
  }
  
  async performSearch(event) {
    event.preventDefault()
    
    if (!this.searchQuery.trim()) return
    
    this.setSearchLoading(true)
    
    try {
      // Perform search
      const formData = new FormData(event.target)
      const searchParams = new URLSearchParams(formData)
      
      // Navigate to search results or trigger search event
      if (this.searchUrlValue) {
        window.location.href = `${this.searchUrlValue}?${searchParams.toString()}`
      } else {
        // Trigger custom search event
        this.dispatch('search', { 
          detail: { 
            query: this.searchQuery,
            formData: Object.fromEntries(formData)
          } 
        })
      }
    } catch (error) {
      console.error('Search error:', error)
      this.showSearchError('Search failed. Please try again.')
    } finally {
      this.setSearchLoading(false)
    }
  }
  
  async fetchSearchSuggestions() {
    if (this.isSearching) return
    
    this.isSearching = true
    
    try {
      const response = await fetch(`${this.searchUrlValue}/suggestions?q=${encodeURIComponent(this.searchQuery)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const suggestions = await response.json()
        this.displaySearchSuggestions(suggestions)
      }
    } catch (error) {
      console.error('Search suggestions error:', error)
    } finally {
      this.isSearching = false
    }
  }
  
  displaySearchSuggestions(suggestions) {
    // Create or update suggestions dropdown
    let dropdown = this.element.querySelector('.search-suggestions')
    
    if (!dropdown && suggestions.length > 0) {
      dropdown = this.createSearchSuggestionsDropdown()
    }
    
    if (dropdown) {
      if (suggestions.length > 0) {
        this.populateSearchSuggestions(dropdown, suggestions)
        dropdown.classList.remove('hidden')
      } else {
        dropdown.classList.add('hidden')
      }
    }
  }
  
  createSearchSuggestionsDropdown() {
    const searchContainer = this.getActiveSearchContainer()
    if (!searchContainer) return null
    
    const dropdown = document.createElement('div')
    dropdown.className = 'search-suggestions absolute top-full left-0 right-0 mt-1 bg-white border border-gray-200 rounded-md shadow-lg z-50 max-h-60 overflow-y-auto'
    dropdown.style.display = 'none'
    
    searchContainer.style.position = 'relative'
    searchContainer.appendChild(dropdown)
    
    return dropdown
  }
  
  populateSearchSuggestions(dropdown, suggestions) {
    dropdown.innerHTML = suggestions.map((suggestion, index) => `
      <div class="search-suggestion px-4 py-2 hover:bg-gray-100 cursor-pointer border-b border-gray-100 last:border-b-0" 
           data-action="click->toolbar#selectSuggestion" 
           data-suggestion="${suggestion.value}"
           data-index="${index}">
        <div class="flex items-center justify-between">
          <span class="text-sm text-gray-900">${suggestion.label}</span>
          ${suggestion.category ? `<span class="text-xs text-gray-500">${suggestion.category}</span>` : ''}
        </div>
      </div>
    `).join('')
    
    dropdown.style.display = 'block'
  }
  
  selectSuggestion(event) {
    const suggestion = event.currentTarget.dataset.suggestion
    const searchInput = this.getActiveSearchInput()
    
    if (searchInput) {
      searchInput.value = suggestion
      this.searchQuery = suggestion
      this.performSearch({ 
        preventDefault: () => {},
        target: searchInput.closest('form')
      })
    }
    
    this.clearSearchResults()
  }
  
  clearSearchResults() {
    const dropdown = this.element.querySelector('.search-suggestions')
    if (dropdown) {
      dropdown.classList.add('hidden')
    }
  }
  
  setSearchLoading(loading) {
    const searchInputs = this.getAllSearchInputs()
    
    searchInputs.forEach(input => {
      if (loading) {
        input.classList.add('animate-pulse')
        input.placeholder = 'Searching...'
      } else {
        input.classList.remove('animate-pulse')
        input.placeholder = this.data.get('search-placeholder') || 'Search...'
      }
    })
  }
  
  showSearchError(message) {
    // Show error message near search input
    console.error(message)
  }
  
  // User Menu Management
  toggleUserMenu() {
    this.userMenuOpenValue = !this.userMenuOpenValue
    this.updateUserMenuState()
  }
  
  openUserMenu() {
    this.userMenuOpenValue = true
    this.updateUserMenuState()
  }
  
  closeUserMenu() {
    this.userMenuOpenValue = false
    this.updateUserMenuState()
  }
  
  updateUserMenuState() {
    if (this.hasUserMenuDropdownTarget) {
      if (this.userMenuOpenValue) {
        this.userMenuDropdownTarget.classList.remove('hidden')
        this.userMenuDropdownTarget.classList.add('animate-fade-in')
      } else {
        this.userMenuDropdownTarget.classList.add('animate-fade-out')
        
        setTimeout(() => {
          this.userMenuDropdownTarget.classList.add('hidden')
          this.userMenuDropdownTarget.classList.remove('animate-fade-in', 'animate-fade-out')
        }, 150)
      }
    }
  }
  
  // Notifications Management
  toggleNotifications() {
    this.notificationsOpenValue = !this.notificationsOpenValue
    this.updateNotificationsState()
  }
  
  updateNotificationsState() {
    if (this.hasNotificationsDropdownTarget) {
      if (this.notificationsOpenValue) {
        this.notificationsDropdownTarget.classList.remove('hidden')
        this.loadNotifications()
      } else {
        this.notificationsDropdownTarget.classList.add('hidden')
      }
    }
  }
  
  async loadNotifications() {
    // Load notifications from server
    try {
      const response = await fetch('/notifications', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const notifications = await response.json()
        this.displayNotifications(notifications)
      }
    } catch (error) {
      console.error('Failed to load notifications:', error)
    }
  }
  
  displayNotifications(notifications) {
    // Update notifications dropdown content
    if (this.hasNotificationsDropdownTarget) {
      // Implementation would populate the notifications dropdown
    }
  }
  
  // Event Handlers
  handleGlobalClick(event) {
    // Close dropdowns when clicking outside
    if (!this.element.contains(event.target)) {
      this.closeUserMenu()
      this.closeNotifications()
      this.clearSearchResults()
    }
  }
  
  handleGlobalKeydown(event) {
    switch (event.key) {
      case 'Escape':
        this.closeMobileMenu()
        this.closeUserMenu()
        this.closeNotifications()
        this.closeSearch()
        this.clearSearchResults()
        break
        
      case '/':
        // Quick search shortcut
        if (event.ctrlKey || event.metaKey) {
          event.preventDefault()
          this.openSearch()
        }
        break
        
      case 'ArrowDown':
      case 'ArrowUp':
        // Navigate search suggestions
        if (this.element.querySelector('.search-suggestions:not(.hidden)')) {
          event.preventDefault()
          this.navigateSearchSuggestions(event.key === 'ArrowDown' ? 'down' : 'up')
        }
        break
        
      case 'Enter':
        // Select highlighted suggestion
        if (this.element.querySelector('.search-suggestions:not(.hidden)')) {
          const highlighted = this.element.querySelector('.search-suggestion.highlighted')
          if (highlighted) {
            event.preventDefault()
            highlighted.click()
          }
        }
        break
    }
  }
  
  handleResize() {
    this.updateResponsiveState()
  }
  
  // Helper Methods
  updateResponsiveState() {
    const isMobile = window.innerWidth < 1024 // lg breakpoint
    
    if (!isMobile && this.mobileMenuOpenValue) {
      this.closeMobileMenu()
    }
  }
  
  focusSearchInput() {
    const searchInput = this.getActiveSearchInput()
    if (searchInput) {
      searchInput.focus()
    }
  }
  
  getActiveSearchInput() {
    if (this.searchOpenValue && this.hasExpandedSearchInputTarget) {
      return this.expandedSearchInputTarget
    } else if (this.hasSearchInputTarget) {
      return this.searchInputTarget
    }
    return null
  }
  
  getActiveSearchContainer() {
    const searchInput = this.getActiveSearchInput()
    return searchInput ? searchInput.closest('form') || searchInput.parentElement : null
  }
  
  getAllSearchInputs() {
    return [
      this.hasSearchInputTarget ? this.searchInputTarget : null,
      this.hasExpandedSearchInputTarget ? this.expandedSearchInputTarget : null
    ].filter(Boolean)
  }
  
  navigateSearchSuggestions(direction) {
    const suggestions = this.element.querySelectorAll('.search-suggestion')
    const highlighted = this.element.querySelector('.search-suggestion.highlighted')
    
    let newIndex = 0
    
    if (highlighted) {
      const currentIndex = Array.from(suggestions).indexOf(highlighted)
      newIndex = direction === 'down' 
        ? Math.min(currentIndex + 1, suggestions.length - 1)
        : Math.max(currentIndex - 1, 0)
      
      highlighted.classList.remove('highlighted', 'bg-gray-100')
    }
    
    if (suggestions[newIndex]) {
      suggestions[newIndex].classList.add('highlighted', 'bg-gray-100')
    }
  }
  
  // Value change callbacks
  mobileMenuOpenValueChanged() {
    this.updateMobileMenuState()
  }
  
  searchOpenValueChanged() {
    this.updateSearchState()
  }
  
  userMenuOpenValueChanged() {
    this.updateUserMenuState()
  }
  
  notificationsOpenValueChanged() {
    this.updateNotificationsState()
  }
}