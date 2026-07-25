<template>
  <div class="auth-page">
    <div class="auth-card fade-in">
      <div class="header">
        <NuxtLink to="/" class="brand">✈️ TripApp</NuxtLink>
        <h2>ログイン</h2>
        <p class="subtitle">おかえりなさい！旅の続きをチェックしましょう</p>
      </div>

      <form @submit.prevent="handleLogin" class="form">
        <div class="form-group">
          <label for="email">メールアドレス</label>
          <input v-model="email" type="email" id="email" placeholder="example@email.com" required />
        </div>
        <div class="form-group">
          <label for="password">パスワード</label>
          <input v-model="password" type="password" id="password" required />
        </div>

        <div v-if="authError" class="error-banner">
          ⚠️ {{ authError }}
        </div>

        <button type="submit" class="btn btn-primary" :disabled="loading">
          <span v-if="loading" class="spinner"></span>
          <span>{{ loading ? 'ログイン中...' : 'ログイン' }}</span>
        </button>
      </form>

      <div class="footer-links">
        <span>アカウントをお持ちでないですか？</span>
        <NuxtLink to="/signup" class="link">新規登録</NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const { signIn, loading, authError } = useTripAuth()

const email = ref('')
const password = ref('')

const handleLogin = async () => {
  const res = await signIn(email.value, password.value)
  if (res.success) {
    navigateTo('/trips')
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px 16px;
  background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
}

.auth-card {
  background: #ffffff;
  border-radius: 20px;
  padding: 36px 28px;
  max-width: 400px;
  width: 100%;
  box-shadow: 0 20px 30px -10px rgba(15, 23, 42, 0.08);
  border: 1px solid #f1f5f9;
}

.header {
  text-align: center;
  margin-bottom: 28px;
}

.brand {
  font-weight: 800;
  color: #2563eb;
  text-decoration: none;
  font-size: 1.1rem;
  display: inline-block;
  margin-bottom: 8px;
}

.header h2 {
  font-size: 1.5rem;
  font-weight: 800;
  color: #0f172a;
}

.subtitle {
  color: #64748b;
  font-size: 0.85rem;
  margin-top: 4px;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  font-size: 0.85rem;
  font-weight: 600;
  color: #334155;
}

input {
  padding: 12px 14px;
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  font-size: 0.95rem;
  font-family: inherit;
  transition: all 0.2s ease;
  outline: none;
}

input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}

.btn-primary {
  padding: 14px;
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: 700;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s ease;
  margin-top: 6px;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
}

.btn-primary:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.error-banner {
  background: #fef2f2;
  color: #ef4444;
  border: 1px solid #fecaca;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 0.85rem;
}

.footer-links {
  margin-top: 24px;
  text-align: center;
  font-size: 0.85rem;
  color: #64748b;
}

.link {
  color: #2563eb;
  font-weight: 700;
  text-decoration: none;
  margin-left: 6px;
}

.link:hover {
  text-decoration: underline;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
