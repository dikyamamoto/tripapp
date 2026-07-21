<template>
  <div class="trip-detail">
    <header class="header">
      <button @click="goBack" class="back-btn">← 戻る</button>
      <div class="trip-title-area">
        <h2>{{ tripTitle }}</h2>
        <span class="trip-dates">2026/08/10 〜 2026/08/12</span>
      </div>
    </header>

    <!-- タブメニュー -->
    <nav class="tabs">
      <button :class="{ active: activeTab === 'schedule' }" @click="activeTab = 'schedule'">スケジュール</button>
      <button :class="{ active: activeTab === 'expense' }" @click="activeTab = 'expense'">割り勘・精算</button>
      <button :class="{ active: activeTab === 'members' }" @click="activeTab = 'members'">メンバー</button>
    </nav>

    <!-- コンテンツ表示エリア -->
    <main class="tab-content">
      <!-- 1. スケジュールタブ -->
      <section v-if="activeTab === 'schedule'">
        <div class="day-selector">
          <button v-for="d in days" :key="d" :class="{ active: selectedDay === d }" @click="selectedDay = d">
            {{ d }}日目
          </button>
        </div>

        <div class="timeline">
          <div v-for="event in filteredEvents" :key="event.id" class="event-card">
            <span class="event-time">{{ event.time }}</span>
            <div class="event-info">
              <h4>{{ event.title }}</h4>
              <p v-if="event.location" class="location">📍 {{ event.location }}</p>
              <p v-if="event.memo" class="memo">{{ event.memo }}</p>
            </div>
          </div>
        </div>

        <button @click="showAddEvent = true" class="fab">＋ 予定を追加</button>
      </section>

      <!-- 2. 割り勘・精算タブ -->
      <section v-if="activeTab === 'expense'">
        <!-- 精算のサマリー -->
        <div class="expense-summary">
          <div>
            <p class="summary-label">旅行の総出費</p>
            <p class="summary-val">{{ totalExpense }} 円</p>
          </div>
          <div>
            <p class="summary-label">あなたの収支</p>
            <p :class="['summary-val', myBalance >= 0 ? 'plus' : 'minus']">
              {{ myBalance >= 0 ? '+' : '' }}{{ myBalance }} 円
            </p>
          </div>
        </div>

        <div class="expense-actions">
          <button @click="showAddExpense = true" class="btn btn-primary">＋ 出費を記録する</button>
          <button @click="toggleSettlement" class="btn btn-secondary">
            {{ showSettlement ? '履歴一覧を見る' : '清算結果を見る' }}
          </button>
        </div>

        <!-- 清算結果 (送金ルート) 表示 -->
        <div v-if="showSettlement" class="settlement-area">
          <h3>💸 清算ルート (自動計算)</h3>
          <div v-if="settlementRoutes.length === 0" class="no-data">貸し借りは発生していません。</div>
          <div v-else class="routes-list">
            <div v-for="(route, i) in settlementRoutes" :key="i" class="route-card">
              <span class="debtor">{{ route.from }}</span> から 
              <span class="creditor">{{ route.to }}</span> へ 
              <span class="amount">{{ route.amount }} 円</span> 送金
            </div>
          </div>
        </div>

        <!-- 支払履歴リスト -->
        <div v-else class="expense-history">
          <h3>💰 支払履歴</h3>
          <div v-if="expenses.length === 0" class="no-data">まだ支払履歴はありません。</div>
          <div v-else class="expense-list">
            <div v-for="exp in expenses" :key="exp.id" class="expense-card">
              <div class="exp-header">
                <span class="exp-title">{{ exp.description }}</span>
                <span class="exp-amount">{{ exp.amount }} 円</span>
              </div>
              <div class="exp-footer">
                <span>支払者: {{ exp.payer }}</span>
                <span>対象: {{ exp.targets.join(', ') }}</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 3. メンバータブ -->
      <section v-if="activeTab === 'members'" class="members-tab">
        <div class="invite-card">
          <h4>メンバーを招待</h4>
          <p class="invite-code">招待コード: <code>TRIP88</code></p>
          <button @click="copyInviteCode" class="btn btn-secondary btn-sm">招待コードをコピー</button>
        </div>

        <h3>👥 参加メンバー ({{ members.length }}人)</h3>
        <div class="members-list">
          <div v-for="member in members" :key="member.id" class="member-item">
            <span class="member-name">{{ member.name }}</span>
            <span v-if="member.isHost" class="host-badge">ホスト</span>
          </div>
        </div>

        <button @click="leaveGroup" class="btn btn-danger leave-btn">グループから抜ける</button>
      </section>
    </main>

    <!-- 予定追加モーダル -->
    <div v-if="showAddEvent" class="modal-overlay">
      <div class="modal">
        <h3>新しい予定を追加</h3>
        <input v-model="newEventTitle" type="text" placeholder="予定名 (例: 〇〇で昼食)" required />
        <input v-model="newEventTime" type="time" required />
        <input v-model="newEventLocation" type="text" placeholder="場所 (任意)" />
        <textarea v-model="newEventMemo" placeholder="メモ・持ち物 (任意)"></textarea>
        <div class="modal-actions">
          <button @click="addEvent" class="btn btn-primary">追加する</button>
          <button @click="showAddEvent = false" class="btn btn-secondary">キャンセル</button>
        </div>
      </div>
    </div>

    <!-- 出費登録モーダル -->
    <div v-if="showAddExpense" class="modal-overlay">
      <div class="modal">
        <h3>出費を記録する</h3>
        <input v-model="newExpDescription" type="text" placeholder="内容 (例: レンタカー代)" required />
        <input v-model.number="newExpAmount" type="number" placeholder="金額 (円)" required />
        <div class="form-group">
          <label>支払った人</label>
          <select v-model="newExpPayer">
            <option v-for="m in members" :key="m.id" :value="m.name">{{ m.name }}</option>
          </select>
        </div>
        <div class="form-group">
          <label>対象メンバー (複数選択)</label>
          <div class="checkboxes">
            <label v-for="m in members" :key="m.id">
              <input type="checkbox" :value="m.name" v-model="newExpTargets" />
              {{ m.name }}
            </label>
          </div>
        </div>
        <div class="modal-actions">
          <button @click="addExpense" class="btn btn-primary">登録する</button>
          <button @click="showAddExpense = false" class="btn btn-secondary">キャンセル</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const activeTab = ref('schedule')
