export type TierType = 'total_multiplier' | 'fixed_amount' | 'base_plus_incremental' | 'per_order_band';

export type Tier = {
  from: number;
  to: number;
  pricePerOrder: number;
  tierType: TierType;
  incrementalThreshold?: number;
  incrementalPrice?: number;
};

export type SchemeType = 'order_based' | 'fixed_monthly';

export type Scheme = {
  id: string;
  name: string;
  name_en?: string;
  status: 'active' | 'archived';
  scheme_type: SchemeType;
  monthly_amount?: number | null;
  target_orders?: number;
  target_bonus?: number;
  tiers?: Tier[];
};

export type Snapshot = { month_year: string };
export type AppItem = { id: string; name: string; scheme_id: string | null };
export type SalarySchemeTierRow = {
  scheme_id: string;
  from_orders: number;
  to_orders: number | null;
  price_per_order: number;
  tier_type?: TierType;
  incremental_threshold?: number | null;
  incremental_price?: number | null;
};
