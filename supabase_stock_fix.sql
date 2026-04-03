-- ============================================================
-- KOI DESSERT BAR — STOCK DECREMENT FIX
-- Run this in Supabase SQL Editor
-- ============================================================

-- Recreate the stock decrement trigger so it can update products safely
-- even when the buyer is a normal customer and RLS is enabled.

drop trigger if exists on_order_item_insert on public.order_items;
drop function if exists public.decrement_product_stock();

create or replace function public.decrement_product_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products
  set stock = stock - new.quantity,
      updated_at = now()
  where id = new.product_id
    and stock >= new.quantity;

  if not found then
    raise exception 'Insufficient stock for product %', new.product_id
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

alter function public.decrement_product_stock() owner to postgres;

create trigger on_order_item_insert
after insert on public.order_items
for each row
execute function public.decrement_product_stock();

-- Optional but strongly recommended:
-- return stock if an order gets cancelled.

drop trigger if exists on_order_cancel_restore_stock on public.orders;
drop function if exists public.restore_product_stock_on_cancel();

create or replace function public.restore_product_stock_on_cancel()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status <> 'cancelled' and new.status = 'cancelled' then
    update public.products p
    set stock = p.stock + oi.quantity,
        updated_at = now()
    from public.order_items oi
    where oi.order_id = new.id
      and p.id = oi.product_id;
  end if;

  return new;
end;
$$;

alter function public.restore_product_stock_on_cancel() owner to postgres;

create trigger on_order_cancel_restore_stock
after update of status on public.orders
for each row
execute function public.restore_product_stock_on_cancel();

notify pgrst, 'reload schema';
