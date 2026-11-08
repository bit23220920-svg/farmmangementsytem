/* ==========================================================================
   Password field with a show/hide eye toggle and an optional live
   strength meter. Same rule set the backend enforces (Auth::passwordMeetsPolicy):
   at least 8 characters, one lowercase, one uppercase, one number, one symbol.
   ========================================================================== */

const EYE_OPEN = '<path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/>';
const EYE_OFF = '<path d="M3 3l18 18M10.6 10.6a3 3 0 0 0 4.24 4.24M9.9 4.24A11 11 0 0 1 12 4c7 0 11 8 11 8a17.7 17.7 0 0 1-3.16 4.2M6.3 6.3A17.5 17.5 0 0 0 1 12s4 8 11 8a10.6 10.6 0 0 0 4.7-1.06"/>';

export function passwordChecks(pw){
  return {
    length: pw.length >= 8,
    lower: /[a-z]/.test(pw),
    upper: /[A-Z]/.test(pw),
    number: /[0-9]/.test(pw),
    symbol: /[^a-zA-Z0-9]/.test(pw),
  };
}

export function passwordScore(pw){
  const c = passwordChecks(pw);
  const passed = Object.values(c).filter(Boolean).length;
  let label, color;
  if (!pw){ label = ''; color = 'transparent'; }
  else if (passed <= 2){ label = 'Weak'; color = 'var(--rust)'; }
  else if (passed <= 4){ label = 'Okay'; color = 'var(--ochre)'; }
  else { label = 'Strong'; color = 'var(--olive)'; }
  return { checks: c, passed, total: 5, label, color, valid: passed === 5 };
}

/** Returns the HTML string for a password field. Call wirePasswordField() after inserting it. */
export function passwordFieldHtml({ id, label, placeholder = '', withStrength = false, autocomplete = 'new-password' }){
  return `
    <div class="field">
      <label for="${id}">${label}</label>
      <div class="password-input-wrap">
        <input type="password" id="${id}" autocomplete="${autocomplete}" placeholder="${placeholder}">
        <button type="button" class="pw-toggle" data-target="${id}" aria-label="Show password">
          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${EYE_OPEN}</svg>
        </button>
      </div>
      ${withStrength ? `
        <div class="pw-strength" aria-hidden="true">
          <div class="pw-strength-bar" id="${id}_bar"></div>
        </div>
        <p class="pw-strength-label" id="${id}_label">&nbsp;</p>
        <ul class="pw-rules" id="${id}_rules">
          <li data-rule="length">At least 8 characters</li>
          <li data-rule="upper">One uppercase letter</li>
          <li data-rule="lower">One lowercase letter</li>
          <li data-rule="number">One number</li>
          <li data-rule="symbol">One symbol</li>
        </ul>
      ` : ''}
    </div>`;
}

/** Wires up the eye toggle (and strength meter, if present) for a field inserted via passwordFieldHtml(). */
export function wirePasswordField(id, { withStrength = false } = {}){
  const input = document.getElementById(id);
  const toggle = input.parentElement.querySelector('.pw-toggle');

  toggle.addEventListener('click', () => {
    const showing = input.type === 'text';
    input.type = showing ? 'password' : 'text';
    toggle.querySelector('svg').innerHTML = showing ? EYE_OPEN : EYE_OFF;
    toggle.setAttribute('aria-label', showing ? 'Show password' : 'Hide password');
  });

  if (withStrength){
    const bar = document.getElementById(`${id}_bar`);
    const label = document.getElementById(`${id}_label`);
    const rulesList = document.getElementById(`${id}_rules`);

    const update = () => {
      const { checks, passed, label: text, color } = passwordScore(input.value);
      bar.style.width = `${(passed / 5) * 100}%`;
      bar.style.background = color;
      label.textContent = input.value ? text : '\u00A0';
      label.style.color = color;
      rulesList.querySelectorAll('li').forEach(li => {
        const rule = li.dataset.rule;
        li.classList.toggle('met', !!checks[rule]);
      });
    };
    input.addEventListener('input', update);
    update();
  }

  return input;
}
