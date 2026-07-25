<template>
  <div class="landing-page">
    <div class="bg-decoration">
      <div class="blob blob-1"></div>
      <div class="blob blob-2"></div>
    </div>

    <div class="hero-card fade-in">
      <div class="logo-badge">✈️ TripApp</div>
      <h1 class="title">旅の計画も、割り勘も。<br /><span class="highlight">これひとつで、もっとスマートに。</span></h1>
      <p class="subtitle">
        タイムライン共有・招待コードで簡単参加。<br />
        最適な送金ルートを自動計算し、精算のモヤモヤをゼロにします。
      </p>

      <div class="features-grid">
        <div class="feature-item">
          <span class="icon">📅</span>
          <div>
            <strong>リアルタイム共有</strong>
            <p>みんなでタイムラインを共同編集</p>
          </div>
        </div>
        <div class="feature-item">
          <span class="icon">💰</span>
          <div>
            <strong>送金回数の最小化</strong>
            <p>アルゴリズムで最も賢く精算</p>
          </div>
        </div>
      </div>

      <div class="actions">
        <NuxtLink to="/signup" class="btn btn-primary">
          <span>新しくアカウントを作る</span>
          <span class="arrow">→</span>
        </NuxtLink>
        <NuxtLink to="/signin" class="btn btn-secondary">ログインする</NuxtLink>
      </div>
    </div>
  </div>
</template>

<style scoped>
.landing-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 16px;
  position: relative;
  overflow: hidden;
}

.bg-decoration {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 0;
  pointer-events: none;
}

.blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.5;
}

.blob-1 {
  width: 350px;
  height: 350px;
  background: #60a5fa;
  top: -100px;
  right: -50px;
}

.blob-2 {
  width: 300px;
  height: 300px;
  background: #a78bfa;
  bottom: -50px;
  left: -50px;
}

.hero-card {
  position: relative;
  z-index: 1;
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.6);
  border-radius: 24px;
  padding: 40px 28px;
  max-width: 460px;
  width: 100%;
  box-shadow: 0 20px 40px -15px rgba(15, 23, 42, 0.08);
  text-align: center;
}

.logo-badge {
  display: inline-flex;
  align-items: center;
  padding: 6px 14px;
  background: #eff6ff;
  color: #2563eb;
  border-radius: 20px;
  font-weight: 700;
  font-size: 0.9rem;
  margin-bottom: 20px;
}

.title {
  font-size: 1.75rem;
  font-weight: 800;
  line-height: 1.35;
  color: #0f172a;
  margin-bottom: 16px;
  letter-spacing: -0.02em;
}

.highlight {
  background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.subtitle {
  color: #64748b;
  font-size: 0.95rem;
  line-height: 1.6;
  margin-bottom: 28px;
}

.features-grid {
  display: flex;
  flex-direction: column;
  gap: 12px;
  text-align: left;
  margin-bottom: 32px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  background: #ffffff;
  padding: 12px 16px;
  border-radius: 14px;
  border: 1px solid #f1f5f9;
  box-shadow: 0 2px 4px rgba(0,0,0,0.02);
}

.feature-item .icon {
  font-size: 1.4rem;
}

.feature-item strong {
  display: block;
  font-size: 0.9rem;
  color: #1e293b;
}

.feature-item p {
  font-size: 0.78rem;
  color: #64748b;
  margin: 0;
}

.actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.btn {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 14px 20px;
  border-radius: 14px;
  font-weight: 700;
  font-size: 1rem;
  text-decoration: none;
  transition: all 0.2s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
  box-shadow: 0 4px 14px rgba(59, 130, 246, 0.35);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(59, 130, 246, 0.45);
}

.btn-primary .arrow {
  margin-left: 8px;
  transition: transform 0.2s ease;
}

.btn-primary:hover .arrow {
  transform: translateX(4px);
}

.btn-secondary {
  background: #f1f5f9;
  color: #334155;
}

.btn-secondary:hover {
  background: #e2e8f0;
}
</style>
