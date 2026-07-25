<template>
  <div class="profile-page">
    <div class="profile-card fade-in">
      <div class="header">
        <div class="avatar-circle">
          {{ displayName.slice(0, 1) || '👤' }}
        </div>
        <h2>プロフィール設定</h2>
        <p class="subtitle">表示名やアカウント情報の確認</p>
      </div>

      <form @submit.prevent="saveProfile" class="form">
        <div class="form-group">
          <label>メールアドレス</label>
          <input :value="user?.email" type="email" disabled class="disabled-input" />
        </div>
        <div class="form-group">
          <label for="displayName">表示名 (ニックネーム)</label>
          <input v-model="displayName" type="text" id="displayName" placeholder="例: たろう" required />
        </div>

        <div v-if="msg" class="success-banner">
          ✅ {{ msg }}
        </div>

        <button type="submit" class="btn btn-primary" :disabled="loading">
          {{ loading ? '保存中...' : '変更を保存する' }}
        </button>
      </form>

      <div class="action-buttons">
        <button @click="logout" class="btn btn-secondary">ログアウト</button>
        <button @click="goBack" class="btn btn-outline">← マイ旅行一覧に戻る</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const { user, fetchProfile, updateProfile, signOut, loading } = useTripAuth()

const displayName = ref('')
const msg = ref('')

onMounted(async () => {
  const profile = await fetchProfile()
  if (profile) {
    displayName.value = profile.display_name
  }
})

const saveProfile = async () => {
  if (!displayName.value.trim()) return
  const res = await updateProfile(displayName.value)
  if (res.success) {
    msg.value = 'プロフィールを保存しました！'
    setTimeout(() => {
      msg.value = ''
      navigateTo('/trips')
    }, 1000)
  } else {
    alert(res.error || '保存に失敗しました')
  }
}

const logout = async () => {
  if (confirm('ログアウトしますか？')) {
    const res = await signOut()
    if (res.success) {
      navigateTo('/')
    }
  }
}

const goBack = () => {
  navigateTo('/trips')
}
</script>

<style scoped>
.profile-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px 16px;
  background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
}

.profile-card {
  background: #ffffff;
  border-radius: 20px;
  padding: 36px 28px;
  max-width: 420px;
  width: 100%;
  box-shadow: 0 20px 30px -10px rgba(15, 23, 42, 0.08);
  border: 1px solid #f1f5f9;
}

.header {
  text-align: center;
  margin-bottom: 24px;
}

.avatar-circle {
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.6rem;
  font-weight: 800;
  margin: 0 auto 16px auto;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.header h2 {
  font-size: 1.4rem;
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
  gap: 16px;
  margin-bottom: 24px;
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
  outline: none;
  transition: all 0.2s ease;
}

input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}

.disabled-input {
  background-color: #f1f5f9;
  color: #64748b;
  cursor: not-allowed;
}

.btn {
  padding: 12px;
  border-radius: 10px;
  font-weight: 700;
  font-size: 0.95rem;
  cursor: pointer;
  border: none;
  transition: all 0.2s ease;
  width: 100%;
}

.btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
}

.btn-secondary {
  background: #fef2f2;
  color: #ef4444;
  border: 1px solid #fecaca;
}

.btn-secondary:hover {
  background: #fee2e2;
}

.btn-outline {
  background: transparent;
  color: #64748b;
  font-weight: 600;
}

.btn-outline:hover {
  color: #0f172a;
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.success-banner {
  background: #ecfdf5;
  color: #059669;
  border: 1px solid #a7f3d0;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 0.85rem;
}
</style>
