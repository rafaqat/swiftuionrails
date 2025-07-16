// Playground Data Manager with compression and caching
export class PlaygroundDataManager {
  constructor() {
    this.cache = {};
    this.cacheKey = 'playground_data_v1';
    this.cacheExpiry = 24 * 60 * 60 * 1000; // 24 hours
  }

  // Decompress data (simplified - no pako in V2)
  decompressData(compressedBase64) {
    try {
      // For V2, we'll rely on server-side data instead of compressed files
      console.warn('Decompression not implemented in V2 - using server data');
      return null;
    } catch (error) {
      console.error('Failed to decompress data:', error);
      return null;
    }
  }

  // Get signature data with caching
  async getSignatureData() {
    const cachedData = this.getCachedData('signatures');
    if (cachedData) return cachedData;

    try {
      const response = await fetch('/compressed_signatures.json');
      const { compressed } = await response.json();
      const data = this.decompressData(compressed);
      
      if (data) {
        this.setCachedData('signatures', data);
      }
      return data;
    } catch (error) {
      console.error('Failed to fetch signature data:', error);
      return null;
    }
  }

  // Get completion data with caching
  async getCompletionData() {
    const cachedData = this.getCachedData('completions');
    if (cachedData) return cachedData;

    try {
      const response = await fetch('/compressed_completions.json');
      const { compressed } = await response.json();
      const data = this.decompressData(compressed);
      
      if (data) {
        this.setCachedData('completions', data);
      }
      return data;
    } catch (error) {
      console.error('Failed to fetch completion data:', error);
      return null;
    }
  }

  // Cache management
  getCachedData(key) {
    try {
      const stored = sessionStorage.getItem(`${this.cacheKey}_${key}`);
      if (!stored) return null;

      const { data, timestamp } = JSON.parse(stored);
      const isExpired = Date.now() - timestamp > this.cacheExpiry;
      
      if (isExpired) {
        sessionStorage.removeItem(`${this.cacheKey}_${key}`);
        return null;
      }

      return data;
    } catch (error) {
      console.error('Cache read error:', error);
      return null;
    }
  }

  setCachedData(key, data) {
    try {
      const cacheData = {
        data: data,
        timestamp: Date.now()
      };
      sessionStorage.setItem(`${this.cacheKey}_${key}`, JSON.stringify(cacheData));
    } catch (error) {
      console.error('Cache write error:', error);
      // If storage is full, clear old data
      if (error.name === 'QuotaExceededError') {
        this.clearCache();
      }
    }
  }

  clearCache() {
    const keys = Object.keys(sessionStorage);
    keys.forEach(key => {
      if (key.startsWith(this.cacheKey)) {
        sessionStorage.removeItem(key);
      }
    });
  }

  // Preload all data
  async preloadAll() {
    console.log('Preloading playground data...');
    await Promise.all([
      this.getSignatureData(),
      this.getCompletionData()
    ]);
    console.log('All playground data preloaded');
  }
}

// Create and export default instance
const playgroundDataManager = new PlaygroundDataManager();
export default playgroundDataManager;