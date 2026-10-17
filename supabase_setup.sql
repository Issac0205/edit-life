-- =============================================================
--  《编辑生命》课堂投票 · Supabase 一次性初始化脚本
--  用法：Supabase 控制台 → SQL Editor → New query → 粘贴全部 → Run
-- =============================================================

-- 1) 投票表：每台设备(voter)在每道题(poll)只保留一票，改票即覆盖
create table if not exists public.votes (
  id          bigint generated always as identity primary key,
  poll        text not null check (char_length(poll)   <= 80),
  option      text not null check (char_length(option) <= 40),
  voter       text not null check (char_length(voter)  <= 64),
  created_at  timestamptz not null default now(),
  unique (poll, voter)
);

-- 2) 行级安全：允许匿名用户 投票 / 改票 / 读取（不允许删除）
alter table public.votes enable row level security;

drop policy if exists "anon can vote"   on public.votes;
drop policy if exists "anon can revote" on public.votes;
drop policy if exists "anon can read"   on public.votes;

create policy "anon can vote"   on public.votes for insert to anon with check (true);
create policy "anon can revote" on public.votes for update to anon using (true) with check (true);
create policy "anon can read"   on public.votes for select to anon using (true);

grant select, insert, update on public.votes to anon;

-- 3) 计票函数：大屏每 2 秒调用一次，只返回各选项票数（数据量极小）
create or replace function public.poll_counts(p text)
returns table(option text, n bigint)
language sql stable security definer
set search_path = public
as $$
  select v.option, count(*)::bigint as n
  from public.votes v
  where v.poll = p
  group by v.option;
$$;

grant execute on function public.poll_counts(text) to anon;

-- =============================================================
--  （可选）汇报结束后查看全部数据：
--    select poll, option, count(*) from public.votes group by 1,2 order by 1,2;
--  （可选）清空某一场：
--    delete from public.votes where poll like 'class-2026:%';
-- =============================================================
