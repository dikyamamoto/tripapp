import { ref, onUnmounted } from 'vue'

export interface EventItem {
  id: string
  trip_id: string
  title: string
  start_time?: string
  end_time?: string
  event_date: string
  location?: string
  memo?: string
  created_by?: string
}

export interface ExpenseItem {
  id: string
  trip_id: string
  payer_id: string
  amount: number
  description: string
  payment_date: string
  payer_name?: string
  targets: Array<{ user_id: string; display_name: string; weight: number }>
}

export interface MemberItem {
  id: string
  display_name: string
  avatar_url?: string
  isHost: boolean
}

export const useTripDetail = (tripId: string) => {
  const supabase = useSupabaseClient()

  const trip = ref<any>(null)
  const members = ref<MemberItem[]>([])
  const events = ref<EventItem[]>([])
  const expenses = ref<ExpenseItem[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  let realtimeChannel: any = null

  const getCurrentUser = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  }

  // 旅行の全データ（基本情報、メンバー、イベント、出費）を一元取得
  const fetchAllTripData = async () => {
    if (!tripId || tripId === 'undefined') return
    loading.value = true
    error.value = null

    try {
      // 1. 旅行基本情報
      const { data: tripData, error: tripErr } = await supabase
        .from('trips')
        .select('*')
        .eq('id', tripId)
        .single()

      if (tripErr) throw tripErr
      trip.value = tripData

      // 2. メンバー一覧情報
      const { data: memberData, error: memberErr } = await supabase
        .from('trip_members')
        .select('user_id, profiles(id, display_name, avatar_url)')
        .eq('trip_id', tripId)

      if (memberErr) throw memberErr

      members.value = (memberData || [])
        .filter((m: any) => m.profiles)
        .map((m: any) => ({
          id: m.profiles.id,
          display_name: m.profiles.display_name,
          avatar_url: m.profiles.avatar_url,
          isHost: m.profiles.id === tripData.host_id
        }))

      // 3. イベント情報
      const { data: eventData, error: eventErr } = await supabase
        .from('events')
        .select('*')
        .eq('trip_id', tripId)
        .order('event_date', { ascending: true })
        .order('start_time', { ascending: true })

      if (eventErr) throw eventErr
      events.value = eventData || []

      // 4. 出費情報＋割り勘対象者
      const { data: expenseData, error: expenseErr } = await supabase
        .from('expenses')
        .select(`
          *,
          profiles:payer_id (display_name),
          expense_participants (
            user_id,
            weight,
            profiles (display_name)
          )
        `)
        .eq('trip_id', tripId)
        .order('created_at', { ascending: false })

      if (expenseErr) throw expenseErr

      expenses.value = (expenseData || []).map((exp: any) => ({
        id: exp.id,
        trip_id: exp.trip_id,
        payer_id: exp.payer_id,
        amount: exp.amount,
        description: exp.description,
        payment_date: exp.payment_date,
        payer_name: exp.profiles?.display_name || '不明',
        targets: (exp.expense_participants || [])
          .filter((p: any) => p.profiles)
          .map((p: any) => ({
            user_id: p.user_id,
            display_name: p.profiles?.display_name || '不明',
            weight: Number(p.weight || 1.0)
          }))
      }))

    } catch (err: any) {
      console.error('fetchAllTripData error:', err)
      error.value = err.message || '旅行情報の読み込みに失敗しました'
    } finally {
      loading.value = false
    }
  }

  // イベント（予定）の追加
  const addEvent = async (payload: {
    title: string
    event_date: string
    start_time?: string
    end_time?: string
    location?: string
    memo?: string
  }) => {
    try {
      const currentUser = await getCurrentUser()
      const { error: insertErr } = await supabase.from('events').insert({
        trip_id: tripId,
        title: payload.title.trim(),
        event_date: payload.event_date,
        start_time: payload.start_time || null,
        end_time: payload.end_time || null,
        location: payload.location || null,
        memo: payload.memo || null,
        created_by: currentUser?.id || null
      })

      if (insertErr) throw insertErr
      await fetchAllTripData()
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    }
  }

  // イベント（予定）の更新
  const updateEvent = async (eventId: string, payload: {
    title: string
    event_date: string
    start_time?: string
    end_time?: string
    location?: string
    memo?: string
  }) => {
    try {
      const { error: updateErr } = await supabase
        .from('events')
        .update({
          title: payload.title.trim(),
          event_date: payload.event_date,
          start_time: payload.start_time || null,
          end_time: payload.end_time || null,
          location: payload.location || null,
          memo: payload.memo || null
        })
        .eq('id', eventId)

      if (updateErr) throw updateErr
      await fetchAllTripData()
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    }
  }

  // イベント（予定）の削除
  const deleteEvent = async (eventId: string) => {
    try {
      const { error: delErr } = await supabase.from('events').delete().eq('id', eventId)
      if (delErr) throw delErr
      await fetchAllTripData()
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    }
  }

  // 出費の記録
  const addExpense = async (payload: {
    description: string
    amount: number
    payer_id: string
    payment_date: string
    target_user_ids: string[]
  }) => {
    try {
      if (!payload.payer_id || payload.payer_id === 'undefined') {
        throw new Error('支払者を指定してください')
      }

      // 1. expenses テーブルへ登録
      const { data: exp, error: expErr } = await supabase
        .from('expenses')
        .insert({
          trip_id: tripId,
          payer_id: payload.payer_id,
          amount: payload.amount,
          description: payload.description.trim(),
          payment_date: payload.payment_date
        })
        .select()
        .single()

      if (expErr) throw expErr

      // 2. expense_participants テーブルへ対象者登録
      const participants = payload.target_user_ids
        .filter(uid => uid && uid !== 'undefined')
        .map(uid => ({
          expense_id: exp.id,
          user_id: uid,
          weight: 1.0
        }))

      if (participants.length > 0) {
        const { error: partErr } = await supabase
          .from('expense_participants')
          .insert(participants)

        if (partErr) throw partErr
      }

      await fetchAllTripData()
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    }
  }

  // 出費の削除
  const deleteExpense = async (expenseId: string) => {
    try {
      const { error: delErr } = await supabase.from('expenses').delete().eq('id', expenseId)
      if (delErr) throw delErr
      await fetchAllTripData()
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    }
  }

  // リアルタイム同期の有効化
  const setupRealtime = () => {
    if (!tripId || tripId === 'undefined') return

    realtimeChannel = supabase
      .channel(`trip-${tripId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', filter: `trip_id=eq.${tripId}` },
        () => {
          fetchAllTripData()
        }
      )
      .subscribe()
  }

  // クリーンアップ
  onUnmounted(() => {
    if (realtimeChannel) {
      supabase.removeChannel(realtimeChannel)
    }
  })

  return {
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
  }
}
