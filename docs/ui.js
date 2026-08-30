// Wires the recommender logic in app.js to the page: loads the bundled sample snapshot,
// builds the champion picker, and re-renders results whenever the role or the
// already-picked/banned set changes.
(function () {
  const { parseSnapshot, topChampions, recommendForRole } = window.lolScout;

  const state = {
    rows: [],
    role: 'mid',
    unavailable: new Set(), // champions already picked or banned this draft
  };

  const el = {
    status: document.getElementById('status'),
    body: document.getElementById('recommender-body'),
    roleButtons: document.getElementById('role-buttons'),
    champList: document.getElementById('champion-list'),
    champSearch: document.getElementById('champion-search'),
    unavailableCount: document.getElementById('unavailable-count'),
    clearUnavailable: document.getElementById('clear-unavailable'),
    topFive: document.getElementById('top-five'),
    topRole: document.getElementById('top-role'),
    topRoleLabel: document.getElementById('top-role-label'),
  };

  function renderResults() {
    const exclude = [...state.unavailable];

    el.topFive.innerHTML = '';
    topChampions(state.rows, 5).forEach((name, i) => {
      el.topFive.appendChild(resultItem(i + 1, name));
    });

    el.topRoleLabel.textContent = state.role;
    el.topRole.innerHTML = '';
    const picks = recommendForRole(state.rows, state.role, exclude, 3);
    if (picks.length === 0) {
      const li = document.createElement('li');
      li.className = 'empty';
      li.textContent = 'No champions left for this role with the current exclusions.';
      el.topRole.appendChild(li);
    } else {
      picks.forEach((name, i) => el.topRole.appendChild(resultItem(i + 1, name)));
    }

    el.unavailableCount.textContent = state.unavailable.size;
  }

  function resultItem(rank, name) {
    const li = document.createElement('li');
    li.innerHTML = `<span class="rank">${rank}</span><span class="champ-name">${name}</span>`;
    return li;
  }

  function renderChampionList(filter) {
    const q = (filter || '').trim().toLowerCase();
    el.champList.innerHTML = '';
    state.rows
      .map((row) => row.Name)
      .filter((name) => name.includes(q))
      .sort()
      .forEach((name) => {
        const id = `champ-${name.replace(/[^a-z0-9]/g, '-')}`;
        const label = document.createElement('label');
        label.className = 'champion-checkbox';
        label.htmlFor = id;
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.id = id;
        checkbox.checked = state.unavailable.has(name);
        checkbox.addEventListener('change', () => {
          if (checkbox.checked) state.unavailable.add(name);
          else state.unavailable.delete(name);
          renderResults();
        });
        label.appendChild(checkbox);
        label.appendChild(document.createTextNode(name));
        el.champList.appendChild(label);
      });
  }

  function setRole(role) {
    state.role = role;
    [...el.roleButtons.children].forEach((btn) => {
      btn.setAttribute('aria-pressed', String(btn.dataset.role === role));
    });
    renderResults();
  }

  el.roleButtons.addEventListener('click', (event) => {
    const btn = event.target.closest('button[data-role]');
    if (btn) setRole(btn.dataset.role);
  });

  el.champSearch.addEventListener('input', () => renderChampionList(el.champSearch.value));

  el.clearUnavailable.addEventListener('click', () => {
    state.unavailable.clear();
    renderChampionList(el.champSearch.value);
    renderResults();
  });

  fetch('data/champInfoVersionCSV.csv')
    .then((response) => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response.text();
    })
    .then((csvText) => {
      state.rows = parseSnapshot(csvText);
      el.status.remove();
      el.body.style.display = '';
      renderChampionList('');
      setRole(state.role);
    })
    .catch((err) => {
      el.status.textContent = `Couldn't load the sample data (${err.message}). ` +
        'Try opening this page through GitHub Pages rather than as a local file — ' +
        'browsers block fetch() on file:// URLs.';
      el.status.classList.add('error');
    });
})();
