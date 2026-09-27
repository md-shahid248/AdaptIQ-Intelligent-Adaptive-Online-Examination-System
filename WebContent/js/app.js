/* =============================================
   AdaptExam — Client-Side JavaScript
   ============================================= */

// ── Flash message auto-dismiss ────────────────
document.addEventListener('DOMContentLoaded', () => {
  const flash = document.querySelector('.alert');
  if (flash) {
    setTimeout(() => {
      flash.style.transition = 'opacity 0.5s ease';
      flash.style.opacity = '0';
      setTimeout(() => flash.remove(), 500);
    }, 3500);
  }
});

// ── Form Validation ───────────────────────────
function validateLogin() {
  const email    = document.getElementById('email')?.value?.trim();
  const password = document.getElementById('password')?.value;
  const emailRx  = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!email || !emailRx.test(email)) {
    showToast('Please enter a valid email address.', 'error');
    return false;
  }
  if (!password || password.length < 6) {
    showToast('Password must be at least 6 characters.', 'error');
    return false;
  }
  return true;
}

function validateAddUser() {
  const name     = document.getElementById('name')?.value?.trim();
  const email    = document.getElementById('email')?.value?.trim();
  const password = document.getElementById('password')?.value;
  const role     = document.getElementById('role')?.value;
  const emailRx  = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!name || name.length < 2) { showToast('Name must be at least 2 characters.', 'error'); return false; }
  if (!email || !emailRx.test(email)) { showToast('Enter a valid email.', 'error'); return false; }
  if (!password || password.length < 6) { showToast('Password must be at least 6 characters.', 'error'); return false; }
  if (!role) { showToast('Please select a role.', 'error'); return false; }
  return true;
}

function validateCreateExam() {
  const title    = document.getElementById('title')?.value?.trim();
  const subject  = document.getElementById('subjectId')?.value;
  const duration = parseInt(document.getElementById('durationMins')?.value);
  const total    = parseInt(document.getElementById('totalQuestions')?.value);

  if (!title || title.length < 3) { showToast('Exam title must be at least 3 characters.', 'error'); return false; }
  if (!subject) { showToast('Please select a subject.', 'error'); return false; }
  if (isNaN(duration) || duration < 5 || duration > 180) { showToast('Duration must be between 5 and 180 minutes.', 'error'); return false; }
  if (isNaN(total) || total < 1 || total > 100) { showToast('Total questions must be between 1 and 100.', 'error'); return false; }
  return true;
}

function validateAddQuestion() {
  const fields = [
    ['questionText', 'Question text'],
    ['optionA', 'Option A'], ['optionB', 'Option B'],
    ['optionC', 'Option C'], ['optionD', 'Option D']
  ];
  for (const [id, label] of fields) {
    const el = document.getElementById(id);
    if (!el || !el.value.trim()) {
      showToast(`${label} is required.`, 'error');
      return false;
    }
  }
  const answer = document.getElementById('correctAnswer')?.value;
  if (!answer) { showToast('Please select the correct answer.', 'error'); return false; }
  return true;
}

// ── Icon rendering ────────────────────────────
// Lucide swaps each <i data-lucide> for an inline <svg>, so markup injected
// after a page's own createIcons() call has to be re-scanned. Guarded because
// the icon script is a CDN load — a failed load must never break exam flow.
function renderIcons() {
  if (window.lucide) lucide.createIcons();
}