const selectedDay = ref(1)
const showAddEvent = ref(false)
const showAddExpense = ref(false)
const showSettlement = ref(false)

const tripTitle = ref('夏の北海道旅行')
const days = [1, 2, 3]

// メンバーデータ (ダミー)
const members = ref([
  { id: 'u1', name: 'あなた (自分)', isHost: true },
  { id: 'u2', name: 'たろう', isHost: false },
  { id: 'u3', name: 'はなこ', isHost: false },
])

// 予定データ (ダミー)
const events = ref([
  { id: 'e1', day: 1, time: '10:00', title: '羽田空港 集合', location: '第1ターミナル', memo: '遅刻厳禁' },
  { id: 'e2', day: 1, time: '13:00', title: '新千歳空港 到着', location: '新千歳空港', memo: 'レンタカー受け取りへ' },
  { id: 'e3', day: 2, time: '12:00', title: '札幌ラーメンランチ', location: '麺処〇〇', memo: '味噌ラーメンが有名' },
])

// 出費データ (ダミー)
const expenses = ref([
  { id: 'x1', description: 'レンタカー代', amount: 9000, payer: 'あなた (自分)', targets: ['あなた (自分)', 'たろう', 'はなこ'] },
  { id: 'x2', description: '居酒屋夕食', amount: 6000, payer: 'たろう', targets: ['たろう', 'はなこ'] },
])

