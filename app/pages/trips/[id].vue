<template>
  <div class="trip-detail-page">
    <!-- ローディング/エラー表示 -->
    <div v-if="loading && !trip" class="loading-state">
      <div class="spinner"></div>
      <p>旅行データを取得中...</p>
    </div>

    <div v-else-if="error" class="error-state">
      <p>⚠️ {{ error }}</p>
      <button @click="goBack" class="btn btn-secondary">一覧に戻る</button>
    </div>

    <div v-else-if="trip" class="fade-in">
      <!-- ヘッダー -->
      <header class="app-header">
        <div class="header-content">
          <button @click="goBack" class="back-btn">← 戻る</button>
          <div class="trip-meta">
            <h2>{{ trip.title }}</h2>
            <span class="dates-pill">📅 {{ trip.start_date }} 〜 {{ trip.end_date }}</span>
          </div>
        </div>
      </header>

      <main class="main-container">
        <!-- ピルスタイル・タブ切り替え -->
        <nav class="tab-nav">
          <button :class="{ active: activeTab === 'schedule' }" @click="activeTab = 'schedule'">
            <span>📅 スケジュール</span>
          </button>
          <button :class="{ active: activeTab === 'expense' }" @click="activeTab = 'expense'">
            <span>💰 割り勘・精算</span>
          </button>
          <button :class="{ active: activeTab === 'members' }" @click="activeTab = 'members'">
            <span>👥 メンバー</span>
          </button>
        </nav>

        <!-- 1. スケジュールタブ -->
        <section v-if="activeTab === 'schedule'" class="tab-pane">
          <!-- 日付選択ピル -->
          <div class="day-pills">
            <button
              v-for="d in tripDays"
              :key="d.dayNum"
              :class="{ active: selectedDay === d.dayNum }"
              @click="selectedDay = d.dayNum"
            >
              <strong>{{ d.dayNum }}日目</strong>
              <small>{{ d.dateStr.slice(5) }}</small>
            </button>
          </div>

          <!-- タイムライン表示 -->
          <div class="timeline-container">
            <div v-if="filteredEvents.length === 0" class="empty-timeline">
              <span class="icon">📍</span>
              <p>この日の予定はまだ登録されていません</p>
            </div>

            <div v-else class="timeline-list">
              <div v-for="event in filteredEvents" :key="event.id" class="timeline-item">
                <div class="time-badge">
                  <template v-if="event.start_time">
                    <span>{{ event.start_time.slice(0,5) }}</span>
                    <span v-if="event.end_time" class="time-end"> 〜 {{ event.end_time.slice(0,5) }}</span>
                  </template>
                  <template v-else>
                    <span class="no-time">指定なし</span>
                  </template>
                </div>
                <div class="event-card clickable" @click="openEditEventModal(event)" title="クリックして予定を編集">
                  <div class="event-header">
                    <h4>{{ event.title }}</h4>
                    <button @click.stop="handleDeleteEvent(event.id)" class="del-icon" title="削除">✕</button>
                  </div>
                  <div v-if="event.location" class="location-group">
                    <a
                      v-if="parseLocationData(event.location).mapUrl"
                      :href="parseLocationData(event.location).mapUrl"
                      target="_blank"
                      rel="noopener"
                      class="location-link map-link"
                      @click.stop
                      title="Googleマップを開く"
                    >
                      🗺️ Googleマップ ↗
                    </a>
                    <a
                      v-if="parseLocationData(event.location).webUrl"
                      :href="parseLocationData(event.location).webUrl"
                      target="_blank"
                      rel="noopener"
                      class="location-link web-link"
                      @click.stop
                      title="WEBサイトを開く"
                    >
                      🌐 WEBサイト ↗
                    </a>
                  </div>
                  <p v-if="event.memo" class="memo">📝 {{ event.memo }}</p>
                </div>
              </div>
            </div>

            <!-- ポップな予定追加ボタン -->
            <button @click="openAddEventModal" class="add-event-btn pop-btn">
              <span class="sparkle">✨</span>
              <span>＋ 新しい予定を追加する</span>
            </button>
          </div>
        </section>

        <!-- 2. 割り勘・精算タブ -->
        <section v-if="activeTab === 'expense'" class="tab-pane">
          <!-- 収支サマリーカード -->
          <div class="summary-card">
            <div class="summary-box">
              <span class="label">旅行の総出費</span>
              <span class="value">{{ totalExpense.toLocaleString() }} <small>円</small></span>
            </div>
            <div class="divider"></div>
            <div class="summary-box">
              <span class="label">あなたの収支</span>
              <span :class="['value', myBalance >= 0 ? 'plus' : 'minus']">
                {{ myBalance >= 0 ? '+' : '' }}{{ myBalance.toLocaleString() }} <small>円</small>
              </span>
            </div>
          </div>

          <!-- 操作ボタン -->
          <div class="expense-toolbar">
            <button @click="openAddExpenseModal" class="btn btn-primary btn-flex">
              <span>＋ 出費を記録する</span>
            </button>
            <button @click="toggleSettlement" class="btn btn-secondary btn-flex">
              <span>{{ showSettlement ? '💰 支払履歴を見る' : '💸 精算結果を見る' }}</span>
            </button>
          </div>

          <!-- 送金ルート (精算結果) -->
          <div v-if="showSettlement" class="settlement-section fade-in">
            <div class="section-title">
              <h3>💸 送金ルート (送金最小化)</h3>
              <p>誰が誰にいくら送金すれば清算完了するかを算出しています</p>
            </div>

            <div v-if="settlementRoutes.length === 0" class="empty-box">
              <span>🎉 貸し借りは発生していません！</span>
            </div>

            <div v-else class="routes-list">
              <div v-for="(route, i) in settlementRoutes" :key="i" class="route-item">
                <div class="person debtor">{{ route.from }}</div>
                <div class="arrow-area">
                  <span class="amount-tag">{{ route.amount.toLocaleString() }} 円</span>
                  <span class="arrow-line">→</span>
                </div>
                <div class="person creditor">{{ route.to }}</div>
              </div>
            </div>
          </div>

          <!-- 支払履歴 -->
          <div v-else class="expense-section fade-in">
            <div class="section-title">
              <h3>💰 支払履歴一覧</h3>
            </div>

            <div v-if="expenses.length === 0" class="empty-box">
              <span>まだ支払履歴はありません。</span>
            </div>

            <div v-else class="expense-list">
              <div v-for="exp in expenses" :key="exp.id" class="expense-card">
                <div class="exp-top">
                  <span class="exp-title">{{ exp.description }}</span>
                  <span class="exp-amount">{{ exp.amount.toLocaleString() }} 円</span>
                </div>
                <div class="exp-bottom">
                  <span>支払者: <strong>{{ exp.payer_name }}</strong></span>
                  <span>対象: {{ exp.targets.map(t => t.display_name).join(', ') }}</span>
                </div>
                <button @click="handleDeleteExpense(exp.id)" class="del-icon" title="削除">✕</button>
              </div>
            </div>
          </div>
        </section>

        <!-- 3. メンバータブ -->
        <section v-if="activeTab === 'members'" class="tab-pane fade-in">
          <!-- 招待カード -->
          <div class="invite-banner">
            <div class="invite-text">
              <h4>メンバーを招待</h4>
              <p>このコードをグループメンバーに共有して招待しましょう</p>
            </div>
            <div class="code-box-wrapper">
              <div class="code-box">
                <code>{{ trip.invite_code }}</code>
                <button @click="copyInviteCode" class="btn btn-sm btn-primary">コピー</button>
              </div>
              <button @click="shareToLine" class="line-share-btn-large">
                💬 LINEで共有
              </button>
            </div>
          </div>

          <!-- メンバーリスト -->
          <div class="members-card">
            <h3>👥 参加メンバー ({{ members.length }}人)</h3>
            <div class="members-grid">
              <div v-for="member in members" :key="member.id" class="member-chip">
                <div class="avatar">{{ member.display_name.slice(0,1) }}</div>
                <span class="name">{{ member.display_name }}</span>
                <span v-if="member.isHost" class="host-tag">ホスト</span>
              </div>
            </div>
          </div>
        </section>
      </main>

      <!-- 予定追加モーダル -->
      <div v-if="showAddEvent" class="modal-overlay pop-in">
        <div class="modal-card">
          <div class="modal-header">
            <h3>新しい予定を追加</h3>
            <button @click="showAddEvent = false" class="close-btn">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>予定タイトル</label>
              <input v-model="newEventTitle" type="text" placeholder="例: ラーメンランチ" required />
            </div>
            <div class="form-group">
              <label>時間（任意・スクロール選択）</label>
              <div class="time-range-selects">
                <select v-model="newEventStartTime" class="time-select">
                  <option value="">開始: 指定なし</option>
                  <option v-for="t in timeOptions" :key="'s-' + t" :value="t">{{ t }}</option>
                </select>
                <span class="range-separator">〜</span>
                <select v-model="newEventEndTime" class="time-select">
                  <option value="">終了: 指定なし</option>
                  <option v-for="t in timeOptions" :key="'e-' + t" :value="t">{{ t }}</option>
                </select>
              </div>
              <small class="help-text">※時間を決めない場合は「指定なし」のまま登録できます</small>
            </div>
            <div class="form-group">
              <label>Googleマップ URL または 場所名 (任意)</label>
              <input v-model="newEventMapUrl" type="text" placeholder="例: https://maps.app.goo.gl/... または 東京タワー" />
              <small class="help-text">※Googleマップの共有リンク、または「東京タワー」等の場所名を入力できます</small>
            </div>
            <div class="form-group">
              <label>WEB URL (任意)</label>
              <input v-model="newEventWebUrl" type="url" placeholder="例: https://example.com" />
            </div>
            <div class="form-group">
              <label>メモ (任意)</label>
              <textarea v-model="newEventMemo" placeholder="持ち物や補足など"></textarea>
            </div>
            <div v-if="modalError" class="error-msg">⚠️ {{ modalError }}</div>
          </div>
          <div class="modal-footer">
            <button @click="showAddEvent = false" class="btn btn-outline">キャンセル</button>
            <button @click="handleAddEvent" class="btn btn-primary">追加する</button>
          </div>
        </div>
      </div>

      <!-- 予定編集モーダル -->
      <div v-if="showEditEvent" class="modal-overlay pop-in">
        <div class="modal-card">
          <div class="modal-header">
            <h3>予定を編集</h3>
            <button @click="showEditEvent = false" class="close-btn">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>予定タイトル</label>
              <input v-model="editEventTitle" type="text" placeholder="例: ラーメンランチ" required />
            </div>
            <div class="form-group">
              <label>時間（任意・スクロール選択）</label>
              <div class="time-range-selects">
                <select v-model="editEventStartTime" class="time-select">
                  <option value="">開始: 指定なし</option>
                  <option v-for="t in timeOptions" :key="'es-' + t" :value="t">{{ t }}</option>
                </select>
                <span class="range-separator">〜</span>
                <select v-model="editEventEndTime" class="time-select">
                  <option value="">終了: 指定なし</option>
                  <option v-for="t in timeOptions" :key="'ee-' + t" :value="t">{{ t }}</option>
                </select>
              </div>
            </div>
            <div class="form-group">
              <label>Googleマップ URL または 場所名 (任意)</label>
              <input v-model="editEventMapUrl" type="text" placeholder="例: https://maps.app.goo.gl/... または 東京タワー" />
              <small class="help-text">※Googleマップの共有リンク、または「東京タワー」等の場所名を入力できます</small>
            </div>
            <div class="form-group">
              <label>WEB URL (任意)</label>
              <input v-model="editEventWebUrl" type="url" placeholder="例: https://example.com" />
            </div>
            <div class="form-group">
              <label>メモ (任意)</label>
              <textarea v-model="editEventMemo" placeholder="持ち物や補足など"></textarea>
            </div>
            <div v-if="modalError" class="error-msg">⚠️ {{ modalError }}</div>
          </div>
          <div class="modal-footer">
            <button @click="showEditEvent = false" class="btn btn-outline">キャンセル</button>
            <button @click="handleUpdateEvent" class="btn btn-primary">更新する</button>
          </div>
        </div>
      </div>

      <!-- 出費登録モーダル -->
      <div v-if="showAddExpense" class="modal-overlay pop-in">
        <div class="modal-card">
          <div class="modal-header">
            <h3>出費を記録する</h3>
            <button @click="showAddExpense = false" class="close-btn">✕</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>内容</label>
              <input v-model="newExpDescription" type="text" placeholder="例: レンタカー代" required />
            </div>
            <div class="form-group">
              <label>金額 (円)</label>
              <input v-model.number="newExpAmount" type="number" inputmode="numeric" placeholder="例: 9000" required />
            </div>
            <div class="form-group">
              <label>支払った人</label>
              <select v-model="newExpPayerId">
                <option v-for="m in members" :key="m.id" :value="m.id">{{ m.display_name }}</option>
              </select>
            </div>
            <div class="form-group">
              <label>割り勘対象メンバー</label>
              <div class="checkbox-group">
                <label v-for="m in members" :key="m.id" class="checkbox-item">
                  <input type="checkbox" :value="m.id" v-model="newExpTargetIds" />
                  <span>{{ m.display_name }}</span>
                </label>
              </div>
            </div>
            <div v-if="modalError" class="error-msg">⚠️ {{ modalError }}</div>
          </div>
          <div class="modal-footer">
            <button @click="showAddExpense = false" class="btn btn-outline">キャンセル</button>
            <button @click="handleAddExpense" class="btn btn-primary">登録する</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const route = useRoute()
