-- ==============================================================================
-- 権限エラー (Permission Denied for table trips) 修正用 SQL
-- Supabase Dashboard の SQL Editor でこの内容を実行してください
-- ==============================================================================

-- 1. authenticated / anon ロールに対する全テーブルのテーブル操作権限を付与
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 2. 既存の trips ポリシーをリセット
DROP POLICY IF EXISTS "認証済みユーザーは旅行情報を閲覧可能" ON public.trips;
DROP POLICY IF EXISTS "メンバーまたはホストは旅行情報を閲覧可能" ON public.trips;
DROP POLICY IF EXISTS "認証済みユーザーは新しい旅行を作成可能" ON public.trips;
DROP POLICY IF EXISTS "メンバーは旅行情報を更新可能" ON public.trips;
DROP POLICY IF EXISTS "ホストのみ旅行を削除可能" ON public.trips;

-- 3. trips の RLS ポリシーの簡略化・完全適用
CREATE POLICY "認証済みユーザーは旅行情報を閲覧可能" ON public.trips
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "認証済みユーザーは新しい旅行を作成可能" ON public.trips
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "認証済みユーザーは旅行情報を更新可能" ON public.trips
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "認証済みユーザーは旅行を削除可能" ON public.trips
  FOR DELETE USING (auth.role() = 'authenticated');

-- 4. profiles の既存ポリシーのリセットと適用
DROP POLICY IF EXISTS "ログインユーザーは全プロフィールを閲覧可能" ON public.profiles;
DROP POLICY IF EXISTS "ユーザーは自分のプロフィールのみ更新可能" ON public.profiles;

CREATE POLICY "全プロフィールを閲覧可能" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "認証済みユーザーはプロフィールを作成可能" ON public.profiles
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "認証済みユーザーはプロフィールを更新可能" ON public.profiles
  FOR UPDATE USING (auth.role() = 'authenticated');
