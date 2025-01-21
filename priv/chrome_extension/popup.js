document.addEventListener('DOMContentLoaded', function() {
  // Get current tab URL
  chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
    const currentTab = tabs[0];

    // Pre-fill form with page details
    document.getElementById('title').value = currentTab.title || '';

    // Handle form submission
    document.getElementById('bookmarkForm').addEventListener('submit', function(e) {
      e.preventDefault();

      const bookmark = {
        title: document.getElementById('title').value,
        url: currentTab.url,
        description: document.getElementById('description').value,
        tags: document.getElementById('tags').value,
        public: true
      };

      saveBookmark(bookmark);
    });
  });
});

async function saveBookmark(bookmark) {
  const statusDiv = document.getElementById('status');
  try {
    console.log('Sending bookmark:', bookmark);

    const response = await fetch('http://localhost:4000/api/bookmarks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({ bookmark }),
    });

    console.log('Response status:', response.status);

    // Log the raw response text first
    const responseText = await response.text();
    console.log('Raw response:', responseText);

    let data;
    try {
      data = JSON.parse(responseText);
    } catch (e) {
      console.error('Failed to parse response as JSON:', e);
      throw new Error('Server returned invalid JSON');
    }

    if (!response.ok) {
      console.error('Error response:', data);
      throw new Error(JSON.stringify(data.errors || data.error || 'Unknown error'));
    }

    statusDiv.style.color = '#00ff00';
    statusDiv.textContent = 'Bookmark saved!';
    setTimeout(() => window.close(), 1000);
  } catch (error) {
    console.error('Error:', error);
    statusDiv.textContent = `Error: ${error.message}`;
  }
}