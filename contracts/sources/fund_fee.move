module delta_hedging::fund_fee {
    use delta_hedging::white_list::{only_admin};
    use delta_hedging::math::{safe_sub};
    use delta_hedging::math256::{I256, init_i256, get_value_256, is_negative_256};
    const DELTA_HEDGING: address = @delta_hedging;

    struct FundFee has key {
        fund_fee_all: I256,
        fund_fee_safety: u256,
        fund_fee_risky: I256
    }

    struct TVL has key {
        total_deposited_risky: u64,
        total_deposited_safety: u64,
    }

    #[view]
    public fun current_deposited(): (u64, u64) acquires TVL {
        let tvl = borrow_global<TVL>(DELTA_HEDGING);
        (tvl.total_deposited_safety, tvl.total_deposited_risky)
    }

    public entry fun set_current(signer: &signer, safety: u64, risky: u64) acquires TVL{
        only_admin(signer);
        let tvl = borrow_global_mut<TVL>(DELTA_HEDGING);
        tvl.total_deposited_safety = safety;
        tvl.total_deposited_risky = risky;
    }

    public fun update_current_deposited(fund_safety: u64, fund_risky: u64, increase: bool) acquires TVL{
        let tvl = borrow_global_mut<TVL>(DELTA_HEDGING);
        if(increase)
        {   
            tvl.total_deposited_safety += fund_safety;
            tvl.total_deposited_risky += fund_risky;
        }
        else{
            tvl.total_deposited_safety = safe_sub(tvl.total_deposited_safety, fund_safety);
            tvl.total_deposited_risky = safe_sub(tvl.total_deposited_risky, fund_risky);
        }
    }


    #[view]
    public fun fund_fee_current(): (I256, u256, I256) acquires FundFee {
        let fund_fee = borrow_global<FundFee>(DELTA_HEDGING);
        (fund_fee.fund_fee_all, fund_fee.fund_fee_safety, fund_fee.fund_fee_risky)
    }

    #[view]
    public fun fund_fee_safety(): u256 acquires FundFee {
        let fund_fee = borrow_global<FundFee>(DELTA_HEDGING);
        fund_fee.fund_fee_safety
    }

    #[view]
    public fun fund_fee_risky(): (u256, bool) acquires FundFee {
        let fund_fee = borrow_global<FundFee>(DELTA_HEDGING);
        let fund_risky = fund_fee.fund_fee_risky;
        (get_value_256(fund_risky), is_negative_256(fund_risky))
    }

    public fun update_fund_fee(fund_all: I256, fund_safety: u256, fund_risky: I256) acquires FundFee{
        let fund_fee = borrow_global_mut<FundFee>(DELTA_HEDGING);
        fund_fee.fund_fee_all = fund_all;
        fund_fee.fund_fee_safety = fund_safety;
        fund_fee.fund_fee_risky = fund_risky;
    }

    public fun set_fund_fee_zero() acquires FundFee{
        let fund_fee = borrow_global_mut<FundFee>(DELTA_HEDGING);
        fund_fee.fund_fee_all = init_i256(0, false);
    }

    public entry fun init_fund_fee(
        signer: &signer
    ) {
        only_admin(signer);
        let fund_fee_new = FundFee {
            fund_fee_all: init_i256(0, false),
            fund_fee_safety: 0,
            fund_fee_risky: init_i256(0, false)
        };

        move_to(signer, fund_fee_new);   
    }

    public entry fun init_total_deposited(
        signer: &signer
    ) {
        only_admin(signer);
        let tvl = TVL {
            total_deposited_risky: 0,
            total_deposited_safety: 0
        };

        move_to(signer, tvl);   
    }

}