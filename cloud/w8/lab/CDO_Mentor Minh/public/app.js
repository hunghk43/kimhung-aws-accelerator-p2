const appNameElement = document.getElementById('appName');
const dbStatusElement = document.getElementById('dbStatus');
const bucketStatusElement = document.getElementById('bucketStatus');
const notesListElement = document.getElementById('notesList');
const noteFormElement = document.getElementById('noteForm');
const noteInputElement = document.getElementById('noteInput');
const emptyStateTemplate = document.getElementById('emptyStateTemplate');

function formatCreatedAt(value) {
  if (!value) {
    return '';
  }

  return new Intl.DateTimeFormat('vi-VN', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function renderNotes(notes) {
  notesListElement.innerHTML = '';

  if (!notes || notes.length === 0) {
    notesListElement.appendChild(emptyStateTemplate.content.cloneNode(true));
    return;
  }

  for (const note of notes) {
    const article = document.createElement('article');
    article.className = 'note-item';

    const content = document.createElement('div');
    content.className = 'note-content';
    content.textContent = note.content;

    const meta = document.createElement('div');
    meta.className = 'note-meta';
    meta.textContent = formatCreatedAt(note.created_at);

    article.append(content, meta);
    notesListElement.appendChild(article);
  }
}

async function loadMeta() {
  const response = await fetch('/api/meta');
  const meta = await response.json();

  appNameElement.textContent = meta.appName;
  dbStatusElement.textContent = `DB: ${meta.dbReady ? 'ready' : 'local fallback'}`;
  bucketStatusElement.textContent = `S3 bucket: ${meta.s3Bucket}`;
}

async function loadNotes() {
  const response = await fetch('/api/notes');
  const data = await response.json();
  renderNotes(data.notes);
}

noteFormElement.addEventListener('submit', async (event) => {
  event.preventDefault();

  const content = noteInputElement.value.trim();

  if (!content) {
    return;
  }

  const response = await fetch('/api/notes', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ content }),
  });

  if (!response.ok) {
    return;
  }

  noteInputElement.value = '';
  await loadNotes();
});

Promise.all([loadMeta(), loadNotes()]).catch((error) => {
  console.error(error);
  notesListElement.innerHTML = '<p class="empty-state">Không tải được dữ liệu.</p>';
});