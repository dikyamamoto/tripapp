import { ref } from 'vue'

export interface Trip {
  id: string
  title: string
  start_date: string
  end_date: string
  invite_code: string
  cover_image_url?: string
  host_id: string
  member_count?: number
}

export const useTrips = () => {
  const supabase = useSupabaseClient()
  const loading = ref(false)
  const tripsError = ref<string | null>(null)

  // 招待コード（6桁英数字）をランダム生成
  const generateInviteCode = (): string => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    let code = ''
    for (let i = 0; i < 6; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return code
  }

  // 確実な現在のユーザー取得
  const getCurrentUser = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    return user
  }

  // 自分の所属している旅行一覧を取得
  const fetchMyTrips = async (): Promise<Trip[]> => {
    loading.value = true
    tripsError.value = null

    try {
      const currentUser = await getCurrentUser()
      if (!currentUser || !currentUser.id) {
        return []
      }

      // trip_members を介して自分の参加旅行を取得
      const { data: memberRecords, error: memberErr } = await supabase
        .from('trip_members')
        .select('trip_id')
        .eq('user_id', currentUser.id)

      if (memberErr) throw memberErr

      if (!memberRecords || memberRecords.length === 0) {
        return []
      }

      const tripIds = memberRecords.map(m => m.trip_id).filter(Boolean)

      if (tripIds.length === 0) return []

      // 旅行データと各旅行のメンバー数を取得
      const { data: tripData, error: tripErr } = await supabase
        .from('trips')
        .select(`
          id,
          title,
          start_date,
          end_date,
          invite_code,
          cover_image_url,
          host_id,
          trip_members(user_id)
        `)
        .in('id', tripIds)
        .order('created_at', { ascending: false })

      if (tripErr) throw tripErr

      return (tripData || []).map((t: any) => ({
        id: t.id,
        title: t.title,
        start_date: t.start_date,
        end_date: t.end_date,
        invite_code: t.invite_code,
        cover_image_url: t.cover_image_url,
        host_id: t.host_id,
        member_count: Array.isArray(t.trip_members) ? t.trip_members.length : 0
      }))
    } catch (err: any) {
      console.error('fetchMyTrips error:', err)
      tripsError.value = err.message || '旅行データの取得に失敗しました'
      return []
    } finally {
      loading.value = false
    }
  }

  // 新しい旅行を作成
  const createTrip = async (payload: { title: string; start_date: string; end_date: string }) => {
    loading.value = true
    tripsError.value = null

    try {
      const currentUser = await getCurrentUser()
      if (!currentUser || !currentUser.id) {
        return { success: false, error: 'ログインが必要です。ログインし直してください。' }
      }

      const invite_code = generateInviteCode()

      // 1. trips テーブルにレコード登録
      const { data: trip, error: tripErr } = await supabase
        .from('trips')
        .insert({
          title: payload.title.trim(),
          start_date: payload.start_date,
          end_date: payload.end_date,
          invite_code,
          host_id: currentUser.id
        })
        .select()
        .single()

      if (tripErr) throw tripErr

      // 2. trip_members にホスト自身を登録
      const { error: memberErr } = await supabase
        .from('trip_members')
        .insert({
          trip_id: trip.id,
          user_id: currentUser.id
        })

      if (memberErr) throw memberErr

      return { success: true, trip }
    } catch (err: any) {
      console.error('createTrip error:', err)
      tripsError.value = err.message || '旅行の作成に失敗しました'
      return { success: false, error: tripsError.value }
    } finally {
      loading.value = false
    }
  }

  // 招待コードを入力して旅行に参加
  const joinTripByInviteCode = async (inviteCode: string) => {
    loading.value = true
    tripsError.value = null

    try {
      const currentUser = await getCurrentUser()
      if (!currentUser || !currentUser.id) {
        return { success: false, error: 'ログインが必要です。ログインし直してください。' }
      }

      const cleanCode = inviteCode.trim().toUpperCase()

      // 1. 該当する旅行を検索
      const { data: trip, error: findErr } = await supabase
        .from('trips')
        .select('id, title')
        .eq('invite_code', cleanCode)
        .single()

      if (findErr || !trip) {
        throw new Error('指定された招待コードの旅行が見つかりません')
      }

      // 2. すでにメンバーか確認
      const { data: existingMember } = await supabase
        .from('trip_members')
        .select('user_id')
        .eq('trip_id', trip.id)
        .eq('user_id', currentUser.id)
        .maybeSingle()

      if (existingMember) {
        return { success: true, tripId: trip.id, alreadyJoined: true }
      }

      // 3. メンバーとして追加
      const { error: joinErr } = await supabase
        .from('trip_members')
        .insert({
          trip_id: trip.id,
          user_id: currentUser.id
        })

      if (joinErr) throw joinErr

      return { success: true, tripId: trip.id, title: trip.title }
    } catch (err: any) {
      console.error('joinTrip error:', err)
      tripsError.value = err.message || '旅行への参加に失敗しました'
      return { success: false, error: tripsError.value }
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    tripsError,
    fetchMyTrips,
    createTrip,
    joinTripByInviteCode
  }
}
