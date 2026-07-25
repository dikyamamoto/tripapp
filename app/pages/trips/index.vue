<template>
  <div class="dashboard-page">
    <header class="navbar">
      <div class="nav-content">
        <NuxtLink to="/trips" class="brand">✈️ TripApp</NuxtLink>
        <NuxtLink to="/profile" class="profile-btn">
          <span class="user-icon">👤</span>
          <span>プロフィール</span>
        </NuxtLink>
      </div>
    </header>

    <main class="container fade-in">
      <div class="page-header">
        <div>
          <h2>マイ旅行一覧</h2>
          <p class="subtitle">計画中の旅行や思い出の記録</p>
        </div>
        <div class="actions">
          <button @click="showCreateModal = true" class="btn btn-primary">＋ 新しい旅行を作成</button>
          <button @click="showJoinModal = true" class="btn btn-secondary">🔑 招待コードで参加</button>
        </div>
      </div>

      <div v-if="tripsError" class="error-banner">⚠️ {{ tripsError }}</div>

      <div v-if="loading" class="loading-card">
        <div class="spinner"></div>
        <p>旅行データを読み込み中...</p>
      </div>

      <div v-else-if="trips.length === 0" class="empty-card">
        <span class="empty-icon">🧳</span>
        <h3>まだ旅行がありません</h3>
        <p>「新しい旅行を作成」または「招待コードで参加」をして、仲間と一緒に計画を始めましょう！</p>
        <button @click="showCreateModal = true" class="btn btn-primary btn-sm">今すぐ旅行を作成</button>
      </div>

      <div v-else class="trip-grid">
        <div v-for="trip in trips" :key="trip.id" class="trip-card" @click="goToTrip(trip.id)">
          <div class="card-header">
            <h3>{{ trip.title }}</h3>
            <span class="badge badge-dates">📅 {{ trip.start_date }} 〜 {{ trip.end_date }}</span>
          </div>
          <div class="card-footer">
            <span class="member-count">👥 メンバー {{ trip.member_count }}人</span>
            <div class="invite-actions">
              <div class="invite-badge" @click.stop="copyCode(trip.invite_code)" title="コードをコピー">
                <span><strong>{{ trip.invite_code }}</strong></span>
                <span class="copy-icon">📋</span>
              </div>
              <button @click.stop="shareToLine(trip.title, trip.invite_code)" class="line-share-btn" title="LINEで共有">
                💬 LINE
              </button>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 旅行作成モーダル -->
    <div v-if="showCreateModal" class="modal-overlay pop-in">
      <div class="modal-card">
        <div class="modal-header">
          <h3>新しい旅行を作成</h3>
          <button @click="closeCreateModal" class="close-btn">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>旅行タイトル</label>
            <input v-model="newTripTitle" type="text" placeholder="例: 夏の北海道旅行" required />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>開始日</label>
              <input v-model="startDate" type="date" required />
            </div>
            <div class="form-group">
              <label>終了日</label>
              <input v-model="endDate" type="date" required />
            </div>
          </div>
          <div v-if="modalError" class="error-msg">⚠️ {{ modalError }}</div>
        </div>
        <div class="modal-footer">
          <button @click="closeCreateModal" class="btn btn-outline">キャンセル</button>
          <button @click="handleCreateTrip" class="btn btn-primary" :disabled="loading">作成する</button>
        </div>
      </div>
    </div>

    <!-- 招待コード参加モーダル -->
    <div v-if="showJoinModal" class="modal-overlay pop-in">
      <div class="modal-card">
        <div class="modal-header">
          <h3>招待コードで旅行に参加</h3>
          <button @click="closeJoinModal" class="close-btn">✕</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>6桁の招待コード</label>
            <input v-model="inviteCode" type="text" placeholder="例: TRIP88" maxlength="6" style="text-transform: uppercase; font-family: monospace; letter-spacing: 2px; font-size: 1.2rem; text-align: center;" required />
          </div>
          <div v-if="modalError" class="error-msg">⚠️ {{ modalError }}</div>
        </div>
        <div class="modal-footer">
          <button @click="closeJoinModal" class="btn btn-outline">キャンセル</button>
          <button @click="handleJoinTrip" class="btn btn-primary" :disabled="loading">参加する</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const { fetchMyTrips, createTrip, joinTripByInviteCode, loading, tripsError } = useTrips()

const trips = ref([])
const showCreateModal = ref(false)
const showJoinModal = ref(false)
const modalError = ref('')

const newTripTitle = ref('')
const startDate = ref(new Date().toISOString().split('T')[0])
const endDate = ref(new Date(Date.now() + 86400000 * 2).toISOString().split('T')[0])
const inviteCode = ref('')

const loadTrips = async () => {
  trips.value = await fetchMyTrips()
}

onMounted(() => {
  loadTrips()
})

const goToTrip = (id) => {
  navigateTo(`/trips/${id}`)
}

const copyCode = (code) => {
  navigator.clipboard.writeText(code)
  alert(`招待コード ${code} をコピーしました！`)
}

const shareToLine = (tripTitle, inviteCode) => {
  const text = `旅行「${tripTitle}」に招待されています！✈️\nTripAppで一緒に旅行計画・割り勘を始めよう！\n\n🔑 招待コード: ${inviteCode}`
  const lineUrl = `https://line.me/R/msg/text/?${encodeURIComponent(text)}`
  window.open(lineUrl, '_blank')
}