const supabase = useSupabaseClient()
const tripId = String(route.params.id)

const {
  trip,
  members,
  events,
  expenses,
  loading,
  error,
  fetchAllTripData,
  addEvent,
  updateEvent,
  deleteEvent,
  addExpense,
  deleteExpense,
  setupRealtime
} = useTripDetail(tripId)

const activeTab = ref('schedule')
const selectedDay = ref(1)
const showAddEvent = ref(false)
const showEditEvent = ref(false)
const showAddExpense = ref(false)
const showSettlement = ref(false)
const modalError = ref('')

onMounted(async () => {
  await fetchAllTripData()
  setupRealtime()
  const { data: { user: currentUser } } = await supabase.auth.getUser()
  if (members.value.length > 0) {
    if (currentUser && members.value.some(m => m.id === currentUser.id)) {
      newExpPayerId.value = currentUser.id
    } else {
      newExpPayerId.value = members.value[0].id
    }
    newExpTargetIds.value = members.value.map(m => m.id)
  }
})

// 日付リスト
const tripDays = computed(() => {
  if (!trip.value) return []
  const start = new Date(trip.value.start_date)
  const end = new Date(trip.value.end_date)
  const list = []
  let current = new Date(start)
  let dayNum = 1

  while (current <= end) {
    list.push({
      dayNum,
      dateStr: current.toISOString().split('T')[0]
    })
    current.setDate(current.getDate() + 1)
    dayNum++
  }
  return list.length > 0 ? list : [{ dayNum: 1, dateStr: trip.value.start_date }]
})

