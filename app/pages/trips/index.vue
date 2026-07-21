<template>
  <div class="dashboard">
    <header class="header">
      <h2>マイ旅行一覧</h2>
      <div class="user-actions">
        <NuxtLink to="/profile" class="profile-link">プロフィール設定</NuxtLink>
      </div>
    </header>

    <div class="content">
      <div class="actions">
        <button @click="showCreateModal = true" class="btn btn-primary">＋ 新しい旅行を作成</button>
        <button @click="showJoinModal = true" class="btn btn-secondary">招待コードで参加</button>
      </div>

      <div class="trip-list">
        <div v-for="trip in trips" :key="trip.id" class="trip-card" @click="goToTrip(trip.id)">
          <div class="trip-info">
            <h3>{{ trip.title }}</h3>
            <p class="dates">{{ trip.start_date }} 〜 {{ trip.end_date }}</p>
            <p class="members">メンバー数: {{ trip.member_count }}人</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 旅行作成モーダル (ダミー) -->
    <div v-if="showCreateModal" class="modal-overlay">
      <div class="modal">
        <h3>新しい旅行を作成</h3>
        <input v-model="newTripTitle" type="text" placeholder="旅行タイトル (例: 北海道旅行)" />
        <div class="modal-actions">
          <button @click="createTrip" class="btn btn-primary">作成する</button>
          <button @click="showCreateModal = false" class="btn btn-secondary">キャンセル</button>
        </div>
      </div>
    </div>

    <!-- 招待コード参加モーダル (ダミー) -->
    <div v-if="showJoinModal" class="modal-overlay">
      <div class="modal">
        <h3>招待コードで旅行に参加</h3>
        <input v-model="inviteCode" type="text" placeholder="招待コードを入力" />
        <div class="modal-actions">
          <button @click="joinTrip" class="btn btn-primary">参加する</button>
          <button @click="showJoinModal = false" class="btn btn-secondary">キャンセル</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const showCreateModal = ref(false)
const showJoinModal = ref(false)
const newTripTitle = ref('')
const inviteCode = ref('')

// ダミーデータ
const trips = ref([
  { id: '1', title: '夏の北海道旅行', start_date: '2026-08-10', end_date: '2026-08-12', member_count: 3 },
  { id: '2', title: '京都弾丸ツアー', start_date: '2026-09-05', end_date: '2026-09-06', member_count: 2 },
])

const goToTrip = (id) => {
  navigateTo(`/trips/${id}`)
}

const createTrip = () => {
  if (newTripTitle.value) {
    trips.value.push({
      id: String(trips.value.length + 1),
      title: newTripTitle.value,
      start_date: '2026-10-01',
      end_date: '2026-10-03',
      member_count: 1
    })
    showCreateModal.value = false
    newTripTitle.value = ''
  }
}

const joinTrip = () => {
  if (inviteCode.value) {
    alert(`招待コード ${inviteCode.value} で旅行に参加しました！`)
    showJoinModal.value = false
    inviteCode.value = ''
  }
}
</script>

<style scoped>
.dashboard {
  font-family: sans-serif;
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
  background-color: #f9f9f9;
  min-height: 100vh;
}
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #ddd;
  padding-bottom: 10px;
}
.profile-link {
  text-decoration: none;
  color: #007bff;
}
.content {
  margin-top: 20px;
}
.actions {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}
.btn {
  padding: 10px 15px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}
.btn-primary {
  background-color: #007bff;
  color: white;
}
.btn-secondary {
  background-color: #6c757d;
  color: white;
}
.trip-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}
.trip-card {
  background-color: white;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #eee;
  cursor: pointer;
  transition: transform 0.2s;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}
.trip-card:hover {
  transform: translateY(-2px);
}
.dates {
  color: #666;
  font-size: 0.9rem;
}
.members {
  font-size: 0.9rem;
  color: #888;
}
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
}
.modal {
  background: white;
  padding: 20px;
  border-radius: 8px;
  width: 90%;
  max-width: 350px;
  display: flex;
  flex-direction: column;
  gap: 15px;
}
.modal input {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
