-- ==============================================================================
-- RLS 無限再帰 (Infinite Recursion) 修正用 SQL
-- Supabase Dashboard の SQL Editor でこの内容を実行してください
-- ==============================================================================

-- 既存の RLS ポリシーをドロップ
DROP POLICY IF EXISTS "旅行メンバーはメンバー一覧を閲覧可能" ON public.trip_members;
DROP POLICY IF EXISTS "認証済みユーザーは自分自身を旅行メンバーに追加可能" ON public.trip_members;
DROP POLICY IF EXISTS "メンバーは退会可能" ON public.trip_members;

DROP POLICY IF EXISTS "メンバーは旅行情報を閲覧可能" ON public.trips;
DROP POLICY IF EXISTS "認証済みユーザーは新しい旅行を作成可能" ON public.trips;
DROP POLICY IF EXISTS "メンバーは旅行情報を更新可能" ON public.trips;
DROP POLICY IF EXISTS "ホストのみ旅行を削除可能" ON public.trips;

-- ------------------------------------------------------------------------------
-- 1. trip_members のポリシー（再帰を回避）
-- ------------------------------------------------------------------------------
CREATE POLICY "認証済みユーザーはメンバー一覧を閲覧可能" ON public.trip_members
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "認証済みユーザーは自分をメンバーに追加可能" ON public.trip_members
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "メンバーは退会可能" ON public.trip_members
  FOR DELETE USING (user_id = auth.uid());

-- ------------------------------------------------------------------------------
-- 2. trips のポリシー
-- ------------------------------------------------------------------------------
CREATE POLICY "メンバーまたはホストは旅行情報を閲覧可能" ON public.trips
  FOR SELECT USING (
    auth.role() = 'authenticated'
  );

CREATE POLICY "認証済みユーザーは新しい旅行を作成可能" ON public.trips
  FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = host_id);

CREATE POLICY "メンバーは旅行情報を更新可能" ON public.trips
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = trips.id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "ホストのみ旅行を削除可能" ON public.trips
  FOR DELETE USING (auth.uid() = host_id);
