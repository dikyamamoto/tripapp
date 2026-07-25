-- ==============================================================================
-- TripApp データベース初期化スキーマ (Supabase SQL Editor 実行用)
-- ==============================================================================

-- 既存のテーブル・関数のクリーンアップ（再実行時用）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.generate_invite_code();

DROP TABLE IF EXISTS public.expense_participants CASCADE;
DROP TABLE IF EXISTS public.expenses CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.trip_members CASCADE;
DROP TABLE IF EXISTS public.trips CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- ==============================================================================
-- 1. テーブル作成
-- ==============================================================================

-- 1.1 ユーザープロフィールテーブル (auth.usersと連動)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.2 旅行情報テーブル
CREATE TABLE public.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  invite_code VARCHAR(6) UNIQUE NOT NULL,
  cover_image_url TEXT,
  host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.3 旅行メンバー中間テーブル
CREATE TABLE public.trip_members (
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (trip_id, user_id)
);

-- 1.4 スケジュール (イベント) テーブル
CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  start_time TIME,
  end_time TIME,
  event_date DATE NOT NULL,
  location TEXT,
  memo TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.5 出費 (経費) テーブル
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  payer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  description TEXT NOT NULL,
  payment_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 1.6 出費対象メンバー (割り勘対象者) 中間テーブル
CREATE TABLE public.expense_participants (
  expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  weight NUMERIC(3, 2) NOT NULL DEFAULT 1.0 CHECK (weight > 0),
  PRIMARY KEY (expense_id, user_id)
);

-- インデックスの追加（検索・結合の高速化）
CREATE INDEX idx_trips_invite_code ON public.trips(invite_code);
CREATE INDEX idx_trip_members_user_id ON public.trip_members(user_id);
CREATE INDEX idx_events_trip_date ON public.events(trip_id, event_date);
CREATE INDEX idx_expenses_trip_id ON public.expenses(trip_id);

-- ==============================================================================
-- 2. トリガー＆ヘルパー関数
-- ==============================================================================

-- 2.1 updated_at 自動更新関数
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 2.2 サインアップ時に自動でprofilesを作成するトリガー関数
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'ゲスト'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2.3 6桁ランダム招待コード生成関数
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- 3. Row Level Security (RLS) ポリシーの設定
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_participants ENABLE ROW LEVEL SECURITY;

-- 3.1 profiles
CREATE POLICY "ログインユーザーは全プロフィールを閲覧可能" ON public.profiles
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "ユーザーは自分のプロフィールのみ更新可能" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- 3.2 trips
CREATE POLICY "認証済みユーザーは旅行情報を閲覧可能" ON public.trips
  FOR SELECT USING (auth.role() = 'authenticated');

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

-- 3.3 trip_members
CREATE POLICY "認証済みユーザーはメンバー一覧を閲覧可能" ON public.trip_members
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "認証済みユーザーは自分をメンバーに追加可能" ON public.trip_members
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "メンバーは退会可能" ON public.trip_members
  FOR DELETE USING (user_id = auth.uid());

-- 3.4 events
CREATE POLICY "旅行メンバーはイベントを閲覧可能" ON public.events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = events.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーはイベントを作成可能" ON public.events
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = events.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーはイベントを更新可能" ON public.events
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = events.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーはイベントを削除可能" ON public.events
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = events.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

-- 3.5 expenses
CREATE POLICY "旅行メンバーは出費を閲覧可能" ON public.expenses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーは出費を追加可能" ON public.expenses
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーは出費を更新可能" ON public.expenses
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーは出費を削除可能" ON public.expenses
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.trip_members
      WHERE trip_members.trip_id = expenses.trip_id
        AND trip_members.user_id = auth.uid()
    )
  );

-- 3.6 expense_participants
CREATE POLICY "旅行メンバーは出費対象者を閲覧可能" ON public.expense_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      JOIN public.trip_members tm ON tm.trip_id = e.trip_id
      WHERE e.id = expense_participants.expense_id
        AND tm.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーは出費対象者を追加可能" ON public.expense_participants
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.expenses e
      JOIN public.trip_members tm ON tm.trip_id = e.trip_id
      WHERE e.id = expense_participants.expense_id
        AND tm.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーは出費対象者を更新可能" ON public.expense_participants
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      JOIN public.trip_members tm ON tm.trip_id = e.trip_id
      WHERE e.id = expense_participants.expense_id
        AND tm.user_id = auth.uid()
    )
  );

CREATE POLICY "旅行メンバーは出費対象者を削除可能" ON public.expense_participants
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      JOIN public.trip_members tm ON tm.trip_id = e.trip_id
      WHERE e.id = expense_participants.expense_id
        AND tm.user_id = auth.uid()
    )
  );

-- ==============================================================================
-- 4. Realtime パブリケーションの設定
-- ==============================================================================

-- Supabase Realtimeで変更を検知したいテーブルを追加
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.expense_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_members;
