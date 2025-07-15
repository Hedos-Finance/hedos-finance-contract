module aries::controller {
     public entry fun deposit<Coin0>(
        account: &signer,
        profile_name: vector<u8>,
        amount: u64,
        repay_only: bool,
    ) {
        abort(0);
    }

    public entry fun withdraw<Coin0>(
        account: &signer,
        profile_name: vector<u8>,
        amount: u64,
        allow_borrow: bool,
    ) {
        abort(0);
    }
}