// 選択中の日のイベント
const filteredEvents = computed(() => {
  const selectedDateObj = tripDays.value.find(d => d.dayNum === selectedDay.value)
  if (!selectedDateObj) return []
  return events.value.filter(e => e.event_date === selectedDateObj.dateStr)
})

// 場所データ（MapURL・WebURL）のパースと結合
const getNormalizedMapUrl = (raw) => {
  if (!raw) return ''
  const trimmed = raw.trim()
  if (!trimmed) return ''

  // すでに http:// または https:// で始まっている場合
  if (/^https?:\/\//i.test(trimmed)) {
    return trimmed
  }

  // maps.google.com や maps.app.goo.gl などのドメインで始まる場合
  if (/^(www\.|maps\.|goo\.gl|google\.com|google\.co\.jp)/i.test(trimmed)) {
    return `https://${trimmed}`
  }

  // URLではなく場所の名前（例：「東京タワー」など）の場合はGoogleマップ検索URLに変換
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(trimmed)}`
}

const getNormalizedWebUrl = (raw) => {
  if (!raw) return ''
  const trimmed = raw.trim()
  if (!trimmed) return ''
  if (/^https?:\/\//i.test(trimmed)) {
    return trimmed
  }
  return `https://${trimmed}`
}

const parseLocationData = (locStr) => {
  if (!locStr) return { mapUrl: '', webUrl: '' }
  
  if (locStr.includes(':::')) {
    const parts = locStr.split(':::')
    return {
      mapUrl: getNormalizedMapUrl(parts[0]),
      webUrl: getNormalizedWebUrl(parts[1])
    }
  }

  // 互換性フォールバック（旧データのURL単体判定）
  if (/^https?:\/\//i.test(locStr)) {
    if (locStr.includes('google.com') || locStr.includes('goo.gl') || locStr.includes('maps')) {
      return { mapUrl: getNormalizedMapUrl(locStr), webUrl: '' }
    }
    return { mapUrl: '', webUrl: getNormalizedWebUrl(locStr) }
  }

  // それ以外（場所の名前テキストのみ等）の場合
  return { mapUrl: getNormalizedMapUrl(locStr), webUrl: '' }
}

