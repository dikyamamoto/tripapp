import { ref } from 'vue'

export const useTripAuth = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const loading = ref(false)
  const authError = ref<string | null>(null)

  // サインアップ (新規登録: メールアドレス + パスワード + 表示名)
  const signUp = async (email: string, password: string, displayName: string) => {
    loading.value = true
    authError.value = null
    try {
      if (!email.trim()) {
        throw new Error('メールアドレスを入力してください')
      }
      if (!displayName.trim()) {
        throw new Error('表示名(ニックネーム)を入力してください')
      }
      if (password.length < 6) {
        throw new Error('パスワードは6文字以上で入力してください')
      }

      const { data, error } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: {
            display_name: displayName.trim()
          }
        }
      })

      if (error) throw error

      // プロフィールの作成確認とフォールバック
      if (data.user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('id')
          .eq('id', data.user.id)
          .maybeSingle()

        if (!profile) {
          await supabase.from('profiles').insert({
            id: data.user.id,
            display_name: displayName.trim()
          })
        }
      }

      return { success: true, user: data.user }
    } catch (err: any) {
      authError.value = err.message || '登録に失敗しました'
      return { success: false, error: authError.value }
    } finally {
      loading.value = false
    }
  }

  // サインイン (ログイン: メールアドレス + パスワード)
  const signIn = async (email: string, password: string) => {
    loading.value = true
    authError.value = null
    try {
      if (!email.trim() || !password) {
        throw new Error('メールアドレスとパスワードを入力してください')
      }

      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password
      })

      if (error) {
        if (error.message.includes('Invalid login credentials')) {
          throw new Error('メールアドレスまたはパスワードが正しくありません')
        }
        throw error
      }

      return { success: true, user: data.user }
    } catch (err: any) {
      authError.value = err.message || 'ログインに失敗しました'
      return { success: false, error: authError.value }
    } finally {
      loading.value = false
    }
  }

  // ログアウト
  const signOut = async () => {
    loading.value = true
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  // プロフィールを取得
  const fetchProfile = async () => {
    if (!user.value) return null
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.value.id)
        .single()

      if (error) throw error
      return data
    } catch (err) {
      console.error('Fetch profile error:', err)
      return null
    }
  }

  // プロフィールの更新
  const updateProfile = async (displayName: string) => {
    if (!user.value) return { success: false, error: '未ログインです' }
    loading.value = true
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ display_name: displayName.trim() })
        .eq('id', user.value.id)

      if (error) throw error
      return { success: true }
    } catch (err: any) {
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  return {
    user,
    loading,
    authError,
    signUp,
    signIn,
    signOut,
    fetchProfile,
    updateProfile
  }
}