// ── Toast Notification ────────────────────────
// Styles live in css/style.css (.toast, .toast-error/success/info,
// .toast-icon, @keyframes slideIn) — see the Toast Notification section there.
function showToast(message, type = 'info') {
  const existing = document.querySelector('.toast');
  if (existing) existing.remove();

  const icon = type === 'error' ? 'triangle-alert' : type === 'success' ? 'circle-check' : 'info';
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <span class="toast-icon"><i data-lucide="${icon}" style="width:18px;height:18px"></i></span>
    <span>${message}</span>
  `;

  document.body.appendChild(toast);
  renderIcons();
  setTimeout(() => { toast.style.transition = 'opacity 0.4s'; toast.style.opacity = '0'; setTimeout(() => toast.remove(), 400); }, 3000);
}

// ── Confirm Delete ────────────────────────────
function confirmDelete(formId, message) {
  const msg = message || 'Are you sure you want to delete this? This action cannot be undone.';
  if (confirm(msg)) {
    document.getElementById(formId)?.submit();
    return true;
  }
  return false;
}

// ── Exam Timer ────────────────────────────────
let examTimerInterval = null;

function startExamTimer(totalSeconds, onExpire) {
  const timerEl = document.getElementById('examTimer');
  let remaining = totalSeconds;

  function update() {
    if (remaining <= 0) {
      clearInterval(examTimerInterval);
      if (typeof onExpire === 'function') onExpire();
      return;
    }
    const m = Math.floor(remaining / 60).toString().padStart(2, '0');
    const s = (remaining % 60).toString().padStart(2, '0');
    if (timerEl) {
      timerEl.textContent = m + ':' + s;
      if (remaining <= 300) timerEl.classList.add('danger');
    }
    remaining--;
  }

  update();
  examTimerInterval = setInterval(update, 1000);
}

// ── Anti-Cheat System ─────────────────────────
let violations = 0;
const MAX_VIOLATIONS = 3;

function initAntiCheat(autoSubmitFormId) {

  // Tab/window visibility change
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      violations++;
      if (violations >= MAX_VIOLATIONS) {
        showWarningModal(
          'Exam Auto-Submitted',
          'You switched tabs ' + MAX_VIOLATIONS + ' times. Your exam has been submitted automatically.',
          () => autoSubmit(autoSubmitFormId)
        );
      } else {
        showWarningModal(
          'Tab Switch Detected',
          `Warning ${violations} of ${MAX_VIOLATIONS}: Switching tabs is not allowed during the exam. Your exam will be auto-submitted if you do this ${MAX_VIOLATIONS - violations} more time(s).`,
          null
        );
      }
    }
  });

  // Right-click disable
  document.addEventListener('contextmenu', e => {
    e.preventDefault();
    showToast('Right-click is disabled during the exam.', 'error');
  });

  // Copy/Cut disable
  document.addEventListener('copy', e => { e.preventDefault(); showToast('Copying is not allowed.', 'error'); });
  document.addEventListener('cut',  e => { e.preventDefault(); });

  // Keyboard shortcuts
  document.addEventListener('keydown', e => {
    // Block F12, Ctrl+Shift+I/J/U, Ctrl+C, Ctrl+U, PrintScreen
    if (e.key === 'F12' ||
        (e.ctrlKey && e.shiftKey && ['i','I','j','J','c','C'].includes(e.key)) ||
        (e.ctrlKey && ['u','U'].includes(e.key)) ||
        e.key === 'PrintScreen') {
      e.preventDefault();
      showToast('Keyboard shortcuts are disabled during the exam.', 'error');
    }
  });

  // Window blur (switching to another window/app)
  window.addEventListener('blur', () => {
    if (document.visibilityState === 'visible') {
      violations++;
      if (violations >= MAX_VIOLATIONS) {
        autoSubmit(autoSubmitFormId);
      }
    }
  });
}

function showWarningModal(title, message, callback) {
  let modal = document.getElementById('warningModal');
  if (!modal) {
    modal = document.createElement('div');
    modal.id = 'warningModal';
    modal.className = 'modal-overlay';
    modal.innerHTML = `
      <div class="modal-box">
        <div style="margin-bottom:12px" id="modalIcon"><i data-lucide="triangle-alert" style="width:40px;height:40px;color:#f59e0b"></i></div>
        <h2 id="modalTitle"></h2>
        <p id="modalMessage"></p>
        <button class="btn btn-primary btn-lg" id="modalBtn" onclick="closeWarningModal()">OK, I Understand</button>
      </div>
    `;
    document.body.appendChild(modal);
    renderIcons();
  }
  document.getElementById('modalTitle').textContent   = title;
  document.getElementById('modalMessage').textContent = message;
  modal.classList.remove('hidden');

  if (callback) {
    const btn = document.getElementById('modalBtn');
    btn.onclick = () => { closeWarningModal(); callback(); };
  }
}

function closeWarningModal() {
  const modal = document.getElementById('warningModal');
  if (modal) modal.classList.add('hidden');
}

function autoSubmit(formId) {
  clearInterval(examTimerInterval);
  const form = document.getElementById(formId);
  if (form) {
    const inp = form.querySelector('[name="action"]') || document.createElement('input');
    inp.type = 'hidden'; inp.name = 'action'; inp.value = 'autosubmit';
    form.appendChild(inp);
    form.submit();
  }
}

/* =============================================================
   UI ENHANCEMENTS (additive — no existing logic changed)
   - Dark mode toggle (persisted in localStorage)
   - Password visibility toggle on login
   - Marks active nav-link based on current URL
   ============================================================= */
(function () {
  const THEME_KEY = 'adaptexam-theme';

  // Apply stored theme early to avoid FOUC
  try {
    const saved = localStorage.getItem(THEME_KEY);
    if (saved === 'dark') document.documentElement.classList.add('dark');
  } catch (_) {}

  document.addEventListener('DOMContentLoaded', () => {
    /* ── Dark mode toggle inside navbar ── */
    const navUser = document.querySelector('.navbar .navbar-user');
    if (navUser && !document.getElementById('themeToggleBtn')) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.id = 'themeToggleBtn';
      btn.className = 'btn btn-ghost btn-sm';
      btn.setAttribute('aria-label', 'Toggle dark mode');
      btn.style.cssText = 'color:#cbd5e1;border-color:rgba(255,255,255,.12);background:rgba(255,255,255,.04);padding:6px 10px';
      const themeIcon = dark => `<i data-lucide="${dark ? 'sun' : 'moon'}" style="width:16px;height:16px"></i>`;
      btn.innerHTML = themeIcon(document.documentElement.classList.contains('dark'));
      btn.addEventListener('click', () => {
        const nowDark = document.documentElement.classList.toggle('dark');
        try { localStorage.setItem(THEME_KEY, nowDark ? 'dark' : 'light'); } catch(_) {}
        btn.innerHTML = themeIcon(nowDark);
        renderIcons();
      });
      navUser.insertBefore(btn, navUser.firstChild);
      renderIcons();   // must run after insert — createIcons() only scans attached nodes
    }

    /* ── Password visibility toggle ── */
    document.querySelectorAll('input[type="password"]').forEach(input => {
      if (input.dataset.pwEnhanced) return;
      input.dataset.pwEnhanced = '1';
      const wrap = document.createElement('div');
      wrap.style.cssText = 'position:relative';
      input.parentNode.insertBefore(wrap, input);
      wrap.appendChild(input);
      input.style.paddingRight = '42px';
      const eye = document.createElement('button');
      eye.type = 'button';
      eye.setAttribute('aria-label', 'Show password');
      const eyeIcon = shown => `<i data-lucide="${shown ? 'eye-off' : 'eye'}" style="width:16px;height:16px;vertical-align:middle"></i>`;
      eye.innerHTML = eyeIcon(false);
      eye.style.cssText = 'position:absolute;right:8px;top:50%;transform:translateY(-50%);background:transparent;border:none;cursor:pointer;padding:6px 8px;font-size:15px;color:#64748b;border-radius:6px';
      eye.addEventListener('click', () => {
        const showing = input.type === 'text';
        input.type = showing ? 'password' : 'text';
        eye.innerHTML = eyeIcon(!showing);
        renderIcons();
      });
      wrap.appendChild(eye);
      renderIcons();   // must run after append — createIcons() only scans attached nodes
    });

    /* ── Auto-mark active nav-link ── */
    const path = location.pathname.split('/').pop();
    document.querySelectorAll('.navbar .nav-link').forEach(a => {
      const href = a.getAttribute('href') || '';
      if (path && href.endsWith(path)) a.classList.add('active');
    });
  });
})();