const formatLocationData = (mapUrl, webUrl) => {
  const cleanMap = getNormalizedMapUrl(mapUrl)
  const cleanWeb = getNormalizedWebUrl(webUrl)
  
  if (!cleanMap && !cleanWeb) return ''
  return `${cleanMap}:::${cleanWeb}`
}

// 30分刻みの時間リスト (00:00 〜 23:30)
const timeOptions = Array.from({ length: 48 }, (_, i) => {
  const h = String(Math.floor(i / 2)).padStart(2, '0')
  const m = i % 2 === 0 ? '00' : '30'
  return `${h}:${m}`
})

// 予定フォーム
const newEventTitle = ref('')
const newEventStartTime = ref('')
const newEventEndTime = ref('')
const newEventMapUrl = ref('')
const newEventWebUrl = ref('')
const newEventMemo = ref('')

// 編集モーダル用の状態
const editingEventId = ref(null)
const editEventTitle = ref('')
const editEventStartTime = ref('')
const editEventEndTime = ref('')
const editEventMapUrl = ref('')
const editEventWebUrl = ref('')
const editEventMemo = ref('')

const openAddEventModal = () => {
  modalError.value = ''
  showAddEvent.value = true
}

const handleAddEvent = async () => {
  modalError.value = ''
  if (!newEventTitle.value.trim()) {
    modalError.value = '予定タイトルを入力してください'
    return
  }

  const selectedDateObj = tripDays.value.find(d => d.dayNum === selectedDay.value)
  const dateStr = selectedDateObj ? selectedDateObj.dateStr : trip.value.start_date
  const combinedLocation = formatLocationData(newEventMapUrl.value, newEventWebUrl.value)

  const res = await addEvent({
    title: newEventTitle.value,
    event_date: dateStr,
    start_time: newEventStartTime.value || undefined,
    end_time: newEventEndTime.value || undefined,
    location: combinedLocation || undefined,
    memo: newEventMemo.value
  })

  if (res.success) {
    showAddEvent.value = false
    newEventTitle.value = ''
    newEventStartTime.value = ''
    newEventEndTime.value = ''
    newEventMapUrl.value = ''
    newEventWebUrl.value = ''
    newEventMemo.value = ''
  } else {
    modalError.value = res.error || '追加に失敗しました'
  }
}