// スケジュールのフィルタリング
const filteredEvents = computed(() => {
  return events.value
    .filter(e => e.day === selectedDay.value)
    .sort((a, b) => a.time.localeCompare(b.time))
})

// 予定の追加
const newEventTitle = ref('')
const newEventTime = ref('12:00')
const newEventLocation = ref('')
const newEventMemo = ref('')

const addEvent = () => {
  if (newEventTitle.value) {
    events.value.push({
      id: String(Date.now()),
      day: selectedDay.value,
      time: newEventTime.value,
      title: newEventTitle.value,
      location: newEventLocation.value,
      memo: newEventMemo.value
    })
    showAddEvent.value = false
    newEventTitle.value = ''
    newEventLocation.value = ''
    newEventMemo.value = ''
  }
}

// 出費の追加
const newExpDescription = ref('')
const newExpAmount = ref(null)
const newExpPayer = ref('あなた (自分)')
const newExpTargets = ref(['あなた (自分)', 'たろう', 'はなこ'])

const addExpense = () => {
  if (newExpDescription.value && newExpAmount.value && newExpTargets.value.length > 0) {
    expenses.value.push({
      id: String(Date.now()),
      description: newExpDescription.value,
      amount: newExpAmount.value,
      payer: newExpPayer.value,
      targets: [...newExpTargets.value]
    })
    showAddExpense.value = false
    newExpDescription.value = ''
    newExpAmount.value = null
  }
}

// 割り勘計算ロジック
const totalExpense = computed(() => {
  return expenses.value.reduce((sum, exp) => sum + exp.amount, 0)
})

// 各メンバーの純貸借 (Net Balance)
const netBalances = computed(() => {
  const balances = {}
  members.value.forEach(m => {
    balances[m.name] = 0
  })

  expenses.value.forEach(exp => {
    // 支払った人はプラス
    balances[exp.payer] += exp.amount
    // 対象者は均等負担 (マイナス)
    const share = exp.amount / exp.targets.length
    exp.targets.forEach(t => {
      balances[t] -= share
    })
  })
  return balances
})

// 自分の現在のバランス
const myBalance = computed(() => {
  return Math.round(netBalances.value['あなた (自分)'] || 0)
})

// 清算ルート算出
const settlementRoutes = computed(() => {
  const balances = { ...netBalances.value }
  const debtors = []
  const creditors = []

  Object.keys(balances).forEach(name => {
    const val = balances[name]
    if (val < -0.1) {
      debtors.push({ name, amount: val })
    } else if (val > 0.1) {
      creditors.push({ name, amount: val })
    }
  })

  // 絶対値の降順ソート
  debtors.sort((a, b) => a.amount - b.amount) // 一番マイナスが大きい順
  creditors.sort((a, b) => b.amount - a.amount) // 一番プラスが大きい順

  const routes = []
  let dIdx = 0
  let cIdx = 0

  while (dIdx < debtors.length && cIdx < creditors.length) {
    const d = debtors[dIdx]
    const c = creditors[cIdx]

    const dAbs = Math.abs(d.amount)
    const sendAmount = Math.round(Math.min(dAbs, c.amount))

    if (sendAmount > 0) {
      routes.push({
        from: d.name,
        to: c.name,
        amount: sendAmount
      })
    }

    d.amount += sendAmount
    c.amount -= sendAmount

    if (Math.abs(d.amount) < 0.1) dIdx++
    if (c.amount < 0.1) cIdx++
  }

  return routes
})

const toggleSettlement = () => {
  showSettlement.value = !showSettlement.value
}

const copyInviteCode = () => {
  navigator.clipboard.writeText('TRIP88')
  alert('招待コード TRIP88 をコピーしました！')
}

const leaveGroup = () => {
  if (confirm('本当にこの旅行グループから抜けますか？')) {
    navigateTo('/trips')
  }
}