const handleCreateTrip = async () => {
  modalError.value = ''
  if (!newTripTitle.value.trim()) {
    modalError.value = '旅行タイトルを入力してください'
    return
  }
  if (!startDate.value || !endDate.value) {
    modalError.value = '日程を選択してください'
    return
  }

  const res = await createTrip({
    title: newTripTitle.value,
    start_date: startDate.value,
    end_date: endDate.value
  })

  if (res.success) {
    closeCreateModal()
    await loadTrips()
  } else {
    modalError.value = res.error || '作成に失敗しました'
  }
}

const handleJoinTrip = async () => {
  modalError.value = ''
  if (!inviteCode.value.trim()) {
    modalError.value = '招待コードを入力してください'
    return
  }

  const res = await joinTripByInviteCode(inviteCode.value)
  if (res.success) {
    closeJoinModal()
    await loadTrips()
    navigateTo(`/trips/${res.tripId}`)
  } else {
    modalError.value = res.error || '参加に失敗しました'
  }
}

const closeCreateModal = () => {
  showCreateModal.value = false
  newTripTitle.value = ''
  modalError.value = ''
}

const closeJoinModal = () => {
  showJoinModal.value = false
  inviteCode.value = ''
  modalError.value = ''
}
</script>

<style scoped>
.dashboard-page {
  min-height: 100vh;
  background-color: #f8fafc;
}

.navbar {
  background: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  position: sticky;
  top: 0;
  z-index: 100;
}

.nav-content {
  max-width: 800px;
  margin: 0 auto;
  padding: 14px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.brand {
  font-size: 1.25rem;
  font-weight: 800;
  color: #2563eb;
  text-decoration: none;
}

.profile-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #f1f5f9;
  border-radius: 20px;
  color: #334155;
  text-decoration: none;
  font-size: 0.85rem;
  font-weight: 600;
  transition: all 0.2s ease;
}

.profile-btn:hover {
  background: #e2e8f0;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 24px 20px 60px 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 16px;
}

.page-header h2 {
  font-size: 1.5rem;
  font-weight: 800;
  color: #0f172a;
}

.subtitle {
  font-size: 0.85rem;
  color: #64748b;
  margin-top: 2px;
}

.actions {
  display: flex;
  gap: 10px;
}

.btn {
  padding: 10px 16px;
  border-radius: 10px;
  font-weight: 700;
  font-size: 0.9rem;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(59, 130, 246, 0.35);
}

.btn-secondary {
  background: #ffffff;
  color: #334155;
  border: 1px solid #cbd5e1;
}

.btn-secondary:hover {
  background: #f8fafc;
}

.trip-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.trip-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 20px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03);
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.trip-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 20px -5px rgba(59, 130, 246, 0.12);
  border-color: #93c5fd;
}

.card-header h3 {
  font-size: 1.15rem;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 8px;
}

.badge-dates {
  display: inline-block;
  font-size: 0.78rem;
  background: #eff6ff;
  color: #2563eb;
  padding: 4px 10px;
  border-radius: 6px;
  font-weight: 600;
}

.card-footer {
  margin-top: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.82rem;
  color: #64748b;
  border-top: 1px solid #f1f5f9;
  padding-top: 12px;
}

.invite-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.invite-badge {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 3px 8px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: background 0.2s ease;
}

.invite-badge:hover {
  background: #e2e8f0;
}

.line-share-btn {
  background: #06C755;
  color: #ffffff;
  border: none;
  padding: 4px 10px;
  border-radius: 6px;
  font-weight: 700;
  font-size: 0.78rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
  transition: all 0.2s ease;
  box-shadow: 0 2px 6px rgba(6, 199, 85, 0.25);
}

.line-share-btn:hover {
  background: #05b34c;
  transform: translateY(-1px);
  box-shadow: 0 4px 10px rgba(6, 199, 85, 0.35);
}

.empty-card, .loading-card {
  text-align: center;
  padding: 60px 20px;
  background: #ffffff;
  border-radius: 20px;
  border: 2px dashed #cbd5e1;
}

.empty-icon {
  font-size: 3rem;
  display: block;
  margin-bottom: 12px;
}

.empty-card h3 {
  font-size: 1.2rem;
  color: #1e293b;
  margin-bottom: 6px;
}

.empty-card p {
  color: #64748b;
  font-size: 0.9rem;
  max-width: 400px;
  margin: 0 auto 20px auto;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(15, 23, 42, 0.5);
  backdrop-filter: blur(8px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  padding: 20px;
}

.modal-card {
  background: #ffffff;
  border-radius: 24px;
  max-width: 440px;
  width: 100%;
  max-height: 85vh;
  overflow-y: auto;
  margin: auto;
  box-shadow: 0 25px 50px -12px rgba(15, 23, 42, 0.35);
}

.modal-header {
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  font-size: 1.15rem;
  font-weight: 700;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  color: #94a3b8;
  cursor: pointer;
}

.modal-body {
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.modal-body label {
  font-size: 0.82rem;
  font-weight: 600;
  color: #334155;
}

.modal-body input {
  padding: 10px 12px;
  border: 1.5px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95rem;
  outline: none;
}

.modal-body input:focus {
  border-color: #3b82f6;
}

.modal-footer {
  padding: 16px 24px;
  background: #f8fafc;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn-outline {
  background: transparent;
  color: #64748b;
}

.error-msg {
  color: #ef4444;
  font-size: 0.85rem;
}
</style>
