// ── Navbar scroll effect ──────────────────────────────────────────────────
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 20);
});

// ── Hamburger menu ────────────────────────────────────────────────────────
const hamburger = document.getElementById('hamburger');
const mobileMenu = document.getElementById('mobileMenu');
hamburger.addEventListener('click', () => {
  mobileMenu.classList.toggle('open');
});
mobileMenu.querySelectorAll('a').forEach(a => {
  a.addEventListener('click', () => mobileMenu.classList.remove('open'));
});

// ── Scroll reveal ─────────────────────────────────────────────────────────
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
    }
  });
}, { threshold: 0.1, rootMargin: '0px 0px -60px 0px' });

document.querySelectorAll('.feature-card, .step, .price-card, .section-header, .business-content, .business-visual, .trusted-logos, .hero-stats').forEach(el => {
  el.classList.add('reveal');
  revealObserver.observe(el);
});

// ── Queue bar animation ───────────────────────────────────────────────────
const queueBar = document.querySelector('.queue-bar');
if (queueBar) {
  setTimeout(() => {
    queueBar.style.width = '65%';
  }, 1000);
}

// ── Animated counter for stats ────────────────────────────────────────────
function animateCounter(el, target, suffix = '') {
  const num = parseFloat(target.replace(/[^0-9.]/g, ''));
  const prefix = target.replace(/[0-9.,+★]/g, '').trim();
  const duration = 1800;
  const start = performance.now();
  const isDecimal = target.includes('.');

  const step = (now) => {
    const progress = Math.min((now - start) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3); // ease-out-cubic
    const current = eased * num;
    el.textContent = isDecimal
      ? current.toFixed(1) + suffix
      : Math.floor(current).toLocaleString('en-IN') + suffix;
    if (progress < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

const statsObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.querySelectorAll('.stat-num').forEach(el => {
        const raw = el.textContent;
        if (raw.includes('M')) animateCounter(el, raw.replace('M+',''), 'M+');
        else if (raw.includes('K')) animateCounter(el, raw.replace('K+',''), 'K+');
        else if (raw.includes('★')) animateCounter(el, raw, '★');
      });
      statsObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.5 });

const heroStats = document.querySelector('.hero-stats');
if (heroStats) statsObserver.observe(heroStats);

// ── Smooth active nav link highlight ─────────────────────────────────────
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-links a');
const sectionObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      navLinks.forEach(a => a.classList.remove('active'));
      const activeLink = document.querySelector(`.nav-links a[href="#${entry.target.id}"]`);
      if (activeLink) activeLink.classList.add('active');
    }
  });
}, { threshold: 0.4 });
sections.forEach(s => sectionObserver.observe(s));

// add active style
const styleEl = document.createElement('style');
styleEl.textContent = `.nav-links a.active { color: var(--text); background: var(--surface2); }`;
document.head.appendChild(styleEl);

console.log('🎉 QueueLess web app loaded!');