const goBack = () => {
  navigateTo('/trips')
}
</script>

<style scoped>
.trip-detail {
  font-family: sans-serif;
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
  background-color: #f9f9f9;
  min-height: 100vh;
  position: relative;
}
.header {
  display: flex;
  align-items: center;
  gap: 15px;
  border-bottom: 1px solid #ddd;
  padding-bottom: 10px;
  margin-bottom: 15px;
}
.back-btn {
  background: none;
  border: none;
  color: #007bff;
  cursor: pointer;
  font-size: 1rem;
}
.trip-title-area h2 {
  margin: 0;
}
.trip-dates {
  font-size: 0.85rem;
  color: #666;
}
.tabs {
  display: flex;
  border-bottom: 2px solid #eee;
  margin-bottom: 15px;
}
.tabs button {
  flex: 1;
  padding: 10px;
  background: none;
  border: none;
  font-weight: bold;
  cursor: pointer;
  color: #666;
}
.tabs button.active {
  color: #007bff;
  border-bottom: 2px solid #007bff;
}
.day-selector {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
}
.day-selector button {
  padding: 8px 15px;
  border-radius: 20px;
  border: 1px solid #ddd;
  background: white;
  cursor: pointer;
}
.day-selector button.active {
  background: #007bff;
  color: white;
  border-color: #007bff;
}
.timeline {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.event-card {
  display: flex;
  gap: 15px;
  background: white;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #eee;
}
.event-time {
  font-weight: bold;
  color: #333;
  min-width: 45px;
}
.event-info h4 {
  margin: 0 0 5px 0;
}
.location {
  font-size: 0.85rem;
  color: #666;
  margin: 0 0 5px 0;
}
.memo {
  font-size: 0.85rem;
  color: #888;
  margin: 0;
}
.fab {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 50px;
  padding: 15px 25px;
  font-weight: bold;
  box-shadow: 0 4px 10px rgba(0,0,0,0.2);
  cursor: pointer;
}
.expense-summary {
  display: flex;
  justify-content: space-around;
  background: white;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #eee;
  margin-bottom: 15px;
  text-align: center;
}
.summary-label {
  font-size: 0.85rem;
  color: #666;
  margin: 0;
}
.summary-val {
  font-size: 1.2rem;
  font-weight: bold;
  margin: 5px 0 0 0;
}
.summary-val.plus {
  color: #28a745;
}
.summary-val.minus {
  color: #dc3545;
}
.expense-actions {
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
.btn-danger {
  background-color: #dc3545;
  color: white;
}
.expense-list, .routes-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.expense-card, .route-card {
  background: white;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #eee;
}
.exp-header {
  display: flex;
  justify-content: space-between;
  font-weight: bold;
  margin-bottom: 8px;
}
.exp-footer {
  display: flex;
  justify-content: space-between;
  font-size: 0.85rem;
  color: #666;
}
.route-card {
  font-size: 1rem;
}
.route-card .debtor, .route-card .creditor {
  font-weight: bold;
}
.route-card .amount {
  color: #dc3545;
  font-weight: bold;
}
.invite-card {
  background: white;
  padding: 15px;
  border-radius: 8px;
  border: 1px solid #eee;
  margin-bottom: 20px;
}
.invite-code {
  font-size: 1.1rem;
  margin: 10px 0;
}
.members-list {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 8px;
  border: 1px solid #eee;
  margin-bottom: 20px;
}
.member-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 15px;
  border-bottom: 1px solid #eee;
}
.member-item:last-child {
  border-bottom: none;
}
.host-badge {
  font-size: 0.75rem;
  background: #ffc107;
  padding: 2px 6px;
  border-radius: 10px;
}
.leave-btn {
  width: 100%;
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
  z-index: 1000;
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
.modal input, .modal select, .modal textarea {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.checkboxes {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
.no-data {
  text-align: center;
  padding: 20px;
  color: #888;
}
</style>