const openEditEventModal = (event) => {
  modalError.value = ''
  editingEventId.value = event.id
  editEventTitle.value = event.title
  editEventStartTime.value = event.start_time ? event.start_time.slice(0, 5) : ''
  editEventEndTime.value = event.end_time ? event.end_time.slice(0, 5) : ''
  
  const parsedLoc = parseLocationData(event.location)
  editEventMapUrl.value = parsedLoc.mapUrl
  editEventWebUrl.value = parsedLoc.webUrl

  editEventMemo.value = event.memo || ''
  showEditEvent.value = true
}

const handleUpdateEvent = async () => {
  modalError.value = ''
  if (!editEventTitle.value.trim()) {
    modalError.value = '予定タイトルを入力してください'
    return
  }

  const selectedDateObj = tripDays.value.find(d => d.dayNum === selectedDay.value)
  const dateStr = selectedDateObj ? selectedDateObj.dateStr : trip.value.start_date
  const combinedLocation = formatLocationData(editEventMapUrl.value, editEventWebUrl.value)

  const res = await updateEvent(editingEventId.value, {
    title: editEventTitle.value,
    event_date: dateStr,
    start_time: editEventStartTime.value || undefined,
    end_time: editEventEndTime.value || undefined,
    location: combinedLocation || undefined,
    memo: editEventMemo.value
  })

  if (res.success) {
    showEditEvent.value = false
    editingEventId.value = null
  } else {
    modalError.value = res.error || '更新に失敗しました'
  }
}

const handleDeleteEvent = async (eventId) => {
  if (confirm('この予定を削除しますか？')) {
    await deleteEvent(eventId)
  }
}

// 出費フォーム
const newExpDescription = ref('')
const newExpAmount = ref(null)
const newExpPayerId = ref('')
const newExpTargetIds = ref([])

const openAddExpenseModal = async () => {
  modalError.value = ''
  showAddExpense.value = true
  try {
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    if (members.value.length > 0) {
      if (!newExpPayerId.value || newExpPayerId.value === 'undefined') {
        newExpPayerId.value = (currentUser && members.value.some(m => m.id === currentUser.id))
          ? currentUser.id
          : members.value[0].id
      }
      if (newExpTargetIds.value.length === 0) {
        newExpTargetIds.value = members.value.map(m => m.id)
      }
    }
  } catch (err) {
    console.error('openAddExpenseModal error:', err)
  }
}

const handleAddExpense = async () => {
  modalError.value = ''
  if (!newExpDescription.value.trim() || !newExpAmount.value || newExpAmount.value <= 0) {
    modalError.value = '内容と正確な金額を入力してください'
    return
  }
  if (!newExpPayerId.value || newExpTargetIds.value.length === 0) {
    modalError.value = '支払者と対象メンバーを選択してください'
    return
  }

  const todayStr = new Date().toISOString().split('T')[0]

  const res = await addExpense({
    description: newExpDescription.value,
    amount: Number(newExpAmount.value),
    payer_id: newExpPayerId.value,
    payment_date: todayStr,
    target_user_ids: newExpTargetIds.value
  })

  if (res.success) {
    showAddExpense.value = false
    newExpDescription.value = ''
    newExpAmount.value = null
  } else {
    modalError.value = res.error || '登録に失敗しました'
  }
}

