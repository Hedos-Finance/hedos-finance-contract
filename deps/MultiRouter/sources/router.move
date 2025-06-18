module multi_router::router {
    struct BinStepV0V05 {
        leuleu: bool,
    }

    public entry fun fa_swap_exact_coin_for_coin_x1<X, Y, C0, BS0>(
        account: &signer,
        coin_in_val: u64,
        coin_out_min_vals: vector<u64>,
        ls_versions: vector<u8>,
        swaps_x_for_y: vector<bool>
    ) {
        abort(0);
    }
}