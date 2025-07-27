module delta_hedging::interact_liquid_swap {    
    public entry fun liquid_swap_coin_for_exact_coin_x1<X, Y, C0, BS0>(
        _account: &signer,
        _coin_in_max_val: u64,
        _coin_out_vals: vector<u64>,
        _ls_versions: vector<u8>,
        _swaps_x_for_y: vector<bool>
    ) {
    }
}