const handleDeleteExpense = async (expenseId) => {
  if (confirm('この出費を削除しますか？')) {
    await deleteExpense(expenseId)
  }
}

// 収支計算
const totalExpense = computed(() => {
  return expenses.value.reduce((sum, exp) => sum + exp.amount, 0)
})

const netBalances = computed(() => {
  const balances = {}
  members.value.forEach(m => {
    balances[m.id] = { name: m.display_name, balance: 0 }
  })

  expenses.value.forEach(exp => {
    if (balances[exp.payer_id]) {
      balances[exp.payer_id].balance += exp.amount
    }

    if (exp.targets && exp.targets.length > 0) {
      const totalWeight = exp.targets.reduce((wSum, t) => wSum + (t.weight || 1.0), 0)
      exp.targets.forEach(t => {
        if (balances[t.user_id]) {
          const share = (exp.amount * (t.weight || 1.0)) / totalWeight
          balances[t.user_id].balance -= share
        }
      })
    }
  })
  return balances
})

const myBalance = computed(() => {
  return 0
})

// 送金最小化アルゴリズム
const settlementRoutes = computed(() => {
  const balances = netBalances.value
  const debtors = []
  const creditors = []

  Object.keys(balances).forEach(uid => {
    const item = balances[uid]
    const val = item.balance
    if (val < -0.1) {
      debtors.push({ name: item.name, amount: val })
    } else if (val > 0.1) {
      creditors.push({ name: item.name, amount: val })
    }
  })

  debtors.sort((a, b) => a.amount - b.amount)
  creditors.sort((a, b) => b.amount - a.amount)

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
  if (trip.value?.invite_code) {
    navigator.clipboard.writeText(trip.value.invite_code)
    alert(`招待コード ${trip.value.invite_code} をコピーしました！`)
  }
}

const shareToLine = () => {
  if (trip.value?.invite_code) {
    const text = `旅行「${trip.value.title}」に招待されています！✈️\nTripAppで一緒に旅行計画・割り勘を始めよう！\n\n🔑 招待コード: ${trip.value.invite_code}`
    const lineUrl = `https://line.me/R/msg/text/?${encodeURIComponent(text)}`
    window.open(lineUrl, '_blank')
  }
}

const goBack = () => {
  navigateTo('/trips')
}
</script>

<style scoped>
.trip-detail-page {
  min-height: 100vh;
  background-color: #f8fafc;
  padding-bottom: 80px;
}

.app-header {
  background: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-content {
  max-width: 800px;
  margin: 0 auto;
  padding: 12px 16px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-btn {
  background: #f1f5f9;
  border: none;
  color: #334155;
  padding: 8px 14px;
  border-radius: 20px;
  font-weight: 700;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.2s ease;
}

.back-btn:hover {
  background: #e2e8f0;
}

.event-header h4 {
  font-size: 0.98rem;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
  line-height: 1.3;
}

.edit-icon-sub {
  font-size: 0.75rem;
  opacity: 0.4;
  margin-left: 4px;
  transition: opacity 0.2s ease;
}

.event-card.clickable:hover .edit-icon-sub {
  opacity: 1;
}

.trip-meta h2 {
  font-size: 1.2rem;
  font-weight: 800;
  color: #0f172a;
}

.dates-pill {
  font-size: 0.78rem;
  color: #64748b;
  font-weight: 600;
}

.main-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px 16px;
}

.tab-nav {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  background: #e2e8f0;
  padding: 4px;
  border-radius: 14px;
  margin-bottom: 20px;
}

.tab-nav button {
  padding: 10px;
  border: none;
  background: transparent;
  border-radius: 10px;
  font-weight: 700;
  font-size: 0.88rem;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tab-nav button.active {
  background: #ffffff;
  color: #2563eb;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
}

.day-pills {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

.day-pills button {
  padding: 10px 18px;
  background: #ffffff;
  border: 1.5px solid #e2e8f0;
  border-radius: 14px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.day-pills button.active {
  background: #3b82f6;
  border-color: #3b82f6;
  color: white;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.day-pills button.active small {
  color: rgba(255, 255, 255, 0.8);
}

.timeline-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.timeline-item {
  display: flex;
  gap: 10px;
  align-items: center;
}

.time-badge {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  padding: 4px 8px;
  border-radius: 8px;
  font-weight: 800;
  font-size: 0.78rem;
  color: #1e293b;
  min-width: 68px;
  text-align: center;
}

.time-range-selects {
  display: flex;
  align-items: center;
  gap: 8px;
}

.time-select {
  flex: 1;
  padding: 10px 12px;
  border: 1.5px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.9rem;
  background: #ffffff;
  outline: none;
  cursor: pointer;
}

.time-select:focus {
  border-color: #3b82f6;
}

.range-separator {
  font-weight: 700;
  color: #64748b;
}

.help-text {
  font-size: 0.75rem;
  color: #64748b;
  margin-top: 2px;
}

.no-time {
  color: #94a3b8;
  font-weight: 600;
  font-size: 0.78rem;
}

.time-end {
  font-size: 0.78rem;
  color: #64748b;
}

.event-card {
  flex: 1;
  background: #ffffff;
  padding: 16px;
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.02);
  position: relative;
}

.event-card.clickable {
  cursor: pointer;
  transition: all 0.2s ease;
}

.event-card.clickable:hover {
  transform: translateY(-2px);
  border-color: #93c5fd;
  box-shadow: 0 6px 14px -3px rgba(59, 130, 246, 0.15);
}

.edit-hint {
  font-size: 0.72rem;
  color: #3b82f6;
  background: #eff6ff;
  padding: 2px 8px;
  border-radius: 6px;
  display: inline-block;
  margin-top: 8px;
  font-weight: 600;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.event-card.clickable:hover .edit-hint {
  opacity: 1;
}

.event-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.event-header h4 {
  font-size: 1.05rem;
  color: #0f172a;
}

.location-group {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 3px;
}

.location-name {
  font-size: 0.82rem;
  color: #334155;
  font-weight: 600;
}

.location, .memo {
  font-size: 0.8rem;
  color: #64748b;
  margin: 2px 0 0 0;
  line-height: 1.35;
}

.location-link {
  font-weight: 700;
  text-decoration: none;
  padding: 2px 8px;
  border-radius: 6px;
  border: 1px solid transparent;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  transition: all 0.2s ease;
  font-size: 0.78rem;
}

.map-link {
  color: #2563eb;
  background: #eff6ff;
  border-color: #bfdbfe;
}

.map-link:hover {
  background: #dbeafe;
  border-color: #93c5fd;
}

.web-link {
  color: #059669;
  background: #ecfdf5;
  border-color: #a7f3d0;
}

.web-link:hover {
  background: #d1fae5;
  border-color: #6ee7b7;
}

.del-icon {
  background: none;
  border: none;
  color: #94a3b8;
  font-size: 1.1rem;
  cursor: pointer;
}

.del-icon:hover {
  color: #ef4444;
}

/* ポップなブルー・パープル予定追加ボタン */
.add-event-btn {
  width: 100%;
  margin-top: 20px;
  padding: 16px 20px;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  color: #ffffff;
  border: none;
  border-radius: 18px;
  font-weight: 800;
  font-size: 1rem;
  cursor: pointer;
  box-shadow: 0 8px 20px -4px rgba(99, 102, 241, 0.4), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  transition: all 0.25s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.add-event-btn:hover {
  transform: translateY(-3px) scale(1.01);
  box-shadow: 0 12px 25px -4px rgba(99, 102, 241, 0.5), 0 6px 10px -2px rgba(0, 0, 0, 0.1);
  background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%);
}

.add-event-btn:active {
  transform: translateY(1px) scale(0.98);
}

.sparkle {
  font-size: 1.2rem;
  animation: bounce 2s infinite ease-in-out;
}

@keyframes bounce {
  0%, 100% { transform: translateY(0) scale(1); }
  50% { transform: translateY(-3px) scale(1.2); }
}

/* 割り勘・収支カード */
.summary-card {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  color: white;
  border-radius: 20px;
  padding: 24px;
  display: flex;
  justify-content: space-around;
  align-items: center;
  margin-bottom: 20px;
  box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.2);
}

.summary-box {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.summary-box .label {
  font-size: 0.78rem;
  color: #94a3b8;
}

.summary-box .value {
  font-size: 1.5rem;
  font-weight: 800;
  margin-top: 4px;
}

.summary-box .value.plus {
  color: #34d399;
}

.summary-box .value.minus {
  color: #f87171;
}

.divider {
  width: 1px;
  height: 40px;
  background: rgba(255, 255, 255, 0.15);
}

.expense-toolbar {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.btn-flex {
  flex: 1;
  padding: 12px;
  border-radius: 12px;
  font-weight: 700;
  border: none;
  cursor: pointer;
}

.btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
}

.btn-secondary {
  background: #ffffff;
  color: #334155;
  border: 1px solid #cbd5e1;
}

/* 送金ルート */
.routes-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.route-item {
  background: #ffffff;
  padding: 16px;
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.person {
  font-weight: 800;
  font-size: 0.95rem;
}

.debtor {
  color: #ef4444;
}

.creditor {
  color: #10b981;
}

.arrow-area {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.amount-tag {
  font-size: 0.85rem;
  font-weight: 800;
  color: #2563eb;
  background: #eff6ff;
  padding: 2px 10px;
  border-radius: 12px;
}

.arrow-line {
  font-weight: 800;
  color: #94a3b8;
}

/* メンバータブ */
.invite-banner {
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 16px;
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 12px;
}

.invite-text h4 {
  color: #1e3a8a;
  font-size: 1.05rem;
}

.invite-text p {
  color: #3b82f6;
  font-size: 0.8rem;
}

.code-box-wrapper {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.code-box {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #ffffff;
  padding: 6px 14px;
  border-radius: 10px;
  border: 1px solid #93c5fd;
}

.line-share-btn-large {
  background: #06C755;
  color: #ffffff;
  border: none;
  padding: 8px 14px;
  border-radius: 10px;
  font-weight: 800;
  font-size: 0.9rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
  box-shadow: 0 4px 12px rgba(6, 199, 85, 0.25);
}

.line-share-btn-large:hover {
  background: #05b34c;
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(6, 199, 85, 0.35);
}

.code-box code {
  font-family: monospace;
  font-size: 1.3rem;
  font-weight: 800;
  color: #1d4ed8;
  letter-spacing: 2px;
}

.members-card {
  background: #ffffff;
  padding: 20px;
  border-radius: 16px;
  border: 1px solid #e2e8f0;
}

.members-card h3 {
  font-size: 1.05rem;
  color: #0f172a;
  margin-bottom: 16px;
}

.members-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.member-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 8px 14px;
  border-radius: 20px;
}

.member-chip .avatar {
  width: 28px;
  height: 28px;
  background: #3b82f6;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 0.8rem;
}

.host-tag {
  background: #fef3c7;
  color: #d97706;
  font-size: 0.7rem;
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 10px;
}

.expense-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.expense-card {
  background: #ffffff;
  padding: 16px;
  border-radius: 14px;
  border: 1px solid #e2e8f0;
  position: relative;
}

.exp-top {
  display: flex;
  justify-content: space-between;
  font-weight: 800;
  font-size: 1rem;
  margin-bottom: 8px;
  padding-right: 24px;
}

.exp-bottom {
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
  color: #64748b;
}

.expense-card .del-icon {
  position: absolute;
  top: 14px;
  right: 14px;
}

.empty-box, .empty-timeline {
  text-align: center;
  padding: 40px;
  background: #ffffff;
  border-radius: 16px;
  color: #64748b;
  border: 1px dashed #cbd5e1;
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
  transform: translateY(0);
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

.modal-body label {
  font-size: 0.82rem;
  font-weight: 600;
  color: #334155;
}

.modal-body input, .modal-body select, .modal-body textarea {
  padding: 10px 12px;
  border: 1.5px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95rem;
  outline: none;
  font-family: inherit;
}

.modal-body input:focus, .modal-body select:focus, .modal-body textarea:focus {
  border-color: #3b82f6;
}

.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9rem;
  cursor: pointer;
}

.modal-footer {
  padding: 16px 20px;
  background: #f8fafc;
  display: flex;
  gap: 12px;
  border-top: 1px solid #f1f5f9;
  border-bottom-left-radius: 24px;
  border-bottom-right-radius: 24px;
}

.modal-footer .btn {
  flex: 1;
  padding: 14px 18px;
  font-size: 1rem;
  font-weight: 800;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 48px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.modal-footer .btn-primary {
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
  color: white;
  border: none;
  box-shadow: 0 4px 14px rgba(59, 130, 246, 0.35);
}

.modal-footer .btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(59, 130, 246, 0.45);
}

.modal-footer .btn-outline {
  background: #ffffff;
  color: #64748b;
  border: 1.5px solid #cbd5e1;
}

.modal-footer .btn-outline:hover {
  background: #f1f5f9;
  color: #334155;
}

.error-msg {
  color: #ef4444;
  font-size: 0.85rem;
}

.loading-state, .error-state {
  text-align: center;
  padding: 60px 20px;
  color: #64748b;
}

.spinner {
  width: 24px;
  height: 24px;
  border: 3px solid #e2e8f0;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin: 0 auto 12px auto;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
