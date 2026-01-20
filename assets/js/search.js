(function() {
  let posts = [];
  let searchInput, clearButton, resultsCount, postList;

  // Debounce function
  function debounce(fn, delay) {
    let timeoutId;
    return function(...args) {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => fn.apply(this, args), delay);
    };
  }

  // Load posts data
  async function loadPosts() {
    try {
      const response = await fetch('/search.json');
      posts = await response.json();
    } catch (error) {
      console.error('Failed to load search data:', error);
    }
  }

  // Filter posts by search query
  function filterPosts(query) {
    const normalizedQuery = query.toLowerCase().trim();

    if (!normalizedQuery) {
      showAllPosts();
      return;
    }

    let visibleCount = 0;
    const postItems = postList.querySelectorAll('li');

    posts.forEach((post, index) => {
      const matchesTitle = post.title.toLowerCase().includes(normalizedQuery);
      const matchesTags = post.tags && post.tags.some(tag =>
        tag.toLowerCase().includes(normalizedQuery)
      );

      const isVisible = matchesTitle || matchesTags;

      if (postItems[index]) {
        postItems[index].classList.toggle('hidden', !isVisible);
        if (isVisible) visibleCount++;
      }
    });

    updateResultsCount(visibleCount, posts.length);
  }

  // Show all posts
  function showAllPosts() {
    const postItems = postList.querySelectorAll('li');
    postItems.forEach(item => item.classList.remove('hidden'));
    resultsCount.textContent = '';
  }

  // Update results count display
  function updateResultsCount(visible, total) {
    if (visible === total) {
      resultsCount.textContent = '';
    } else {
      resultsCount.textContent = `Showing ${visible} of ${total} posts`;
    }
  }

  // Clear search
  function clearSearch() {
    searchInput.value = '';
    clearButton.classList.remove('visible');
    showAllPosts();
    searchInput.focus();
  }

  // Initialize search
  function init() {
    searchInput = document.getElementById('search-input');
    clearButton = document.getElementById('search-clear');
    resultsCount = document.getElementById('search-results-count');
    postList = document.querySelector('.post-list');

    if (!searchInput || !postList) return;

    loadPosts();

    // Search input handler (debounced)
    const debouncedFilter = debounce(function() {
      filterPosts(searchInput.value);
      clearButton.classList.toggle('visible', searchInput.value.length > 0);
    }, 150);

    searchInput.addEventListener('input', debouncedFilter);

    // Clear button handler
    clearButton.addEventListener('click', clearSearch);

    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
      // "/" to focus search
      if (e.key === '/' && document.activeElement !== searchInput) {
        e.preventDefault();
        searchInput.focus();
      }
      // Escape to clear search
      if (e.key === 'Escape' && document.activeElement === searchInput) {
        clearSearch();
        searchInput.blur();
      }
    });
  }

  // Run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
