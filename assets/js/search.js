(function() {
  let searchInput, clearButton, resultsCount, items;

  // Debounce function
  function debounce(fn, delay) {
    let timeoutId;
    return function(...args) {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => fn.apply(this, args), delay);
    };
  }

  // Read each post's title and tags from the list itself. Matching rows of
  // search.json to <li>s by position broke whenever the two lists differed,
  // e.g. under `jekyll serve --drafts`, where drafts are listed but not indexed.
  function indexItems(postList) {
    return Array.from(postList.children).filter(el => el.tagName === 'LI').map(li => {
      const link = li.querySelector('.post-link');
      return {
        li,
        title: (link ? link.textContent : '').toLowerCase(),
        tags: Array.from(li.querySelectorAll('.post-tags a')).map(a => a.textContent.toLowerCase())
      };
    });
  }

  // Filter posts by search query
  function filterPosts(query) {
    const normalizedQuery = query.toLowerCase().trim();

    if (!normalizedQuery) {
      showAllPosts();
      return;
    }

    let visibleCount = 0;
    items.forEach(item => {
      const isVisible = item.title.includes(normalizedQuery) ||
        item.tags.some(tag => tag.includes(normalizedQuery));
      item.li.classList.toggle('hidden', !isVisible);
      if (isVisible) visibleCount++;
    });

    updateResultsCount(visibleCount, items.length);
  }

  // Show all posts
  function showAllPosts() {
    items.forEach(item => item.li.classList.remove('hidden'));
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

  // Keep ?q= in the address bar in step with the input, so a filtered list
  // can be shared and the SearchAction advertised in the JSON-LD resolves.
  function syncQueryParam(value) {
    const url = new URL(window.location.href);
    if (value.trim()) {
      url.searchParams.set('q', value);
    } else {
      url.searchParams.delete('q');
    }
    window.history.replaceState(null, '', url);
  }

  function applyQuery() {
    filterPosts(searchInput.value);
    clearButton.classList.toggle('visible', searchInput.value.length > 0);
    syncQueryParam(searchInput.value);
  }

  // Clear search
  function clearSearch() {
    searchInput.value = '';
    applyQuery();
    searchInput.focus();
  }

  // Initialize search
  function init() {
    searchInput = document.getElementById('search-input');
    clearButton = document.getElementById('search-clear');
    resultsCount = document.getElementById('search-results-count');
    const postList = document.querySelector('.post-list');

    if (!searchInput || !postList) return;

    items = indexItems(postList);

    // Search input handler (debounced)
    searchInput.addEventListener('input', debounce(applyQuery, 150));

    // Clear button handler
    clearButton.addEventListener('click', clearSearch);

    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
      // "/" to focus search, unless the user is already typing somewhere
      const target = e.target;
      const typing = target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName);
      if (e.key === '/' && !typing && !e.metaKey && !e.ctrlKey && !e.altKey) {
        e.preventDefault();
        searchInput.focus();
      }
      // Escape to clear search
      if (e.key === 'Escape' && document.activeElement === searchInput) {
        clearSearch();
        searchInput.blur();
      }
    });

    // Apply a query passed in the URL (/?q=hotwire)
    const initial = new URLSearchParams(window.location.search).get('q');
    if (initial) {
      searchInput.value = initial;
      applyQuery();
    }
  }

  // Run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
